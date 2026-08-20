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
  });

  final String fullName;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehicleReg;
  final String password;
}

class RiderSignupReset extends RiderSignupEvent {
  const RiderSignupReset();
}
