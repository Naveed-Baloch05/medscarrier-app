abstract class PharmacySignupEvent {
  const PharmacySignupEvent();
}

class PharmacySignupSubmitted extends PharmacySignupEvent {
  const PharmacySignupSubmitted({
    required this.pharmacyName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.businessAddress,
    required this.gphcNumber,
    required this.password,
  });

  final String pharmacyName;
  final String contactName;
  final String email;
  final String phone;
  final String businessAddress;
  final String gphcNumber;
  final String password;
}

class PharmacySignupReset extends PharmacySignupEvent {
  const PharmacySignupReset();
}
