import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/admin_order_service.dart';
import 'admin_order_event.dart';
import 'admin_order_state.dart';

class AdminOrderBloc extends Bloc<AdminOrderEvent, AdminOrderState> {
  AdminOrderBloc({
    AdminOrderService? service,
  })  : _service = service ?? AdminOrderService.instance,
        super(const AdminOrderInitial()) {
    on<AdminOrderLoadRequested>(_onLoadRequested);
    on<AdminOrderAssigned>(_onAssigned);
    on<AdminOrderAutoAssigned>(_onAutoAssigned);
    on<AdminOrderStatusUpdated>(_onStatusUpdated);
    on<AdminOrderCancelled>(_onCancelled);
    on<AdminOrderFiltered>(_onFiltered);
    on<AdminOrderRefreshed>(_onRefreshed);
  }

  final AdminOrderService _service;
  String? _activeFilter;

  Future<void> _loadData(Emitter<AdminOrderState> emit) async {
    List<Map<String, dynamic>> orders;

    if (_activeFilter != null && _activeFilter != 'All') {
      orders = await _service.getOrdersByStatus(_activeFilter!);
    } else {
      orders = await _service.getAllOrders();
    }

    emit(AdminOrderLoaded(orders, activeFilter: _activeFilter));
  }

  Future<void> _onLoadRequested(
    AdminOrderLoadRequested event,
    Emitter<AdminOrderState> emit,
  ) async {
    emit(const AdminOrderLoading());
    try {
      await _loadData(emit);
    } catch (error) {
      emit(AdminOrderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRefreshed(
    AdminOrderRefreshed event,
    Emitter<AdminOrderState> emit,
  ) async {
    try {
      await _loadData(emit);
    } catch (error) {
      emit(AdminOrderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onAssigned(
    AdminOrderAssigned event,
    Emitter<AdminOrderState> emit,
  ) async {
    try {
      await _service.assignOrder(event.orderId, event.riderId);
      emit(const AdminOrderOperationSuccess('Order assigned to rider.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminOrderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onAutoAssigned(
    AdminOrderAutoAssigned event,
    Emitter<AdminOrderState> emit,
  ) async {
    try {
      await _service.autoAssignOrder(event.orderId);
      emit(const AdminOrderOperationSuccess('Order auto-assigned.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminOrderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onStatusUpdated(
    AdminOrderStatusUpdated event,
    Emitter<AdminOrderState> emit,
  ) async {
    try {
      await _service.updateOrderStatus(event.orderId, event.status);
      emit(AdminOrderOperationSuccess('Order status updated to ${event.status}.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminOrderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onCancelled(
    AdminOrderCancelled event,
    Emitter<AdminOrderState> emit,
  ) async {
    try {
      await _service.cancelOrder(event.orderId);
      emit(const AdminOrderOperationSuccess('Order cancelled.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminOrderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onFiltered(
    AdminOrderFiltered event,
    Emitter<AdminOrderState> emit,
  ) async {
    _activeFilter = event.status;
    try {
      await _loadData(emit);
    } catch (error) {
      emit(AdminOrderError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
