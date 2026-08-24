abstract class AdminPharmacyEvent {
  const AdminPharmacyEvent();
}

class AdminPharmacyLoadRequested extends AdminPharmacyEvent {
  const AdminPharmacyLoadRequested();
}

class AdminPharmacyApproved extends AdminPharmacyEvent {
  const AdminPharmacyApproved(this.pharmacyId);
  final String pharmacyId;
}

class AdminPharmacyRejected extends AdminPharmacyEvent {
  const AdminPharmacyRejected(this.pharmacyId);
  final String pharmacyId;
}

class AdminPharmacySuspended extends AdminPharmacyEvent {
  const AdminPharmacySuspended(this.pharmacyId);
  final String pharmacyId;
}

class AdminPharmacyActivated extends AdminPharmacyEvent {
  const AdminPharmacyActivated(this.pharmacyId);
  final String pharmacyId;
}

class AdminPharmacyDeactivated extends AdminPharmacyEvent {
  const AdminPharmacyDeactivated(this.pharmacyId);
  final String pharmacyId;
}

class AdminPharmacyUpdated extends AdminPharmacyEvent {
  const AdminPharmacyUpdated(this.pharmacyId, this.data);
  final String pharmacyId;
  final Map<String, dynamic> data;
}

class AdminPharmacyRefreshed extends AdminPharmacyEvent {
  const AdminPharmacyRefreshed();
}

class AdminPharmacyApplicationApprove extends AdminPharmacyEvent {
  const AdminPharmacyApplicationApprove(this.applicationId);
  final String applicationId;
}

class AdminPharmacyApplicationReject extends AdminPharmacyEvent {
  const AdminPharmacyApplicationReject(
    this.applicationId,
    this.rejectionReason,
  );
  final String applicationId;
  final String rejectionReason;
}
