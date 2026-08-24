import '../../models/pharmacy_model.dart';
import '../../models/order_model.dart';

abstract class AdminDashboardState {
  const AdminDashboardState();
}

class AdminDashboardInitial extends AdminDashboardState {
  const AdminDashboardInitial();
}

class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

class AdminDashboardLoaded extends AdminDashboardState {
  const AdminDashboardLoaded({
    required this.totalOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.avgDeliveryTime,
    required this.totalRiders,
    required this.onlineRiders,
    required this.activeRiders,
    required this.totalPharmacies,
    required this.pendingPharmacies,
    required this.activePharmacies,
    required this.pendingPharmacyList,
    required this.readyOrderList,
    required this.activeOrderList,
  });

  final int totalOrders;
  final int activeOrders;
  final int completedOrders;
  final int avgDeliveryTime;
  final int totalRiders;
  final int onlineRiders;
  final int activeRiders;
  final int totalPharmacies;
  final int pendingPharmacies;
  final int activePharmacies;
  final List<PharmacyModel> pendingPharmacyList;
  final List<OrderModel> readyOrderList;
  final List<OrderModel> activeOrderList;
}

class AdminDashboardError extends AdminDashboardState {
  const AdminDashboardError(this.message);
  final String message;
}

class AdminDashboardActionSuccess extends AdminDashboardState {
  const AdminDashboardActionSuccess(this.message);
  final String message;
}
