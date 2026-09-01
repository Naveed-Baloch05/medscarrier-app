import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/services/rider_map_service.dart';
import '../../core/utils/route_utils.dart';
import '../../models/route_model.dart';
import 'rider_map_event.dart';
import 'rider_map_state.dart';

class RiderMapBloc extends Bloc<RiderMapEvent, RiderMapState> {
  RiderMapBloc({RiderMapService? service})
      : _service = service ?? RiderMapService.instance,
        super(const RiderMapInitial()) {
    on<SubscribeToMap>(_onSubscribe);
    on<SubscribeToOrder>(_onSubscribeOrder);
    on<LoadMapOrder>(_onLoad);
    on<RiderLocationUpdated>(_onRiderLocationUpdated);
    on<SelectRoute>(_onSelectRoute);
    on<RecalculateRoute>(_onRecalculateRoute);
    on<MarkArrived>(_onMarkArrived);
    on<CompleteDelivery>(_onCompleteDelivery);
  }

  final RiderMapService _service;

  StreamSubscription<RiderMapSession>? _mapSubscription;
  RiderMapSession? _latestSession;

  LatLng? _currentPosition;
  double? _currentHeading;
  List<RouteModel> _routes = [];
  int _selectedRouteIndex = 0;
  bool _isComputingRoute = false;

  // Throttling markers for Firestore & Routes API
  DateTime? _lastFirestoreUpdateTime;
  LatLng? _lastFirestoreUpdatePos;
  DateTime? _lastRouteComputeTime;
  LatLng? _lastRouteComputeOrigin;
  LatLng? _lastDestination;
  bool? _lastIsPickedUp;

  @override
  Future<void> close() {
    _mapSubscription?.cancel();
    return super.close();
  }

  RiderMapSession _currentSession() {
    if (_latestSession != null) return _latestSession!;
    final s = state;
    if (s is RiderMapLoaded) return s.session;
    if (s is RiderMapUpdating) return s.session;
    if (s is RiderMapOperationSuccess) return s.session;
    if (s is RiderMapError && s.session != null) return s.session!;
    throw StateError('Map session not loaded yet.');
  }

  Future<void> _onSubscribe(
    SubscribeToMap event,
    Emitter<RiderMapState> emit,
  ) async {
    await _mapSubscription?.cancel();
    _mapSubscription = _service.mapSessionStream(event.riderId).listen(
      (session) {
        if (!isClosed) {
          _handleSessionUpdate(session, emit);
        }
      },
      onError: (Object error) {
        if (!isClosed) {
          emit(RiderMapError(
            message: _clean(error),
            session: _latestSession,
          ));
        }
      },
    );
  }

  Future<void> _onSubscribeOrder(
    SubscribeToOrder event,
    Emitter<RiderMapState> emit,
  ) async {
    emit(const RiderMapLoading());
    await _mapSubscription?.cancel();

    Timer? fallback;
    bool gotEmission = false;

    _mapSubscription = _service.orderSessionStream(event.orderId).listen(
      (session) {
        if (!isClosed) {
          gotEmission = true;
          fallback?.cancel();
          _handleSessionUpdate(session, emit);
        }
      },
      onError: (Object error) {
        if (!isClosed) {
          gotEmission = true;
          fallback?.cancel();
          emit(RiderMapError(
            message: _clean(error),
            session: _latestSession,
          ));
        }
      },
    );

    fallback = Timer(const Duration(seconds: 4), () async {
      if (isClosed || gotEmission) return;
      try {
        final session = await _service.orderSessionOnce(event.orderId);
        if (isClosed) return;
        _handleSessionUpdate(session, emit);
      } catch (error) {
        if (isClosed) return;
        emit(RiderMapError(
          message: _clean(error),
          session: _latestSession,
        ));
      }
    });
  }

  Future<void> _onLoad(
    LoadMapOrder event,
    Emitter<RiderMapState> emit,
  ) async {
    emit(const RiderMapLoading());
    try {
      await _mapSubscription?.cancel();
      _mapSubscription = _service.mapSessionStream(event.riderId).listen(
            (session) {
              if (!isClosed) {
                _handleSessionUpdate(session, emit);
              }
            },
            onError: (Object error) {
              if (!isClosed) {
                emit(RiderMapError(
                  message: _clean(error),
                  session: _latestSession,
                ));
              }
            },
          );
    } catch (error) {
      emit(RiderMapError(message: _clean(error)));
    }
  }

  void _handleSessionUpdate(
    RiderMapSession session,
    Emitter<RiderMapState> emit,
  ) {
    _latestSession = session;

    // Check if delivery stage changed (e.g. order marked as Picked Up)
    final stageChanged = _lastIsPickedUp != null && _lastIsPickedUp != session.isPickedUp;
    _lastIsPickedUp = session.isPickedUp;

    final targetDest = session.currentDestination;
    final destChanged = _lastDestination != null &&
        targetDest != null &&
        (_lastDestination!.latitude != targetDest.latitude ||
            _lastDestination!.longitude != targetDest.longitude);

    _emitLoaded(emit);

    if (stageChanged || destChanged || (_routes.isEmpty && targetDest != null && _currentPosition != null)) {
      add(const RecalculateRoute(force: true));
    }
  }

