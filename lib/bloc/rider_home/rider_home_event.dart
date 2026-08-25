abstract class RiderHomeEvent {
  const RiderHomeEvent();
}

class LoadRiderHome extends RiderHomeEvent {
  const LoadRiderHome(this.riderId);
  final String riderId;
}

class RiderHomeRefreshed extends RiderHomeEvent {
  const RiderHomeRefreshed(this.riderId);
  final String riderId;
}

class RiderHomeToggleOnline extends RiderHomeEvent {
  const RiderHomeToggleOnline(this.riderId, this.isOnline);
  final String riderId;
  final bool isOnline;
}

class RiderHomeOrderStatusChanged extends RiderHomeEvent {
  const RiderHomeOrderStatusChanged(this.orderId, this.newStatus);
  final String orderId;
  final String newStatus;
}

class RiderHomeConfirmDelivery extends RiderHomeEvent {
  const RiderHomeConfirmDelivery({
    required this.orderId,
    required this.cdConfirmed,
    required this.coldChainConfirmed,
  });
  final String orderId;
  final bool cdConfirmed;
  final bool coldChainConfirmed;
}
