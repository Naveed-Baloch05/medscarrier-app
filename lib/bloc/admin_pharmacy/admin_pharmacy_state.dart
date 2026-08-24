import '../../models/pharmacy_application_model.dart';

abstract class AdminPharmacyState {
  const AdminPharmacyState();
}

class AdminPharmacyInitial extends AdminPharmacyState {
  const AdminPharmacyInitial();
}

class AdminPharmacyLoading extends AdminPharmacyState {
  const AdminPharmacyLoading();
}

class AdminPharmacyLoaded extends AdminPharmacyState {
  const AdminPharmacyLoaded(this.pharmacies);
  final List<Map<String, dynamic>> pharmacies;
}

class AdminPharmacyLoadedWithApplications extends AdminPharmacyState {
  const AdminPharmacyLoadedWithApplications(
    this.pharmacies,
    this.pendingApplications,
  );
  final List<Map<String, dynamic>> pharmacies;
  final List<PharmacyApplicationModel> pendingApplications;
}

class AdminPharmacyOperationSuccess extends AdminPharmacyState {
  const AdminPharmacyOperationSuccess(this.message);
  final String message;
}

class AdminPharmacyError extends AdminPharmacyState {
  const AdminPharmacyError(this.message);
  final String message;
}
