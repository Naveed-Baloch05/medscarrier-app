import '../../models/delivery_route_model.dart';
import '../../models/order_model.dart';
import '../../models/rider_live_location.dart';
import '../../models/rider_model.dart';

abstract class PharmacyTrackingEvent {
  const PharmacyTrackingEvent();
}

class InitPharmacyTracking extends PharmacyTrackingEvent {
  const InitPharmacyTracking({
    required this.pharmacyId,
    this.riderId = '',
    this.routeId,
    this.initialOrderId,
  });

  final String pharmacyId;
  final String riderId;
  final String? routeId;
  final String? initialOrderId;
}

class TrackedRouteStreamUpdated extends PharmacyTrackingEvent {
  const TrackedRouteStreamUpdated(this.route);

  final DeliveryRouteModel? route;
}

class RiderLocationStreamUpdated extends PharmacyTrackingEvent {
  const RiderLocationStreamUpdated(this.rider);

  final RiderModel? rider;
}

class TrackedOrdersStreamUpdated extends PharmacyTrackingEvent {
  const TrackedOrdersStreamUpdated(this.orders);

  final List<OrderModel> orders;
}

class RiderBatchLocationUpdated extends PharmacyTrackingEvent {
  const RiderBatchLocationUpdated(this.location);

  final RiderLiveLocation? location;
}

class SelectTrackedOrder extends PharmacyTrackingEvent {
  const SelectTrackedOrder(this.orderId);

  final String orderId;
}

class SelectTrackedStop extends PharmacyTrackingEvent {
  const SelectTrackedStop(this.stopId);

  final String stopId;
}
