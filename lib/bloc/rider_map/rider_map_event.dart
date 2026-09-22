import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/delivery_route_model.dart';

abstract class RiderMapEvent extends Equatable {
  const RiderMapEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize map navigation directly for a batch route stop.
class InitializeStopNavigation extends RiderMapEvent {
  const InitializeStopNavigation(this.stop, {this.riderPosition, this.riderId});

  final RouteStopModel stop;
  final LatLng? riderPosition;
  final String? riderId;

  @override
  List<Object?> get props => [stop.id, riderPosition, riderId];
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

/// Event to advance to the next batch stop without leaving the navigation screen
class AdvanceToNextBatchStop extends RiderMapEvent {
  const AdvanceToNextBatchStop(this.nextStop, {this.riderId});

  final RouteStopModel nextStop;
  final String? riderId;

  @override
  List<Object?> get props => [nextStop.id, riderId];
}
