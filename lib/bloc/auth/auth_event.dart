abstract class AuthEvent {
  const AuthEvent();
}

class SignUpRequested extends AuthEvent {
  const SignUpRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

class LogInRequested extends AuthEvent {
  const LogInRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

class LogOutRequested extends AuthEvent {}
