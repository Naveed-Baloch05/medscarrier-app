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
    required this.todayDeliveries,
    required this.completedDeliveries,
    required this.pendingDeliveries,
    required this.totalEarnings,
  });

  final RiderModel rider;
  final int todayDeliveries;
  final int completedDeliveries;
  final int pendingDeliveries;
  final double totalEarnings;
}

class RiderHomeError extends RiderHomeState {
  const RiderHomeError(this.message);

  final String message;
}
