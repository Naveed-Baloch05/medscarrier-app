import 'dart:io';

abstract class RiderProfileEvent {
  const RiderProfileEvent();
}

class LoadRiderProfile extends RiderProfileEvent {
  const LoadRiderProfile(this.riderId);

  final String riderId;
}

class RiderProfileUpdated extends RiderProfileEvent {
  const RiderProfileUpdated({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.vehicleReg,
    this.notificationsEnabled,
  });

  final String fullName;
  final String phone;
  final String email;
  final String vehicleType;
  final String vehicleReg;
  final bool? notificationsEnabled;
}

class RiderAvailabilityToggled extends RiderProfileEvent {
  const RiderAvailabilityToggled(this.isOnline);

  final bool isOnline;
}

class RiderProfilePhotoChanged extends RiderProfileEvent {
  const RiderProfilePhotoChanged(this.imageFile);

  final File imageFile;
}

class RiderProfilePhotoRemoved extends RiderProfileEvent {
  const RiderProfilePhotoRemoved();
}

class RiderPasswordChanged extends RiderProfileEvent {
  const RiderPasswordChanged({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}

class RiderLoggedOut extends RiderProfileEvent {
  const RiderLoggedOut();
}
