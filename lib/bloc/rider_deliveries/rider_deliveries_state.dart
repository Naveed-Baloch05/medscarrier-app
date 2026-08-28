import 'package:equatable/equatable.dart';

import '../../models/order_model.dart';

abstract class RiderDeliveriesState extends Equatable {
  const RiderDeliveriesState();

  @override
  List<Object?> get props => [];
}

class RiderDeliveriesInitial extends RiderDeliveriesState {
  const RiderDeliveriesInitial();
}

class RiderDeliveriesLoading extends RiderDeliveriesState {
  const RiderDeliveriesLoading();
}

class RiderDeliveriesLoaded extends RiderDeliveriesState {
  const RiderDeliveriesLoaded({
    required this.orders,
    required this.activeOrders,
    required this.completedOrders,
  });

  final List<OrderModel> orders;
  final List<OrderModel> activeOrders;
  final List<OrderModel> completedOrders;

  bool get hasActive => activeOrders.isNotEmpty;

  @override
  List<Object?> get props => [orders, activeOrders, completedOrders];
}

class RiderDeliveriesError extends RiderDeliveriesState {
  const RiderDeliveriesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
