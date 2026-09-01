import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

abstract class RiderMapEvent extends Equatable {
  const RiderMapEvent();

  @override
  List<Object?> get props => [];
}

class SubscribeToMap extends RiderMapEvent {
  const SubscribeToMap(this.riderId);

  final String riderId;

  @override
  List<Object?> get props => [riderId];
}

class SubscribeToOrder extends RiderMapEvent {
  const SubscribeToOrder(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class LoadMapOrder extends RiderMapEvent {
  const LoadMapOrder(this.riderId);

  final String riderId;

  @override
  List<Object?> get props => [riderId];
}

class RiderLocationUpdated extends RiderMapEvent {
  const RiderLocationUpdated(this.position);

  final Position position;

  @override
  List<Object?> get props => [
        position.latitude,
        position.longitude,
        position.heading,
        position.speed,
      ];
}

class SelectRoute extends RiderMapEvent {
  const SelectRoute(this.routeIndex);

  final int routeIndex;

  @override
  List<Object?> get props => [routeIndex];
}

class RecalculateRoute extends RiderMapEvent {
  const RecalculateRoute({this.force = false});

  final bool force;

  @override
  List<Object?> get props => [force];
}

class MarkArrived extends RiderMapEvent {
  const MarkArrived(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class CompleteDelivery extends RiderMapEvent {
  const CompleteDelivery({
    required this.orderId,
    this.recipientName,
    this.signaturePoints,
    this.medicineHandoverConfirmed = false,
  });

  final String orderId;
  final String? recipientName;
  final List<Map<String, double>>? signaturePoints;
  final bool medicineHandoverConfirmed;

  @override
  List<Object?> get props => [
        orderId,
        recipientName,
        signaturePoints,
        medicineHandoverConfirmed,
      ];
}
