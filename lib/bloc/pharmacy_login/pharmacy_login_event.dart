abstract class PharmacyLoginEvent {
  const PharmacyLoginEvent();
}

class PharmacyLoginSubmitted extends PharmacyLoginEvent {
  const PharmacyLoginSubmitted({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

class PharmacyLoginReset extends PharmacyLoginEvent {
  const PharmacyLoginReset();
}
