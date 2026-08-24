import 'dart:io';

abstract class RiderSignupEvent {
  const RiderSignupEvent();
}

class RiderSignupSubmitted extends RiderSignupEvent {
  const RiderSignupSubmitted({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehicleReg,
    required this.password,
    this.profilePhoto,
    this.drivingLicenceFront,
    this.drivingLicenceBack,
  });

  final String fullName;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehicleReg;
  final String password;
  final File? profilePhoto;
  final File? drivingLicenceFront;
  final File? drivingLicenceBack;
}

class RiderSignupReset extends RiderSignupEvent {
  const RiderSignupReset();
}
