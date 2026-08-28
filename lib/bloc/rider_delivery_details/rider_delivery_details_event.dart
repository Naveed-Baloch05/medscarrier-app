import 'package:equatable/equatable.dart';

abstract class RiderDeliveryDetailsEvent extends Equatable {
  const RiderDeliveryDetailsEvent();

  @override
  List<Object?> get props => [];
}

class SubscribeToOrder extends RiderDeliveryDetailsEvent {
  const SubscribeToOrder(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class LoadOrder extends RiderDeliveryDetailsEvent {
  const LoadOrder(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class VerifyPickupQR extends RiderDeliveryDetailsEvent {
  const VerifyPickupQR({
    required this.orderId,
    required this.qrValue,
  });

  final String orderId;
  final String qrValue;

  @override
  List<Object?> get props => [orderId, qrValue];
}

class StartDelivery extends RiderDeliveryDetailsEvent {
  const StartDelivery(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class CompleteDelivery extends RiderDeliveryDetailsEvent {
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
