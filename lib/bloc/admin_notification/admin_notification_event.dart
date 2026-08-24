sealed class AdminNotificationEvent {
  const AdminNotificationEvent();
}

final class AdminNotificationLoadRequested
    extends AdminNotificationEvent {
  const AdminNotificationLoadRequested();
}

final class AdminNotificationMarkRead extends AdminNotificationEvent {
  const AdminNotificationMarkRead(this.notificationId);
  final String notificationId;
}

final class AdminNotificationMarkAllRead extends AdminNotificationEvent {
  const AdminNotificationMarkAllRead();
}
