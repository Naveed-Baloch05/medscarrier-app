import 'package:equatable/equatable.dart';

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
