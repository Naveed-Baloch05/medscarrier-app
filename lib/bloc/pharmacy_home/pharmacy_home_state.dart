import '../../models/pharmacy_model.dart';

abstract class PharmacyHomeState {
  const PharmacyHomeState();
}

class PharmacyHomeInitial extends PharmacyHomeState {
  const PharmacyHomeInitial();
}

class PharmacyHomeLoading extends PharmacyHomeState {
  const PharmacyHomeLoading();
}

class PharmacyHomeLoaded extends PharmacyHomeState {
  const PharmacyHomeLoaded({
    required this.pharmacy,
    required this.totalOrders,
    required this.completedOrders,
    required this.activeOrders,
    required this.newOrders,
    required this.preparingOrders,
    required this.readyOrders,
    required this.deliveredOrders,
  });

  final PharmacyModel pharmacy;

  final int totalOrders;
  final int completedOrders;
  final int activeOrders;

  final int newOrders;
  final int preparingOrders;
  final int readyOrders;
  final int deliveredOrders;
}

class PharmacyHomeError extends PharmacyHomeState {
  const PharmacyHomeError(this.message);

  final String message;
}