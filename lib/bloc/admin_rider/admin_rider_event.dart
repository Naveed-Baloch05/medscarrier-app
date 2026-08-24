abstract class AdminRiderEvent {
  const AdminRiderEvent();
}

class AdminRiderLoadRequested extends AdminRiderEvent {
  const AdminRiderLoadRequested();
}

class AdminRiderAdded extends AdminRiderEvent {
  const AdminRiderAdded(this.riderData);
  final Map<String, dynamic> riderData;
}

class AdminRiderUpdated extends AdminRiderEvent {
  const AdminRiderUpdated(this.riderId, this.data);
  final String riderId;
  final Map<String, dynamic> data;
}

class AdminRiderActivated extends AdminRiderEvent {
  const AdminRiderActivated(this.riderId);
  final String riderId;
}

class AdminRiderDeactivated extends AdminRiderEvent {
  const AdminRiderDeactivated(this.riderId);
  final String riderId;
}

class AdminRiderOrderAssigned extends AdminRiderEvent {
  const AdminRiderOrderAssigned(this.riderId, this.orderId);
  final String riderId;
  final String orderId;
}

class AdminRiderRefreshed extends AdminRiderEvent {
  const AdminRiderRefreshed();
}

class AdminRiderApplicationApprove extends AdminRiderEvent {
  const AdminRiderApplicationApprove(this.applicationId);
  final String applicationId;
}

class AdminRiderApplicationReject extends AdminRiderEvent {
  const AdminRiderApplicationReject(
    this.applicationId,
    this.rejectionReason,
  );
  final String applicationId;
  final String rejectionReason;
}
