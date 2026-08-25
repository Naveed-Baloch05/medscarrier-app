import '../../models/order_model.dart';
import '../../models/rider_model.dart';

abstract class RiderHomeState {
  const RiderHomeState();
}

class RiderHomeInitial extends RiderHomeState {
  const RiderHomeInitial();
}

class RiderHomeLoading extends RiderHomeState {
  const RiderHomeLoading();
}

class RiderHomeLoaded extends RiderHomeState {
  const RiderHomeLoaded({
    required this.rider,
    required this.orders,
    required this.todayCompletedCount,
    required this.totalCompletedCount,
    required this.totalDistanceKm,
    required this.activeOrder,
    required this.upcomingOrders,
  });

  final RiderModel rider;
  final List<OrderModel> orders;
  final int todayCompletedCount;
  final int totalCompletedCount;
  final double totalDistanceKm;
  final OrderModel? activeOrder;
  final List<OrderModel> upcomingOrders;
}

class RiderHomeError extends RiderHomeState {
  const RiderHomeError(this.message);
  final String message;
}

class RiderHomeActionSuccess extends RiderHomeState {
  const RiderHomeActionSuccess(this.message);
  final String message;
}
