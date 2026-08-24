import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/admin_dashboard_service.dart';
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
    on<AdminDashboardApprovePharmacy>(_onApprovePharmacy);
    on<AdminDashboardRejectPharmacy>(_onRejectPharmacy);
    on<AdminDashboardAssignOrder>(_onAssignOrder);
    on<AdminDashboardAutoAssignOrder>(_onAutoAssignOrder);
  }

  final AdminDashboardService _service;

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

  Future<void> _fetchAllData(Emitter<AdminDashboardState> emit) async {
    try {
      final results = await Future.wait([
        _service.fetchDashboardData(),
        _service.fetchPendingPharmacies(),
        _service.fetchReadyOrders(),
        _service.fetchActiveOrders(),
      ]);

      final data = results[0] as Map<String, int>;
      final pendingPharmacies = results[1] as List;
      final readyOrders = results[2] as List;
      final activeOrders = results[3] as List;

      emit(AdminDashboardLoaded(
        totalOrders: data['totalOrders'] ?? 0,
        activeOrders: data['activeOrders'] ?? 0,
        completedOrders: data['completedOrders'] ?? 0,
        avgDeliveryTime: data['avgDeliveryTime'] ?? 0,
        totalRiders: data['totalRiders'] ?? 0,
        onlineRiders: data['onlineRiders'] ?? 0,
        activeRiders: data['activeRiders'] ?? 0,
        totalPharmacies: data['totalPharmacies'] ?? 0,
        pendingPharmacies: data['pendingPharmacies'] ?? 0,
        activePharmacies: data['activePharmacies'] ?? 0,
        pendingPharmacyList: pendingPharmacies.cast(),
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
      add(const AdminDashboardRefreshed());
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
      add(const AdminDashboardRefreshed());
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
      add(const AdminDashboardRefreshed());
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
      add(const AdminDashboardRefreshed());
    } catch (error) {
      emit(AdminDashboardError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
