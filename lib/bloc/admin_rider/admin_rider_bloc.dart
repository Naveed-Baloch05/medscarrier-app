import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/admin_dashboard_service.dart';
import '../../core/services/admin_rider_service.dart';
import 'admin_rider_event.dart';
import 'admin_rider_state.dart';

class AdminRiderBloc extends Bloc<AdminRiderEvent, AdminRiderState> {
  AdminRiderBloc({
    AdminRiderService? service,
    AdminDashboardService? dashboardService,
  })  : _service = service ?? AdminRiderService.instance,
        _dashboardService =
            dashboardService ?? AdminDashboardService.instance,
        super(const AdminRiderInitial()) {
    on<AdminRiderLoadRequested>(_onLoadRequested);
    on<AdminRiderAdded>(_onAdded);
    on<AdminRiderUpdated>(_onUpdated);
    on<AdminRiderActivated>(_onActivated);
    on<AdminRiderDeactivated>(_onDeactivated);
    on<AdminRiderOrderAssigned>(_onOrderAssigned);
    on<AdminRiderRefreshed>(_onRefreshed);
    on<AdminRiderApplicationApprove>(_onApplicationApprove);
    on<AdminRiderApplicationReject>(_onApplicationReject);
  }

  final AdminRiderService _service;
  final AdminDashboardService _dashboardService;

  Future<void> _loadData(Emitter<AdminRiderState> emit) async {
    final riders = await _service.getAllRiders();
    final pendingApplications =
        await _dashboardService.getPendingApplications();
    emit(AdminRiderLoadedWithApplications(
      riders,
      pendingApplications,
    ));
  }

  Future<void> _onLoadRequested(
    AdminRiderLoadRequested event,
    Emitter<AdminRiderState> emit,
  ) async {
    emit(const AdminRiderLoading());
    try {
      await _loadData(emit);
    } catch (error) {
      emit(AdminRiderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRefreshed(
    AdminRiderRefreshed event,
    Emitter<AdminRiderState> emit,
  ) async {
    try {
      await _loadData(emit);
    } catch (error) {
      emit(AdminRiderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onAdded(
    AdminRiderAdded event,
    Emitter<AdminRiderState> emit,
  ) async {
    try {
      await _service.addRider(event.riderData);
      emit(const AdminRiderOperationSuccess('Rider added successfully.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminRiderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onUpdated(
    AdminRiderUpdated event,
    Emitter<AdminRiderState> emit,
  ) async {
    try {
      await _service.updateRider(event.riderId, event.data);
      emit(const AdminRiderOperationSuccess('Rider updated.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminRiderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onActivated(
    AdminRiderActivated event,
    Emitter<AdminRiderState> emit,
  ) async {
    try {
      await _service.activateRider(event.riderId);
      emit(const AdminRiderOperationSuccess('Rider activated.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminRiderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onDeactivated(
    AdminRiderDeactivated event,
    Emitter<AdminRiderState> emit,
  ) async {
    try {
      await _service.deactivateRider(event.riderId);
      emit(const AdminRiderOperationSuccess('Rider deactivated.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminRiderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onOrderAssigned(
    AdminRiderOrderAssigned event,
    Emitter<AdminRiderState> emit,
  ) async {
    try {
      await _service.assignOrderToRider(event.riderId, event.orderId);
      emit(const AdminRiderOperationSuccess('Order assigned to rider.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminRiderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onApplicationApprove(
    AdminRiderApplicationApprove event,
    Emitter<AdminRiderState> emit,
  ) async {
    try {
      await _dashboardService.approveRiderApplication(
        applicationId: event.applicationId,
      );
      emit(const AdminRiderOperationSuccess(
        'Rider application approved.',
      ));
      await _loadData(emit);
    } catch (error) {
      emit(AdminRiderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onApplicationReject(
    AdminRiderApplicationReject event,
    Emitter<AdminRiderState> emit,
  ) async {
    try {
      await _dashboardService.rejectRiderApplication(
        applicationId: event.applicationId,
        rejectionReason: event.rejectionReason,
      );
      emit(const AdminRiderOperationSuccess(
        'Rider application rejected.',
      ));
      await _loadData(emit);
    } catch (error) {
      emit(AdminRiderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
