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
    this.licenseFront,
    this.licenseBack,
  });

  final String fullName;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehicleReg;
  final String password;
  final File? licenseFront;
  final File? licenseBack;
}

class RiderSignupReset extends RiderSignupEvent {
  const RiderSignupReset();
}
