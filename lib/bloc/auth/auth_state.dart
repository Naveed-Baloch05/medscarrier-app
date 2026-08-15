import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState {
  const AuthState();
}

// =========================
// Initial
// =========================

class AuthInitial extends AuthState {
  const AuthInitial();
}

// =========================
// Loading
// =========================

class AuthLoading extends AuthState {
  const AuthLoading();
}

// =========================
// Authenticated
// =========================

class Authenticated extends AuthState {
  const Authenticated(this.user);

  final User user;
}

// =========================
// Unauthenticated
// =========================

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

// =========================
// Authentication Error
// =========================

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}