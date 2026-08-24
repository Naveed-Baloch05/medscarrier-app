import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  // =========================
  // Sign Up
  // =========================
  Future<User> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return credential.user!;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // =========================
  // Sign In
  // =========================
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return credential.user!;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // =========================
  // Sign Out
  // =========================
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // =========================
  // Send Password Reset Email
  // =========================
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // =========================
  // Current User
  // =========================
  User? get currentUser => _auth.currentUser;
}