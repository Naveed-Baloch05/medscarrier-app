abstract class AdminMonitoringEvent {
  const AdminMonitoringEvent();
}

class AdminMonitoringStartRequested extends AdminMonitoringEvent {
  const AdminMonitoringStartRequested();
}

class AdminMonitoringStopRequested extends AdminMonitoringEvent {
  const AdminMonitoringStopRequested();
}

class AdminMonitoringRiderTracked extends AdminMonitoringEvent {
  const AdminMonitoringRiderTracked(this.riderId);
  final String riderId;
}
