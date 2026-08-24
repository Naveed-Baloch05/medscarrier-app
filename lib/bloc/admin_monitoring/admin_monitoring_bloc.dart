import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/admin_monitoring_service.dart';
import 'admin_monitoring_event.dart';
import 'admin_monitoring_state.dart';

class AdminMonitoringBloc
    extends Bloc<AdminMonitoringEvent, AdminMonitoringState> {
  AdminMonitoringBloc({
    AdminMonitoringService? service,
  })  : _service = service ?? AdminMonitoringService.instance,
        super(const AdminMonitoringInitial()) {
    on<AdminMonitoringStartRequested>(_onStartRequested);
    on<AdminMonitoringStopRequested>(_onStopRequested);
    on<AdminMonitoringRiderTracked>(_onRiderTracked);
    on<_RidersUpdated>(_onRidersUpdated);
    on<_RiderUpdated>(_onRiderUpdatedInternal);
    on<_RidersError>(_onRidersError);
  }

  final AdminMonitoringService _service;
  StreamSubscription<List<Map<String, dynamic>>>? _ridersSubscription;
  StreamSubscription<Map<String, dynamic>>? _riderSubscription;

  Future<void> _onStartRequested(
    AdminMonitoringStartRequested event,
    Emitter<AdminMonitoringState> emit,
  ) async {
    emit(const AdminMonitoringLoading());

    await _riderSubscription?.cancel();
    _riderSubscription = null;

    await _ridersSubscription?.cancel();
    _ridersSubscription = _service.allRidersLocationStream().listen(
      (riders) {
        if (!isClosed) {
          add(_RidersUpdated(riders));
        }
      },
      onError: (error) {
        if (!isClosed) {
          add(_RidersError(error.toString()));
        }
      },
    );
  }

  Future<void> _onStopRequested(
    AdminMonitoringStopRequested event,
    Emitter<AdminMonitoringState> emit,
  ) async {
    await _ridersSubscription?.cancel();
    _ridersSubscription = null;
    await _riderSubscription?.cancel();
    _riderSubscription = null;
    emit(const AdminMonitoringInitial());
  }

  Future<void> _onRiderTracked(
    AdminMonitoringRiderTracked event,
    Emitter<AdminMonitoringState> emit,
  ) async {
    await _riderSubscription?.cancel();

    _riderSubscription = _service
        .riderLocationStream(event.riderId)
        .listen(
      (rider) {
        if (!isClosed) {
          add(_RiderUpdated(rider));
        }
      },
      onError: (error) {
        if (!isClosed) {
          add(_RidersError(error.toString()));
        }
      },
    );
  }

  void _onRidersUpdated(
    _RidersUpdated event,
    Emitter<AdminMonitoringState> emit,
  ) {
    emit(AdminMonitoringActive(event.riders));
  }

  void _onRiderUpdatedInternal(
    _RiderUpdated event,
    Emitter<AdminMonitoringState> emit,
  ) {
    emit(AdminMonitoringRiderFocused(event.rider));
  }

  void _onRidersError(
    _RidersError event,
    Emitter<AdminMonitoringState> emit,
  ) {
    emit(AdminMonitoringError(event.message));
  }

  @override
  Future<void> close() {
    _ridersSubscription?.cancel();
    _riderSubscription?.cancel();
    return super.close();
  }
}

// Internal events for stream handling
class _RidersUpdated extends AdminMonitoringEvent {
  const _RidersUpdated(this.riders);
  final List<Map<String, dynamic>> riders;
}

class _RiderUpdated extends AdminMonitoringEvent {
  const _RiderUpdated(this.rider);
  final Map<String, dynamic> rider;
}

class _RidersError extends AdminMonitoringEvent {
  const _RidersError(this.message);
  final String message;
}
