sealed class AdminNotificationState {
  const AdminNotificationState();
}

final class AdminNotificationInitial extends AdminNotificationState {
  const AdminNotificationInitial();
}

final class AdminNotificationLoaded extends AdminNotificationState {
  const AdminNotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  final List<dynamic> notifications;
  final int unreadCount;
}
