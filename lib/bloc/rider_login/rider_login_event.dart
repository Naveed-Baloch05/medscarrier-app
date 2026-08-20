abstract class RiderLoginEvent {
  const RiderLoginEvent();
}

class RiderLoginSubmitted extends RiderLoginEvent {
  const RiderLoginSubmitted({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}
