abstract class AdminDashboardEvent {
  const AdminDashboardEvent();
}

class AdminDashboardLoadRequested extends AdminDashboardEvent {
  const AdminDashboardLoadRequested();
}

class AdminDashboardRefreshed extends AdminDashboardEvent {
  const AdminDashboardRefreshed();
}

class AdminDashboardApprovePharmacy extends AdminDashboardEvent {
  const AdminDashboardApprovePharmacy(this.pharmacyId);
  final String pharmacyId;
}

class AdminDashboardRejectPharmacy extends AdminDashboardEvent {
  const AdminDashboardRejectPharmacy(this.pharmacyId);
  final String pharmacyId;
}

class AdminDashboardAssignOrder extends AdminDashboardEvent {
  const AdminDashboardAssignOrder(this.orderId, this.riderId);
  final String orderId;
  final String riderId;
}

class AdminDashboardAutoAssignOrder extends AdminDashboardEvent {
  const AdminDashboardAutoAssignOrder(this.orderId);
  final String orderId;
}

class AdminDashboardPendingPharmaciesUpdated extends AdminDashboardEvent {
  const AdminDashboardPendingPharmaciesUpdated(this.pendingPharmacies);
  final List<dynamic> pendingPharmacies;
}

class AdminDashboardApproveRider extends AdminDashboardEvent {
  const AdminDashboardApproveRider(this.applicationId);
  final String applicationId;
}

class AdminDashboardRejectRider extends AdminDashboardEvent {
  const AdminDashboardRejectRider(this.applicationId, {this.reason = ''});
  final String applicationId;
  final String reason;
}

class AdminDashboardPendingRidersUpdated extends AdminDashboardEvent {
  const AdminDashboardPendingRidersUpdated(this.pendingRiders);
  final List<dynamic> pendingRiders;
}
