import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/pharmacy_orders_service.dart';
import 'pharmacy_orders_event.dart';
import 'pharmacy_orders_state.dart';

class PharmacyOrdersBloc
    extends Bloc<PharmacyOrdersEvent, PharmacyOrdersState> {
  PharmacyOrdersBloc({
    PharmacyOrdersService? service,
  })  : _service =
      service ?? PharmacyOrdersService.instance,
        super(const PharmacyOrdersInitial()) {
    on<LoadPharmacyOrders>(_onLoaded);

    on<PharmacyOrdersRefreshed>(_onRefreshed);

    on<PharmacyOrdersSearched>(_onSearched);

    on<PharmacyOrdersFiltered>(_onFiltered);

    on<PharmacyOrderAdded>(_onAdded);

    on<PharmacyOrderUpdated>(_onUpdated);

    on<PharmacyOrderDeleted>(_onDeleted);

    on<PharmacyOrderStatusChanged>(_onStatusChanged);
  }

  final PharmacyOrdersService _service;

  String _currentSearch = '';

  String _currentStatus = 'All';

  String _pharmacyId = '';

  // ==============================================================
  // LOAD ORDERS
  // ==============================================================

  Future<void> _onLoaded(
      LoadPharmacyOrders event,
      Emitter<PharmacyOrdersState> emit,
      ) async {
    if (event.pharmacyId.trim().isNotEmpty) {
      _pharmacyId = event.pharmacyId.trim();
    }

    emit(const PharmacyOrdersLoading());

    try {
      final allOrders =
      await _service.getOrders(_pharmacyId);

      final filtered = _applyFilters(
        allOrders,
        _currentSearch,
        _currentStatus,
      );

      emit(
        PharmacyOrdersLoaded(
          orders: filtered,
          allOrders: allOrders,
          selectedStatus: _currentStatus,
        ),
      );
    } catch (error) {
      emit(
        PharmacyOrdersError(
          _cleanError(error),
        ),
      );
    }
  }

  // ==============================================================
  // REFRESH
  // ==============================================================

  Future<void> _onRefreshed(
      PharmacyOrdersRefreshed event,
      Emitter<PharmacyOrdersState> emit,
      ) async {
    try {
      final allOrders =
      await _service.getOrders(_pharmacyId);

      final filtered = _applyFilters(
        allOrders,
        _currentSearch,
        _currentStatus,
      );

      emit(
        PharmacyOrdersLoaded(
          orders: filtered,
          allOrders: allOrders,
          selectedStatus: _currentStatus,
        ),
      );
    } catch (error) {
      emit(
        PharmacyOrdersError(
          _cleanError(error),
        ),
      );
    }
  }

  // ==============================================================
  // SEARCH
  // ==============================================================

  Future<void> _onSearched(
      PharmacyOrdersSearched event,
      Emitter<PharmacyOrdersState> emit,
      ) async {
    _currentSearch = event.query.trim().toLowerCase();

    final currentState = state;

    if (currentState is! PharmacyOrdersLoaded) {
      return;
    }

    final filtered = _applyFilters(
      currentState.allOrders,
      _currentSearch,
      _currentStatus,
    );

    emit(
      PharmacyOrdersLoaded(
        orders: filtered,
        allOrders: currentState.allOrders,
        selectedStatus: _currentStatus,
      ),
    );
  }

  // ==============================================================
  // FILTER
  // ==============================================================

  Future<void> _onFiltered(
      PharmacyOrdersFiltered event,
      Emitter<PharmacyOrdersState> emit,
      ) async {
    _currentStatus = event.status;

    final currentState = state;

    if (currentState is! PharmacyOrdersLoaded) {
      return;
    }

    final filtered = _applyFilters(
      currentState.allOrders,
      _currentSearch,
      _currentStatus,
    );

    emit(
      PharmacyOrdersLoaded(
        orders: filtered,
        allOrders: currentState.allOrders,
        selectedStatus: _currentStatus,
      ),
    );
  }

  // ==============================================================
  // ADD
  // ==============================================================

  Future<void> _onAdded(
      PharmacyOrderAdded event,
      Emitter<PharmacyOrdersState> emit,
      ) async {
    try {
      await _service.addOrder(
        pharmacyId: _pharmacyId,
        customerName: event.customerName,
        medicineCount: event.medicineCount,
        status: event.status,
        totalAmount: event.totalAmount,
        deliveryAddress: event.deliveryAddress,
        deliveryLat: event.deliveryLat,
        deliveryLng: event.deliveryLng,
      );

      final allOrders =
      await _service.getOrders(_pharmacyId);

      final filtered = _applyFilters(
        allOrders,
        _currentSearch,
        _currentStatus,
      );

      emit(
        PharmacyOrdersLoaded(
          orders: filtered,
          allOrders: allOrders,
          selectedStatus: _currentStatus,
        ),
      );
    } catch (error) {
      emit(
        PharmacyOrdersError(
          _cleanError(error),
        ),
      );
    }
  }

  // ==============================================================
  // UPDATE
  // ==============================================================

  Future<void> _onUpdated(
      PharmacyOrderUpdated event,
      Emitter<PharmacyOrdersState> emit,
      ) async {
    try {
      await _service.updateOrder(
        id: event.id,
        customerName: event.customerName,
        medicineCount: event.medicineCount,
        status: event.status,
        totalAmount: event.totalAmount,
      );

      final allOrders =
      await _service.getOrders(_pharmacyId);

      final filtered = _applyFilters(
        allOrders,
        _currentSearch,
        _currentStatus,
      );

      emit(
        PharmacyOrdersLoaded(
          orders: filtered,
          allOrders: allOrders,
          selectedStatus: _currentStatus,
        ),
      );
    } catch (error) {
      emit(
        PharmacyOrdersError(
          _cleanError(error),
        ),
      );
    }
  }

  // ==============================================================
  // DELETE
  // ==============================================================

  Future<void> _onDeleted(
      PharmacyOrderDeleted event,
      Emitter<PharmacyOrdersState> emit,
      ) async {
    try {
      await _service.deleteOrder(event.id);

      final allOrders =
      await _service.getOrders(_pharmacyId);

      final filtered = _applyFilters(
        allOrders,
        _currentSearch,
        _currentStatus,
      );

      emit(
        PharmacyOrdersLoaded(
          orders: filtered,
          allOrders: allOrders,
          selectedStatus: _currentStatus,
        ),
      );
    } catch (error) {
      emit(
        PharmacyOrdersError(
          _cleanError(error),
        ),
      );
    }
  }

  // ==============================================================
  // STATUS CHANGE
  // ==============================================================

  Future<void> _onStatusChanged(
      PharmacyOrderStatusChanged event,
      Emitter<PharmacyOrdersState> emit,
      ) async {
    try {
      await _service.updateOrderStatus(
        id: event.id,
        newStatus: event.newStatus,
        riderName: event.riderName,
        riderPhone: event.riderPhone,
      );

      final allOrders =
      await _service.getOrders(_pharmacyId);

      final filtered = _applyFilters(
        allOrders,
        _currentSearch,
        _currentStatus,
      );

      emit(
        PharmacyOrdersLoaded(
          orders: filtered,
          allOrders: allOrders,
          selectedStatus: _currentStatus,
        ),
      );
    } catch (error) {
      emit(
        PharmacyOrdersError(
          _cleanError(error),
        ),
      );
    }
  }

  // ==============================================================
  // FILTER LOGIC
  // ==============================================================

  List<PharmacyOrder> _applyFilters(
      List<PharmacyOrder> orders,
      String search,
      String status,
      ) {
    return orders.where((order) {
      final normalizedSearch =
      search.trim().toLowerCase();

      final matchesSearch =
          normalizedSearch.isEmpty ||
              order.id
                  .toLowerCase()
                  .contains(normalizedSearch) ||
              order.customerName
                  .toLowerCase()
                  .contains(normalizedSearch);

      final matchesStatus =
          status == 'All' ||
              order.status.toLowerCase() ==
                  status.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // ==============================================================
  // ERROR CLEANUP
  // ==============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }
}