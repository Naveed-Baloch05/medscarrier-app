import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/rider_home_service.dart';
import 'rider_home_event.dart';
import 'rider_home_state.dart';

class RiderHomeBloc extends Bloc<RiderHomeEvent, RiderHomeState> {
  RiderHomeBloc({RiderHomeService? service})
      : _service = service ?? RiderHomeService.instance,
        super(const RiderHomeInitial()) {
    on<LoadRiderHome>(_onLoaded);
    on<RiderHomeRefreshed>(_onRefreshed);
    on<RiderHomeToggleOnline>(_onToggleOnline);
    on<RiderHomeOrderStatusChanged>(_onOrderStatusChanged);
    on<RiderHomeConfirmDelivery>(_onConfirmDelivery);
  }

  final RiderHomeService _service;
  String _currentRiderId = '';

  Future<void> _onLoaded(
    LoadRiderHome event,
    Emitter<RiderHomeState> emit,
  ) async {
    _currentRiderId = event.riderId;
    emit(const RiderHomeLoading());

    try {
      await _fetchAllData(emit);
    } catch (error) {
      emit(RiderHomeError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRefreshed(
    RiderHomeRefreshed event,
    Emitter<RiderHomeState> emit,
  ) async {
    _currentRiderId = event.riderId;
    try {
      await _fetchAllData(emit);
    } catch (error) {
      emit(RiderHomeError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onToggleOnline(
    RiderHomeToggleOnline event,
    Emitter<RiderHomeState> emit,
  ) async {
    try {
      await _service.toggleOnlineStatus(event.riderId, event.isOnline);
      await _fetchAllData(emit);
    } catch (error) {
      emit(RiderHomeError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onOrderStatusChanged(
    RiderHomeOrderStatusChanged event,
    Emitter<RiderHomeState> emit,
  ) async {
    try {
      switch (event.newStatus) {
        case 'Picked Up':
          await _service.markOrderPickedUp(event.orderId);
          break;
        case 'On the Way':
          await _service.markOrderOnTheWay(event.orderId);
          break;
        case 'Delivered':
          await _service.markOrderDelivered(event.orderId);
          break;
      }
      await _fetchAllData(emit);
    } catch (error) {
      emit(RiderHomeError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onConfirmDelivery(
    RiderHomeConfirmDelivery event,
    Emitter<RiderHomeState> emit,
  ) async {
    try {
      await _service.updateDeliveryConfirmation(
        orderId: event.orderId,
        cdConfirmed: event.cdConfirmed,
        coldChainConfirmed: event.coldChainConfirmed,
      );
      await _fetchAllData(emit);
    } catch (error) {
      emit(RiderHomeError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _fetchAllData(Emitter<RiderHomeState> emit) async {
    final rider = await _service.getRiderProfile(_currentRiderId);

    if (rider == null) {
      emit(const RiderHomeError('Rider profile not found.'));
      return;
    }

    final orders = await _service.getRiderOrders(_currentRiderId);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final completedOrders = orders.where((o) => o.isCompleted).toList();
    final todayCompleted = completedOrders.where((o) {
      final delivered = o.deliveredAt;
      return delivered != null && delivered.isAfter(todayStart);
    }).toList();

    double totalDistance = 0;
    for (final order in completedOrders) {
      final km = order.distanceKm;
      if (km != null) totalDistance += km;
    }

    final activeOrders =
        orders.where((o) => o.status == 'Picked Up' || o.status == 'On the Way').toList();
    final activeOrder = activeOrders.isNotEmpty ? activeOrders.first : null;

    final upcomingOrders = orders
        .where((o) => o.status == 'Ready' || o.status == 'Assigned')
        .toList()
      ..sort((a, b) {
        final aTime = a.assignedAt ?? a.createdAt ?? DateTime(0);
        final bTime = b.assignedAt ?? b.createdAt ?? DateTime(0);
        return aTime.compareTo(bTime);
      });

    emit(RiderHomeLoaded(
      rider: rider,
      orders: orders,
      todayCompletedCount: todayCompleted.length,
      totalCompletedCount: completedOrders.length,
      totalDistanceKm: totalDistance,
      activeOrder: activeOrder,
      upcomingOrders: upcomingOrders,
    ));
  }
}
