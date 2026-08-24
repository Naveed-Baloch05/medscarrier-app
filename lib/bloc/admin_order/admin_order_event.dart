abstract class AdminOrderEvent {
  const AdminOrderEvent();
}

class AdminOrderLoadRequested extends AdminOrderEvent {
  const AdminOrderLoadRequested();
}

class AdminOrderAssigned extends AdminOrderEvent {
  const AdminOrderAssigned(this.orderId, this.riderId);
  final String orderId;
  final String riderId;
}

class AdminOrderAutoAssigned extends AdminOrderEvent {
  const AdminOrderAutoAssigned(this.orderId);
  final String orderId;
}

class AdminOrderStatusUpdated extends AdminOrderEvent {
  const AdminOrderStatusUpdated(this.orderId, this.status);
  final String orderId;
  final String status;
}

class AdminOrderCancelled extends AdminOrderEvent {
  const AdminOrderCancelled(this.orderId);
  final String orderId;
}

class AdminOrderFiltered extends AdminOrderEvent {
  const AdminOrderFiltered(this.status);
  final String status;
}

class AdminOrderRefreshed extends AdminOrderEvent {
  const AdminOrderRefreshed();
}
