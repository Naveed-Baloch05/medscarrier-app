abstract class AdminMonitoringState {
  const AdminMonitoringState();
}

class AdminMonitoringInitial extends AdminMonitoringState {
  const AdminMonitoringInitial();
}

class AdminMonitoringLoading extends AdminMonitoringState {
  const AdminMonitoringLoading();
}

class AdminMonitoringActive extends AdminMonitoringState {
  const AdminMonitoringActive(this.riders);
  final List<Map<String, dynamic>> riders;
}

class AdminMonitoringRiderFocused extends AdminMonitoringState {
  const AdminMonitoringRiderFocused(this.rider);
  final Map<String, dynamic> rider;
}

class AdminMonitoringError extends AdminMonitoringState {
  const AdminMonitoringError(this.message);
  final String message;
}
