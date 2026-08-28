import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/admin_dashboard_service.dart';
import '../../models/pharmacy_model.dart';
import '../../models/rider_application_model.dart';
import 'admin_dashboard_event.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  AdminDashboardBloc({
    AdminDashboardService? service,
  })  : _service = service ?? AdminDashboardService.instance,
        super(const AdminDashboardInitial()) {
    on<AdminDashboardLoadRequested>(_onLoadRequested);
    on<AdminDashboardRefreshed>(_onRefreshed);
    on<AdminDashboardPendingPharmaciesUpdated>(_onPendingPharmaciesUpdated);
    on<AdminDashboardPendingRidersUpdated>(_onPendingRidersUpdated);
    on<AdminDashboardApprovePharmacy>(_onApprovePharmacy);
    on<AdminDashboardRejectPharmacy>(_onRejectPharmacy);
    on<AdminDashboardApproveRider>(_onApproveRider);
    on<AdminDashboardRejectRider>(_onRejectRider);
    on<AdminDashboardAssignOrder>(_onAssignOrder);
    on<AdminDashboardAutoAssignOrder>(_onAutoAssignOrder);

    _pendingPharmaciesSubscription =
        _service.streamPendingPharmacies().listen((list) {
      add(AdminDashboardPendingPharmaciesUpdated(list));
    });

    _pendingRidersSubscription =
        _service.streamPendingRiders().listen((list) {
      add(AdminDashboardPendingRidersUpdated(list));
    });
  }

  final AdminDashboardService _service;
  StreamSubscription? _pendingPharmaciesSubscription;
  StreamSubscription? _pendingRidersSubscription;

  @override
  Future<void> close() {
    _pendingPharmaciesSubscription?.cancel();
    _pendingRidersSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadRequested(
    AdminDashboardLoadRequested event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(const AdminDashboardLoading());
    await _fetchAllData(emit);
  }

  Future<void> _onRefreshed(
    AdminDashboardRefreshed event,
    Emitter<AdminDashboardState> emit,
  ) async {
    await _fetchAllData(emit);
  }

  void _onPendingPharmaciesUpdated(
    AdminDashboardPendingPharmaciesUpdated event,
    Emitter<AdminDashboardState> emit,
  ) {
    final list = event.pendingPharmacies.cast<PharmacyModel>();
    if (state is AdminDashboardLoaded) {
      final current = state as AdminDashboardLoaded;
      emit(current.copyWith(
        pendingPharmacies: list.length,
        pendingPharmacyList: list,
      ));
    }
  }

  void _onPendingRidersUpdated(
    AdminDashboardPendingRidersUpdated event,
    Emitter<AdminDashboardState> emit,
  ) {
    final list = event.pendingRiders.cast<RiderApplicationModel>();
    if (state is AdminDashboardLoaded) {
      final current = state as AdminDashboardLoaded;
      emit(current.copyWith(
        pendingRiders: list.length,
        pendingRiderList: list,
      ));
    }
  }

  Future<void> _fetchAllData(Emitter<AdminDashboardState> emit) async {
    try {
      final results = await Future.wait([
        _service.fetchDashboardData(),
        _service.fetchPendingPharmacies(),
        _service.fetchPendingRiders(),
        _service.fetchReadyOrders(),
        _service.fetchActiveOrders(),
      ]);

      final data = results[0] as Map<String, int>;
      final pendingPharmacies = results[1] as List;
      final pendingRiders = results[2] as List;
      final readyOrders = results[3] as List;
      final activeOrders = results[4] as List;

      emit(AdminDashboardLoaded(
        totalOrders: data['totalOrders'] ?? 0,
        activeOrders: data['activeOrders'] ?? 0,
        completedOrders: data['completedOrders'] ?? 0,
        avgDeliveryTime: data['avgDeliveryTime'] ?? 0,
        totalRiders: data['totalRiders'] ?? 0,
        onlineRiders: data['onlineRiders'] ?? 0,
        activeRiders: data['activeRiders'] ?? 0,
        totalPharmacies: data['totalPharmacies'] ?? 0,
        pendingPharmacies: data['pendingPharmacies'] ?? pendingPharmacies.length,
        activePharmacies: data['activePharmacies'] ?? 0,
        pendingRiders: data['pendingRiders'] ?? pendingRiders.length,
        pendingPharmacyList: pendingPharmacies.cast(),
        pendingRiderList: pendingRiders.cast(),
        readyOrderList: readyOrders.cast(),
        activeOrderList: activeOrders.cast(),
      ));
    } catch (error) {
      emit(AdminDashboardError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onApprovePharmacy(
    AdminDashboardApprovePharmacy event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      await _service.approvePharmacy(event.pharmacyId);
      emit(const AdminDashboardActionSuccess('Pharmacy approved and password setup link sent.'));
      await _fetchAllData(emit);
    } catch (error) {
      emit(AdminDashboardError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRejectPharmacy(
    AdminDashboardRejectPharmacy event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      await _service.rejectPharmacy(event.pharmacyId);
      emit(const AdminDashboardActionSuccess('Pharmacy application rejected.'));
      await _fetchAllData(emit);
    } catch (error) {
      emit(AdminDashboardError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onApproveRider(
    AdminDashboardApproveRider event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      await _service.approveRider(event.applicationId);
      emit(const AdminDashboardActionSuccess(
          'Rider approved and password setup email sent.'));
      await _fetchAllData(emit);
    } catch (error) {
      emit(AdminDashboardError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRejectRider(
    AdminDashboardRejectRider event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      await _service.rejectRider(event.applicationId, reason: event.reason);
      emit(const AdminDashboardActionSuccess('Rider application rejected.'));
      await _fetchAllData(emit);
    } catch (error) {
      emit(AdminDashboardError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onAssignOrder(
    AdminDashboardAssignOrder event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      await _service.assignOrder(event.orderId, event.riderId);
      await _fetchAllData(emit);
    } catch (error) {
      emit(AdminDashboardError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onAutoAssignOrder(
    AdminDashboardAutoAssignOrder event,
    Emitter<AdminDashboardState> emit,
  ) async {
    try {
      await _service.autoAssignOrder(event.orderId);
      await _fetchAllData(emit);
    } catch (error) {
      emit(AdminDashboardError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