  Future<void> _onRiderLocationUpdated(
    RiderLocationUpdated event,
    Emitter<RiderMapState> emit,
  ) async {
    final pos = LatLng(event.position.latitude, event.position.longitude);
    _currentPosition = pos;
    if (event.position.heading >= 0) {
      _currentHeading = event.position.heading;
    }

    final session = _latestSession;
    if (session == null || !session.hasOrder || session.order.isCompleted) {
      _emitLoaded(emit);
      return;
    }

    // 1. Throttled Firestore location update
    final riderId = session.riderId ?? session.order.riderId;
    if (riderId != null && riderId.isNotEmpty) {
      final now = DateTime.now();
      final timeDiff = _lastFirestoreUpdateTime == null
          ? 999
          : now.difference(_lastFirestoreUpdateTime!).inSeconds;
      final distanceMoved = _lastFirestoreUpdatePos == null
          ? 999.0
          : RouteUtils.distanceMeters(pos, _lastFirestoreUpdatePos!);

      // Write to Firestore if >= 15 seconds passed OR moved >= 25 meters
      if (timeDiff >= 15 || distanceMoved >= 25.0) {
        _lastFirestoreUpdateTime = now;
        _lastFirestoreUpdatePos = pos;
        _service.updateRiderLiveLocation(
          riderId: riderId,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      }
    }

    // 2. Off-Route & Destination Proximity Detection
    final dest = session.currentDestination;
    bool isNearDest = false;
    bool offRoute = false;

    if (dest != null) {
      final distToDest = RouteUtils.distanceMeters(pos, dest);
      isNearDest = distToDest <= 50.0;

      if (_routes.isNotEmpty) {
        final activeRoute = _selectedRouteIndex < _routes.length
            ? _routes[_selectedRouteIndex]
            : _routes.first;
        offRoute = RouteUtils.isOffRoute(pos, activeRoute.points, thresholdMeters: 50.0);
      } else if (!_isComputingRoute) {
        add(const RecalculateRoute(force: true));
      }
    }

    _emitLoaded(emit, isOffRoute: offRoute, isNearDestination: isNearDest);

    // Auto recalculate route if off-route and not recently calculated
    if (offRoute && !_isComputingRoute) {
      final now = DateTime.now();
      final lastCompute = _lastRouteComputeTime;
      if (lastCompute == null || now.difference(lastCompute).inSeconds >= 10) {
        add(const RecalculateRoute(force: false));
      }
    }
  }

  void _onSelectRoute(
    SelectRoute event,
    Emitter<RiderMapState> emit,
  ) {
    if (event.routeIndex >= 0 && event.routeIndex < _routes.length) {
      _selectedRouteIndex = event.routeIndex;
      _emitLoaded(emit);
    }
  }

  Future<void> _onRecalculateRoute(
    RecalculateRoute event,
    Emitter<RiderMapState> emit,
  ) async {
    final session = _latestSession;
    if (session == null) return;

    final origin = _currentPosition ??
        (session.riderLat != null && session.riderLng != null
            ? LatLng(session.riderLat!, session.riderLng!)
            : null);

    final destination = session.currentDestination;

    if (origin == null || destination == null) return;

    // Check if origin moved enough (> 30m) or force requested
    if (!event.force && _lastRouteComputeOrigin != null) {
      final moved = RouteUtils.distanceMeters(origin, _lastRouteComputeOrigin!);
      if (moved < 30.0) return;
    }

    _isComputingRoute = true;
    _lastRouteComputeTime = DateTime.now();
    _lastRouteComputeOrigin = origin;
    _lastDestination = destination;

    _emitLoaded(emit, isLoadingRoute: true);

    try {
      final calculatedRoutes = await _service.computeRoutes(
        origin: origin,
        destination: destination,
      );

      _routes = calculatedRoutes;
      _selectedRouteIndex = 0;
      _isComputingRoute = false;

      _emitLoaded(emit, isLoadingRoute: false, isOffRoute: false);
    } catch (e) {
      _isComputingRoute = false;
      _emitLoaded(
        emit,
        isLoadingRoute: false,
        routeError: 'Could not calculate road route: ${_clean(e)}',
      );
    }
  }

  void _emitLoaded(
    Emitter<RiderMapState> emit, {
    bool? isOffRoute,
    bool? isLoadingRoute,
    String? routeError,
    bool? isNearDestination,
  }) {
    if (_latestSession == null) return;

    emit(RiderMapLoaded(
      session: _latestSession!,
      routes: _routes,
      selectedRouteIndex: _selectedRouteIndex,
      currentPosition: _currentPosition,
      currentHeading: _currentHeading,
      isOffRoute: isOffRoute ?? (state is RiderMapLoaded ? (state as RiderMapLoaded).isOffRoute : false),
      isLoadingRoute: isLoadingRoute ?? false,
      routeError: routeError,
      isNearDestination: isNearDestination ?? (state is RiderMapLoaded ? (state as RiderMapLoaded).isNearDestination : false),
    ));
  }

  Future<void> _onMarkArrived(
    MarkArrived event,
    Emitter<RiderMapState> emit,
  ) async {
    final current = _currentSession();
    emit(RiderMapUpdating(current));

    try {
      await _service.markArrived(event.orderId);
    } catch (error) {
      emit(RiderMapError(
        message: _clean(error),
        session: current,
      ));
    }
  }

  Future<void> _onCompleteDelivery(
    CompleteDelivery event,
    Emitter<RiderMapState> emit,
  ) async {
    final current = _currentSession();
    emit(RiderMapUpdating(current));

    try {
      await _service.completeDelivery(
        orderId: event.orderId,
        recipientName: event.recipientName,
        signaturePoints: event.signaturePoints,
        medicineHandoverConfirmed: event.medicineHandoverConfirmed,
      );
      emit(RiderMapOperationSuccess(
        message: 'Delivery completed',
        session: RiderMapSession(order: current.order),
      ));
    } catch (error) {
      emit(RiderMapError(
        message: _clean(error),
        session: current,
      ));
    }
  }

  String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
