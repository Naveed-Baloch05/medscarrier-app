import '../../models/user_model.dart';

abstract class AdminLoginState {
  const AdminLoginState();
}

// ============================================================
// Initial
// ============================================================

class AdminLoginInitial extends AdminLoginState {
  const AdminLoginInitial();
}

// ============================================================
// Submitting (signing in)
// ============================================================

class AdminLoginSubmitting extends AdminLoginState {
  const AdminLoginSubmitting();
}

// ============================================================
// Success (authentication successful, carries UserModel
// for splash/login screen navigation)
// ============================================================

class AdminLoginSuccess extends AdminLoginState {
  const AdminLoginSuccess(this.admin);

  final UserModel admin;
}

// ============================================================
// Loading (auto-login check in progress)
// ============================================================

class AdminLoginLoading extends AdminLoginState {
  const AdminLoginLoading();
}

// ============================================================
// Error
// ============================================================

class AdminLoginError extends AdminLoginState {
  const AdminLoginError(this.message);

  final String message;
}

// ============================================================
// Unauthorized
// ============================================================

class AdminLoginUnauthorized extends AdminLoginState {
  const AdminLoginUnauthorized();
}

// ============================================================
// Cleared
// ============================================================

class AdminLoginClearedState extends AdminLoginState {
  const AdminLoginClearedState();
}

// ============================================================
// Password Reset Email Sent
// ============================================================

class AdminLoginPasswordResetSent extends AdminLoginState {
  const AdminLoginPasswordResetSent();
}
