abstract class PharmacyNotificationsEvent {
  const PharmacyNotificationsEvent();
}

class LoadPharmacyNotifications extends PharmacyNotificationsEvent {
  const LoadPharmacyNotifications(this.uid);

  final String uid;
}

class PharmacyNotificationMarkedRead extends PharmacyNotificationsEvent {
  const PharmacyNotificationMarkedRead(this.notificationId);

  final String notificationId;
}

class PharmacyNotificationsMarkAllRead extends PharmacyNotificationsEvent {
  const PharmacyNotificationsMarkAllRead();
}
