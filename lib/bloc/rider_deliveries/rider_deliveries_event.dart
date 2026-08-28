import 'package:equatable/equatable.dart';

abstract class RiderDeliveriesEvent extends Equatable {
  const RiderDeliveriesEvent();

  @override
  List<Object?> get props => [];
}

class LoadRiderDeliveries extends RiderDeliveriesEvent {
  const LoadRiderDeliveries(this.riderId);

  final String riderId;

  @override
  List<Object?> get props => [riderId];
}

class RefreshRiderDeliveries extends RiderDeliveriesEvent {
  const RefreshRiderDeliveries(this.riderId);

  final String riderId;

  @override
  List<Object?> get props => [riderId];
}
