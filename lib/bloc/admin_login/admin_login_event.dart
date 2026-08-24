abstract class AdminLoginEvent {
  const AdminLoginEvent();
}

// ============================================================
// Sign In
// ============================================================

class AdminLoginSubmitted extends AdminLoginEvent {
  const AdminLoginSubmitted({
    required this.email,
    required this.password,
    this.keepSignedIn = true,
  });

  final String email;
  final String password;
  final bool keepSignedIn;
}

// ============================================================
// Auto-Login (splash screen keep-me-signed-in check)
// ============================================================

class AdminLoginLoadRequested extends AdminLoginEvent {
  const AdminLoginLoadRequested();
}

// ============================================================
// Clear Admin (logout)
// ============================================================

class AdminLoginCleared extends AdminLoginEvent {
  const AdminLoginCleared();
}

// ============================================================
// Password Reset
// ============================================================

class AdminLoginPasswordResetRequested extends AdminLoginEvent {
  const AdminLoginPasswordResetRequested({required this.email});

  final String email;
}
