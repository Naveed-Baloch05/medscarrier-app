import '../../models/pharmacy_model.dart';
import '../../models/order_model.dart';
import '../../models/rider_application_model.dart';

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
    this.pendingRiders = 0,
    required this.pendingPharmacyList,
    this.pendingRiderList = const [],
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
  final int pendingRiders;
  final List<PharmacyModel> pendingPharmacyList;
  final List<RiderApplicationModel> pendingRiderList;
  final List<OrderModel> readyOrderList;
  final List<OrderModel> activeOrderList;

  AdminDashboardLoaded copyWith({
    int? totalOrders,
    int? activeOrders,
    int? completedOrders,
    int? avgDeliveryTime,
    int? totalRiders,
    int? onlineRiders,
    int? activeRiders,
    int? totalPharmacies,
    int? pendingPharmacies,
    int? activePharmacies,
    int? pendingRiders,
    List<PharmacyModel>? pendingPharmacyList,
    List<RiderApplicationModel>? pendingRiderList,
    List<OrderModel>? readyOrderList,
    List<OrderModel>? activeOrderList,
  }) {
    return AdminDashboardLoaded(
      totalOrders: totalOrders ?? this.totalOrders,
      activeOrders: activeOrders ?? this.activeOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      avgDeliveryTime: avgDeliveryTime ?? this.avgDeliveryTime,
      totalRiders: totalRiders ?? this.totalRiders,
      onlineRiders: onlineRiders ?? this.onlineRiders,
      activeRiders: activeRiders ?? this.activeRiders,
      totalPharmacies: totalPharmacies ?? this.totalPharmacies,
      pendingPharmacies: pendingPharmacies ?? this.pendingPharmacies,
      activePharmacies: activePharmacies ?? this.activePharmacies,
      pendingRiders: pendingRiders ?? this.pendingRiders,
      pendingPharmacyList: pendingPharmacyList ?? this.pendingPharmacyList,
      pendingRiderList: pendingRiderList ?? this.pendingRiderList,
      readyOrderList: readyOrderList ?? this.readyOrderList,
      activeOrderList: activeOrderList ?? this.activeOrderList,
    );
  }
}

class AdminDashboardError extends AdminDashboardState {
  const AdminDashboardError(this.message);
  final String message;
}

class AdminDashboardActionSuccess extends AdminDashboardState {
  const AdminDashboardActionSuccess(this.message);
  final String message;
}
