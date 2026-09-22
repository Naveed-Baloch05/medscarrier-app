import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/delivery_route_model.dart';
import '../../models/order_model.dart';
import '../../models/rider_live_location.dart';
import '../../models/rider_model.dart';

abstract class PharmacyTrackingState {
  const PharmacyTrackingState();
}

class PharmacyTrackingInitial extends PharmacyTrackingState {
  const PharmacyTrackingInitial();
}

class PharmacyTrackingLoading extends PharmacyTrackingState {
  const PharmacyTrackingLoading();
}

class PharmacyTrackingLoaded extends PharmacyTrackingState {
  const PharmacyTrackingLoaded({
    required this.pharmacyId,
    required this.riderId,
    this.route,
    this.rider,
    this.orders = const [],
    this.liveLocation,
    this.selectedOrder,
    this.activeStop,
    this.selectedStop,
    this.pharmacyLocation,
    this.markers = const {},
    this.polylines = const {},
  });

  final String pharmacyId;
  final String riderId;
  final DeliveryRouteModel? route;
  final RiderModel? rider;
  final List<OrderModel> orders;
  final RiderLiveLocation? liveLocation;
  final OrderModel? selectedOrder;
  final RouteStopModel? activeStop;
  final RouteStopModel? selectedStop;
  final LatLng? pharmacyLocation;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  List<RouteStopModel> get stops => route?.stops ?? const [];

  int get totalCount => stops.isNotEmpty ? stops.length : orders.length;
  int get deliveredCount => stops.isNotEmpty
      ? stops.where((s) => s.isDelivered).length
      : orders.where((o) => o.status.toLowerCase() == 'delivered' || o.status.toLowerCase() == 'completed').length;
  int get failedCount => stops.isNotEmpty
      ? stops.where((s) => s.isFailed).length
      : orders.where((o) => o.status.toLowerCase() == 'failed').length;
  int get inTransitCount => stops.isNotEmpty
      ? stops.where((s) => s.isPending).length
      : orders.where((o) =>
          o.status.toLowerCase() == 'on the way' ||
          o.status.toLowerCase() == 'picked up' ||
          o.status.toLowerCase() == 'arrived').length;

  String get routeStatusDisplay {
    if (isRouteCompleted) return 'Completed';
    if (liveLocation?.isActivelyDelivering == true || route?.isActive == true) return 'Delivering';
    if (route?.status == 'optimized') return 'On Route';
    return 'On Route';
  }

  bool get isRouteCompleted =>
      route?.status == 'completed' || (stops.isNotEmpty && stops.every((s) => !s.isPending));

  String get riderNameDisplay {
    if (rider?.fullName.isNotEmpty == true) return rider!.fullName;
    if (liveLocation?.currentCustomerName.isNotEmpty == true) return 'Assigned Rider';
    return 'Assigned Rider';
  }

  PharmacyTrackingLoaded copyWith({
    String? pharmacyId,
    String? riderId,
    DeliveryRouteModel? route,
    RiderModel? rider,
    List<OrderModel>? orders,
    RiderLiveLocation? liveLocation,
    OrderModel? selectedOrder,
    RouteStopModel? activeStop,
    RouteStopModel? selectedStop,
    LatLng? pharmacyLocation,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
  }) {
    return PharmacyTrackingLoaded(
      pharmacyId: pharmacyId ?? this.pharmacyId,
      riderId: riderId ?? this.riderId,
      route: route ?? this.route,
      rider: rider ?? this.rider,
      orders: orders ?? this.orders,
      liveLocation: liveLocation ?? this.liveLocation,
      selectedOrder: selectedOrder ?? this.selectedOrder,
      activeStop: activeStop ?? this.activeStop,
      selectedStop: selectedStop ?? this.selectedStop,
      pharmacyLocation: pharmacyLocation ?? this.pharmacyLocation,
      markers: markers ?? this.markers,
      polylines: polylines ?? this.polylines,
    );
  }
}

class PharmacyTrackingError extends PharmacyTrackingState {
  const PharmacyTrackingError(this.message);

  final String message;
}
