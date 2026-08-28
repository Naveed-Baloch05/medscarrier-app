import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/rider_map_service.dart';
import 'rider_map_event.dart';
import 'rider_map_state.dart';

class RiderMapBloc extends Bloc<RiderMapEvent, RiderMapState> {
  RiderMapBloc({RiderMapService? service})
      : _service = service ?? RiderMapService.instance,
        super(const RiderMapInitial()) {
    on<SubscribeToMap>(_onSubscribe);
    on<SubscribeToOrder>(_onSubscribeOrder);
    on<LoadMapOrder>(_onLoad);
    on<MarkArrived>(_onMarkArrived);
    on<CompleteDelivery>(_onCompleteDelivery);
  }

  final RiderMapService _service;

  StreamSubscription<RiderMapSession>? _mapSubscription;
  RiderMapSession? _latestSession;

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
        if (!isClosed && session.order.id.isNotEmpty) {
          _latestSession = session;
          emit(RiderMapLoaded(session));
        } else if (!isClosed) {
          emit(RiderMapLoaded(session));
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
    _mapSubscription = _service.orderSessionStream(event.orderId).listen(
      (session) {
        if (!isClosed) {
          if (session.order.id.isNotEmpty) _latestSession = session;
          emit(RiderMapLoaded(session));
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

  Future<void> _onLoad(
    LoadMapOrder event,
    Emitter<RiderMapState> emit,
  ) async {
    emit(const RiderMapLoading());
    try {
      await _subscribeOnce(event.riderId, emit);
    } catch (error) {
      emit(RiderMapError(message: _clean(error)));
    }
  }

  Future<void> _subscribeOnce(
    String riderId,
    Emitter<RiderMapState> emit,
  ) async {
    await _mapSubscription?.cancel();
    _mapSubscription = _service.mapSessionStream(riderId).listen(
          (session) {
            if (!isClosed) {
              if (session.order.id.isNotEmpty) _latestSession = session;
              emit(RiderMapLoaded(session));
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
