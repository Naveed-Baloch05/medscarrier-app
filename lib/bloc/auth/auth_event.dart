abstract class AuthEvent {
  const AuthEvent();
}

// =========================
// Sign Up
// =========================

class SignUpRequested extends AuthEvent {
  const SignUpRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

// =========================
// Log In
// =========================

class LogInRequested extends AuthEvent {
  const LogInRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

// =========================
// Log Out
// =========================

class LogOutRequested extends AuthEvent {
  const LogOutRequested();
}

// =========================
// Check Authentication
// =========================

class CheckAuthRequested extends AuthEvent {
  const CheckAuthRequested();
}