import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/services/pharmacy_tracking_service.dart';
import '../../core/services/rider_map_service.dart';
import '../../models/delivery_route_model.dart';
import '../../models/order_model.dart';
import '../../models/rider_live_location.dart';
import '../../models/rider_model.dart';
import 'pharmacy_tracking_event.dart';
import 'pharmacy_tracking_state.dart';

class PharmacyTrackingBloc
    extends Bloc<PharmacyTrackingEvent, PharmacyTrackingState> {
  PharmacyTrackingBloc({
    PharmacyTrackingService? trackingService,
    RiderMapService? mapService,
  })  : _trackingService = trackingService ?? PharmacyTrackingService.instance,
        _mapService = mapService ?? RiderMapService.instance,
        super(const PharmacyTrackingInitial()) {
    on<InitPharmacyTracking>(_onInit);
    on<TrackedRouteStreamUpdated>(_onRouteUpdated);
    on<RiderLocationStreamUpdated>(_onRiderUpdated);
    on<TrackedOrdersStreamUpdated>(_onOrdersUpdated);
    on<RiderBatchLocationUpdated>(_onBatchLocationUpdated);
    on<SelectTrackedOrder>(_onSelectOrder);
    on<SelectTrackedStop>(_onSelectStop);
  }

  final PharmacyTrackingService _trackingService;
  final RiderMapService _mapService;

  StreamSubscription<DeliveryRouteModel?>? _routeSub;
  StreamSubscription<RiderModel?>? _riderSub;
  StreamSubscription<List<OrderModel>>? _ordersSub;
  StreamSubscription<RiderLiveLocation?>? _batchLocationSub;

  String _pharmacyId = '';
  String _riderId = '';
  String? _routeId;
  String? _selectedOrderId;
  String? _selectedStopId;
  LatLng? _pharmacyLocation;

  DeliveryRouteModel? _currentRoute;
  RiderModel? _currentRider;
  List<OrderModel> _currentOrders = [];
  RiderLiveLocation? _currentLiveLocation;

  // ==============================================================
  // INIT TRACKING
  // ==============================================================

  Future<void> _onInit(
    InitPharmacyTracking event,
    Emitter<PharmacyTrackingState> emit,
  ) async {
    _pharmacyId = event.pharmacyId.trim();
    _riderId = event.riderId.trim();
    _routeId = event.routeId?.trim();
    _selectedOrderId = event.initialOrderId;

    emit(const PharmacyTrackingLoading());

    await _routeSub?.cancel();
    await _riderSub?.cancel();
    await _ordersSub?.cancel();
    await _batchLocationSub?.cancel();

    try {
      _pharmacyLocation =
          await _trackingService.fetchPharmacyLocation(_pharmacyId);

      // 1. Subscribe to Route Stream
      if (_routeId != null && _routeId!.isNotEmpty) {
        _routeSub = _trackingService.routeStream(_routeId!).listen((route) {
          add(TrackedRouteStreamUpdated(route));
        });
      } else {
        _routeSub = _trackingService
            .activeRouteForPharmacyStream(
          pharmacyId: _pharmacyId,
          riderId: _riderId.isNotEmpty ? _riderId : null,
        )
            .listen((route) {
          add(TrackedRouteStreamUpdated(route));
        });
      }

      // 2. If riderId is provided upfront, start listening to rider & location
      if (_riderId.isNotEmpty) {
        _startRiderSubscriptions(_riderId);
      }

      // 3. Keep assigned orders stream for backward compatibility
      if (_riderId.isNotEmpty) {
        _ordersSub = _trackingService
            .pharmacyRiderOrdersStream(
          pharmacyId: _pharmacyId,
          riderId: _riderId,
        )
            .listen((orders) {
          add(TrackedOrdersStreamUpdated(orders));
        });
      }
    } catch (e) {
      emit(PharmacyTrackingError(e.toString()));
    }
  }

  void _startRiderSubscriptions(String riderId) {
    if (riderId.isEmpty) return;
    _riderSub?.cancel();
    _batchLocationSub?.cancel();

    _riderSub = _trackingService.riderLiveLocationStream(riderId).listen((rider) {
      add(RiderLocationStreamUpdated(rider));
    });

    _batchLocationSub =
        _trackingService.riderBatchLocationStream(riderId).listen((location) {
      add(RiderBatchLocationUpdated(location));
    });
  }

  // ==============================================================
  // ROUTE UPDATED (REAL-TIME)
  // ==============================================================

  Future<void> _onRouteUpdated(
    TrackedRouteStreamUpdated event,
    Emitter<PharmacyTrackingState> emit,
  ) async {
    _currentRoute = event.route;

    if (_currentRoute != null) {
      final routeRiderId = _currentRoute!.riderId.trim();
      if (routeRiderId.isNotEmpty && routeRiderId != _riderId) {
        _riderId = routeRiderId;
        _startRiderSubscriptions(routeRiderId);
      }
    }

    await _rebuildState(emit);
  }

  // ==============================================================
  // RIDER LOCATION UPDATED (REAL-TIME)
  // ==============================================================

  Future<void> _onRiderUpdated(
    RiderLocationStreamUpdated event,
    Emitter<PharmacyTrackingState> emit,
  ) async {
    _currentRider = event.rider;
    await _rebuildState(emit);
  }

  // ==============================================================
  // ORDERS UPDATED (REAL-TIME)
  // ==============================================================

  Future<void> _onOrdersUpdated(
    TrackedOrdersStreamUpdated event,
    Emitter<PharmacyTrackingState> emit,
  ) async {
    _currentOrders = event.orders;
    await _rebuildState(emit);
  }

  // ==============================================================
  // BATCH LIVE LOCATION UPDATED (REAL-TIME)
  // ==============================================================

  Future<void> _onBatchLocationUpdated(
    RiderBatchLocationUpdated event,
    Emitter<PharmacyTrackingState> emit,
  ) async {
    _currentLiveLocation = event.location;
    await _rebuildState(emit);
  }

  // ==============================================================
  // SELECT ORDER MANUALLY
  // ==============================================================

  Future<void> _onSelectOrder(
    SelectTrackedOrder event,
    Emitter<PharmacyTrackingState> emit,
  ) async {
    _selectedOrderId = event.orderId;
    _selectedStopId = event.orderId;
    await _rebuildState(emit);
  }

  Future<void> _onSelectStop(
    SelectTrackedStop event,
    Emitter<PharmacyTrackingState> emit,
  ) async {
    _selectedStopId = event.stopId;
    _selectedOrderId = event.stopId;
    await _rebuildState(emit);
  }

  // ==============================================================
  // REBUILD STATE & MAP OVERLAYS
  // ==============================================================

  Future<void> _rebuildState(Emitter<PharmacyTrackingState> emit) async {
    final stops = _currentRoute?.stops ?? const <RouteStopModel>[];

    RouteStopModel? activeStop;
    RouteStopModel? selectedStop;

    if (stops.isNotEmpty) {
      // 1. Resolve selected stop
      if (_selectedStopId != null) {
        final matches = stops.where(
          (s) => s.id == _selectedStopId || s.orderId == _selectedStopId,
        );
        if (matches.isNotEmpty) {
          selectedStop = matches.first;
        }
      }

      // 2. Resolve active stop
      final liveStopIdx = _currentLiveLocation?.currentStopIndex;
      if (liveStopIdx != null && liveStopIdx >= 0 && liveStopIdx < stops.length) {
        activeStop = stops[liveStopIdx];
      } else {
        final pending = stops.where((s) => s.isPending);
        if (pending.isNotEmpty) {
          activeStop = pending.first;
        } else {
          activeStop = stops.last;
        }
      }

      selectedStop ??= activeStop;
    }

    OrderModel? selectedOrder;
    if (_currentOrders.isNotEmpty) {
      if (_selectedOrderId != null) {
        final match = _currentOrders.where(
          (o) => o.id == _selectedOrderId || o.orderId == _selectedOrderId,
        );
        if (match.isNotEmpty) {
          selectedOrder = match.first;
        }
      }
      selectedOrder ??= _currentOrders.firstWhere(
        (o) =>
            o.status.toLowerCase() == 'on the way' ||
            o.status.toLowerCase() == 'picked up' ||
            o.status.toLowerCase() == 'arrived',
        orElse: () => _currentOrders.first,
      );
    }

    final markers = <Marker>{};
    final polylines = <Polyline>{};

    // 1. Pharmacy Marker
    if (_pharmacyLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pharmacy_base'),
          position: _pharmacyLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: 'Pharmacy (Origin)',
            snippet: 'Dispatch Base',
          ),
        ),
      );
    }

    // 2. Rider Live Marker
    final riderLatLng =
        _currentLiveLocation?.latLng ?? _currentRider?.latLng;
    if (riderLatLng != null) {
      final isLive = _currentLiveLocation?.isActivelyDelivering == true;
      final riderDisplayName = _currentRider?.fullName.isNotEmpty == true
          ? _currentRider!.fullName
          : (_currentRoute?.name.isNotEmpty == true
              ? _currentRoute!.name
              : 'Assigned Rider');

      markers.add(
        Marker(
          markerId: MarkerId('rider_$_riderId'),
          position: riderLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: InfoWindow(
            title: 'Rider: $riderDisplayName',
            snippet: isLive
                ? 'Delivering stop ${_currentLiveLocation!.stopNumber} of ${_currentLiveLocation!.totalStops}'
                : (_currentRoute?.isActive == true
                    ? 'Delivering'
                    : (_currentRoute?.isCompleted == true
                        ? 'Route Completed'
                        : 'On Route')),
          ),
        ),
      );
    }

    // 3. Stop Markers in EXACT OPTIMIZED ORDER
    if (stops.isNotEmpty) {
      for (int i = 0; i < stops.length; i++) {
        final stop = stops[i];
        final stopLatLng = stop.latLng;
        if (stopLatLng != null) {
          final isDelivered = stop.isDelivered;
          final isFailed = stop.isFailed;
          final isActive = stop.id == activeStop?.id || stop.orderId == activeStop?.orderId;

          double hue = BitmapDescriptor.hueOrange; // Pending
          if (isDelivered) {
            hue = BitmapDescriptor.hueGreen;
          } else if (isFailed) {
            hue = BitmapDescriptor.hueRose;
          } else if (isActive) {
            hue = BitmapDescriptor.hueCyan;
          }

          markers.add(
            Marker(
              markerId: MarkerId('stop_${stop.id}'),
              position: stopLatLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
              infoWindow: InfoWindow(
                title: '${stop.sequence}. ${stop.customerName}',
                snippet: '${stop.status.toUpperCase()} • ${stop.formattedAddress}',
              ),
            ),
          );
        }
      }

      // Complete Route Polyline connecting all stops
      final stopPoints = <LatLng>[];
      if (_pharmacyLocation != null) stopPoints.add(_pharmacyLocation!);
      for (final s in stops) {
        if (s.latLng != null) stopPoints.add(s.latLng!);
      }

      if (stopPoints.length >= 2) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('optimized_route_path'),
            points: stopPoints,
            color: const Color(0xFF0F7253),
            width: 4,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }
    } else {
      // Fallback to legacy orders
      for (int i = 0; i < _currentOrders.length; i++) {
        final order = _currentOrders[i];
        final dropoff = order.dropoffLatLng;
        if (dropoff != null) {
          final statusNorm = order.status.toLowerCase();
          double hue = BitmapDescriptor.hueOrange;
          if (statusNorm == 'delivered' || statusNorm == 'completed') {
            hue = BitmapDescriptor.hueGreen;
          } else if (statusNorm == 'failed') {
            hue = BitmapDescriptor.hueRose;
          } else if (statusNorm == 'on the way' || statusNorm == 'picked up') {
            hue = BitmapDescriptor.hueViolet;
          }

          markers.add(
            Marker(
              markerId: MarkerId('order_${order.id}'),
              position: dropoff,
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
              infoWindow: InfoWindow(
                title: 'Stop #${i + 1}: ${order.customerName}',
                snippet: '${order.displayStatus} • ${order.dropoffAddress}',
              ),
            ),
          );
        }
      }
    }

    // 4. Active Delivery Segment Polyline (Rider -> Active Stop)
    final targetLatLng = selectedStop?.latLng ??
        activeStop?.latLng ??
        selectedOrder?.dropoffLatLng;

    if (riderLatLng != null && targetLatLng != null) {
      try {
        final routes = await _mapService.computeRoutes(
          origin: riderLatLng,
          destination: targetLatLng,
        );
        if (routes.isNotEmpty && routes.first.points.isNotEmpty) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('rider_to_active_stop'),
              points: routes.first.points,
              color: const Color(0xFF0F7253),
              width: 5,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        }
      } catch (_) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('rider_to_active_stop_direct'),
            points: [riderLatLng, targetLatLng],
            color: const Color(0xFF0F7253),
            width: 4,
            patterns: [PatternItem.dash(10), PatternItem.gap(6)],
          ),
        );
      }
    }

    emit(
      PharmacyTrackingLoaded(
        pharmacyId: _pharmacyId,
        riderId: _riderId,
        route: _currentRoute,
        rider: _currentRider,
        orders: _currentOrders,
        liveLocation: _currentLiveLocation,
        selectedOrder: selectedOrder,
        activeStop: activeStop,
        selectedStop: selectedStop,
        pharmacyLocation: _pharmacyLocation,
        markers: markers,
        polylines: polylines,
      ),
    );
  }

  @override
  Future<void> close() {
    _routeSub?.cancel();
    _riderSub?.cancel();
    _ordersSub?.cancel();
    _batchLocationSub?.cancel();
    return super.close();
  }
}
