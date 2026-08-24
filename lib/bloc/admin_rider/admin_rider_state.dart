import '../../models/rider_application_model.dart';

abstract class AdminRiderState {
  const AdminRiderState();
}

class AdminRiderInitial extends AdminRiderState {
  const AdminRiderInitial();
}

class AdminRiderLoading extends AdminRiderState {
  const AdminRiderLoading();
}

class AdminRiderLoaded extends AdminRiderState {
  const AdminRiderLoaded(this.riders);
  final List<Map<String, dynamic>> riders;
}

class AdminRiderLoadedWithApplications extends AdminRiderState {
  const AdminRiderLoadedWithApplications(
    this.riders,
    this.pendingApplications,
  );
  final List<Map<String, dynamic>> riders;
  final List<RiderApplicationModel> pendingApplications;
}

class AdminRiderOperationSuccess extends AdminRiderState {
  const AdminRiderOperationSuccess(this.message);
  final String message;
}

class AdminRiderError extends AdminRiderState {
  const AdminRiderError(this.message);
  final String message;
}
