import '../../models/pharmacy_notification_model.dart';

abstract class PharmacyNotificationsState {
  const PharmacyNotificationsState();
}

class PharmacyNotificationsInitial extends PharmacyNotificationsState {
  const PharmacyNotificationsInitial();
}

class PharmacyNotificationsLoading extends PharmacyNotificationsState {
  const PharmacyNotificationsLoading();
}

class PharmacyNotificationsLoaded extends PharmacyNotificationsState {
  const PharmacyNotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  final List<PharmacyNotificationModel> notifications;
  final int unreadCount;
}

class PharmacyNotificationsError extends PharmacyNotificationsState {
  const PharmacyNotificationsError(this.message);

  final String message;
}
