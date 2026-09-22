import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/pharmacy_orders_service.dart';
import 'pharmacy_orders_event.dart';
import 'pharmacy_orders_state.dart';

class PharmacyOrdersBloc
    extends Bloc<PharmacyOrdersEvent, PharmacyOrdersState> {
  PharmacyOrdersBloc({
    PharmacyOrdersService? service,
  })  : _service = service ?? PharmacyOrdersService.instance,
        super(const PharmacyOrdersInitial()) {
    on<LoadPharmacyOrders>(_onLoaded);
    on<PharmacyOrdersStreamUpdated>(_onStreamUpdated);
    on<PharmacyOrdersRefreshed>(_onRefreshed);
    on<PharmacyOrdersSearched>(_onSearched);
    on<PharmacyOrdersFiltered>(_onFiltered);
    on<PharmacyOrderAdded>(_onAdded);
    on<PharmacyOrderUpdated>(_onUpdated);
    on<PharmacyOrderDeleted>(_onDeleted);
    on<PharmacyOrderStatusChanged>(_onStatusChanged);
  }

  final PharmacyOrdersService _service;
  StreamSubscription<List<PharmacyOrder>>? _ordersSubscription;

  String _currentSearch = '';
  String _currentStatus = 'All';
  String _pharmacyId = '';
  List<PharmacyOrder> _cachedAllOrders = [];

  // ==============================================================
  // LOAD ORDERS & SUBSCRIBE TO REAL-TIME STREAM
  // ==============================================================

  Future<void> _onLoaded(
    LoadPharmacyOrders event,
    Emitter<PharmacyOrdersState> emit,
  ) async {
    if (event.pharmacyId.trim().isNotEmpty) {
      _pharmacyId = event.pharmacyId.trim();
    }

    emit(const PharmacyOrdersLoading());

    // Cancel any previous stream subscription to prevent leaks
    await _ordersSubscription?.cancel();

    try {
      // First fetch initial list for immediate render
      final allOrders = await _service.getOrders(_pharmacyId);
      _cachedAllOrders = allOrders;

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

      // Now subscribe to real-time updates from Firestore
      _ordersSubscription = _service
          .pharmacyOrdersStream(_pharmacyId)
          .listen(
            (updatedOrders) {
              add(PharmacyOrdersStreamUpdated(updatedOrders));
            },
            onError: (error) {
              add(PharmacyOrdersStreamUpdated(_cachedAllOrders));
            },
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
  // STREAM UPDATED (REAL-TIME FIRESTORE EVENT)
  // ==============================================================

  void _onStreamUpdated(
    PharmacyOrdersStreamUpdated event,
    Emitter<PharmacyOrdersState> emit,
  ) {
    final typedOrders = event.orders.cast<PharmacyOrder>();
    _cachedAllOrders = typedOrders;

    final filtered = _applyFilters(
      typedOrders,
      _currentSearch,
      _currentStatus,
    );

    emit(
      PharmacyOrdersLoaded(
        orders: filtered,
        allOrders: typedOrders,
        selectedStatus: _currentStatus,
      ),
    );
  }

  // ==============================================================
  // REFRESH
  // ==============================================================

  Future<void> _onRefreshed(
    PharmacyOrdersRefreshed event,
    Emitter<PharmacyOrdersState> emit,
  ) async {
    try {
      final allOrders = await _service.getOrders(_pharmacyId);
      _cachedAllOrders = allOrders;

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

  void _onSearched(
    PharmacyOrdersSearched event,
    Emitter<PharmacyOrdersState> emit,
  ) {
    _currentSearch = event.query.trim().toLowerCase();

    final allOrders = state is PharmacyOrdersLoaded
        ? (state as PharmacyOrdersLoaded).allOrders
        : _cachedAllOrders;

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
  }

  // ==============================================================
  // FILTER
  // ==============================================================

  void _onFiltered(
    PharmacyOrdersFiltered event,
    Emitter<PharmacyOrdersState> emit,
  ) {
    _currentStatus = event.status;

    final allOrders = state is PharmacyOrdersLoaded
        ? (state as PharmacyOrdersLoaded).allOrders
        : _cachedAllOrders;

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
  }

  // ==============================================================
  // ADD ORDER
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
        customerPhone: event.customerPhone,
        controlledDrug: event.controlledDrug,
        coldChain: event.coldChain,
      );
      // Stream will automatically emit updated orders list
    } catch (error) {
      emit(
        PharmacyOrdersError(
          _cleanError(error),
        ),
      );
    }
  }

  // ==============================================================
  // UPDATE ORDER
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
      // Stream will automatically emit updated orders list
    } catch (error) {
      emit(
        PharmacyOrdersError(
          _cleanError(error),
        ),
      );
    }
  }

  // ==============================================================
  // DELETE ORDER
  // ==============================================================

  Future<void> _onDeleted(
    PharmacyOrderDeleted event,
    Emitter<PharmacyOrdersState> emit,
  ) async {
    try {
      await _service.deleteOrder(event.id);
      // Stream will automatically emit updated orders list
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
        riderId: event.riderId,
      );
      // Stream will automatically emit updated orders list
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
      final normalizedSearch = search.trim().toLowerCase();

      final matchesSearch = normalizedSearch.isEmpty ||
          order.id.toLowerCase().contains(normalizedSearch) ||
          order.customerName.toLowerCase().contains(normalizedSearch) ||
          order.riderName.toLowerCase().contains(normalizedSearch) ||
          order.deliveryAddress.toLowerCase().contains(normalizedSearch);

      if (status == 'All') {
        return matchesSearch;
      }

      final normStatus = status.toLowerCase();
      final orderStatus = order.status.toLowerCase();

      if (normStatus == 'ready') {
        final matchesReady = orderStatus == 'ready';
        return matchesSearch && matchesReady;
      }

      if (normStatus == 'preparing') {
        final matchesPreparing = orderStatus == 'preparing' || orderStatus == 'new';
        return matchesSearch && matchesPreparing;
      }

      if (normStatus == 'delivered') {
        final matchesDelivered = orderStatus == 'delivered' || orderStatus == 'completed';
        return matchesSearch && matchesDelivered;
      }

      final matchesStatus = orderStatus == normStatus;
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

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}