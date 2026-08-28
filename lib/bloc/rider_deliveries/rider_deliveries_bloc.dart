import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/rider_deliveries_service.dart';
import '../../models/order_model.dart';
import 'rider_deliveries_event.dart';
import 'rider_deliveries_state.dart';

class RiderDeliveriesBloc
    extends Bloc<RiderDeliveriesEvent, RiderDeliveriesState> {
  RiderDeliveriesBloc({
    RiderDeliveriesService? service,
    List<OrderModel>? initialOrders,
  })  : _service = service ?? RiderDeliveriesService.instance,
        super(initialOrders != null
            ? _buildLoaded(initialOrders)
            : const RiderDeliveriesInitial()) {
    on<LoadRiderDeliveries>(_onLoad);
    on<RefreshRiderDeliveries>(_onLoad);
  }

  static RiderDeliveriesState _buildLoaded(List<OrderModel> orders) {
    return RiderDeliveriesLoaded(
      orders: orders,
      activeOrders: orders.where((o) => o.isActive && !o.isCompleted).toList(),
      completedOrders: orders.where((o) => o.isCompleted).toList(),
    );
  }

  final RiderDeliveriesService _service;

  Future<void> _onLoad(
    RiderDeliveriesEvent event,
    Emitter<RiderDeliveriesState> emit,
  ) async {
    final riderId = event is LoadRiderDeliveries
        ? event.riderId
        : (event as RefreshRiderDeliveries).riderId;

    if (state is! RiderDeliveriesLoaded) {
      emit(const RiderDeliveriesLoading());
    }

    try {
      final orders = await _service.getRiderOrders(riderId);
      final active = orders.where((o) => o.isActive && !o.isCompleted).toList();
      final completed = orders.where((o) => o.isCompleted).toList();

      emit(RiderDeliveriesLoaded(
        orders: orders,
        activeOrders: active,
        completedOrders: completed,
      ));
    } catch (error) {
      emit(RiderDeliveriesError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
