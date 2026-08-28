import 'package:equatable/equatable.dart';

import '../../models/order_model.dart';

abstract class RiderDeliveryDetailsState extends Equatable {
  const RiderDeliveryDetailsState();

  @override
  List<Object?> get props => [];
}

class RiderDeliveryDetailsInitial extends RiderDeliveryDetailsState {
  const RiderDeliveryDetailsInitial();
}

class RiderDeliveryDetailsLoading extends RiderDeliveryDetailsState {
  const RiderDeliveryDetailsLoading();
}

class RiderDeliveryDetailsLoaded extends RiderDeliveryDetailsState {
  const RiderDeliveryDetailsLoaded({
    required this.order,
    this.pickupQrValue,
  });

  final OrderModel order;
  final String? pickupQrValue;

  String get normalizedStatus {
    switch (order.status) {
      case 'Ready':
        return 'Assigned';
      case 'Delivered':
        return 'Completed';
      default:
        return order.status;
    }
  }

  bool get isCompleted =>
      order.isCompleted || order.status == 'Completed' ||
      order.status == 'Delivered';

  bool get qrAlreadyScanned =>
      pickupQrValue != null && pickupQrValue!.trim().isNotEmpty;

  @override
  List<Object?> get props => [order, pickupQrValue];
}

class RiderDeliveryDetailsUpdating extends RiderDeliveryDetailsState {
  const RiderDeliveryDetailsUpdating({
    required this.order,
    this.pickupQrValue,
  });

  final OrderModel order;
  final String? pickupQrValue;

  bool get qrAlreadyScanned =>
      pickupQrValue != null && pickupQrValue!.trim().isNotEmpty;

  @override
  List<Object?> get props => [order, pickupQrValue];
}

class RiderDeliveryDetailsOperationSuccess extends RiderDeliveryDetailsState {
  const RiderDeliveryDetailsOperationSuccess({
    required this.message,
    required this.order,
    this.pickupQrValue,
  });

  final String message;
  final OrderModel order;
  final String? pickupQrValue;

  bool get qrAlreadyScanned =>
      pickupQrValue != null && pickupQrValue!.trim().isNotEmpty;

  @override
  List<Object?> get props => [message, order, pickupQrValue];
}

class RiderDeliveryDetailsError extends RiderDeliveryDetailsState {
  const RiderDeliveryDetailsError({
    required this.message,
    this.order,
    this.pickupQrValue,
  });

  final String message;
  final OrderModel? order;
  final String? pickupQrValue;

  @override
  List<Object?> get props => [message, order, pickupQrValue];
}
