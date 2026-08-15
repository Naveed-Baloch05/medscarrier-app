import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    AuthService? authService,
    FirestoreService? firestoreService,
  })  : _authService = authService ?? AuthService.instance,
        _firestoreService =
            firestoreService ?? FirestoreService.instance,
        super(const AuthInitial()) {
    on<SignUpRequested>(_onSignUpRequested);
    on<LogInRequested>(_onLogInRequested);
    on<LogOutRequested>(_onLogOutRequested);
    on<CheckAuthRequested>(_onCheckAuthRequested);
  }

  final AuthService _authService;
  final FirestoreService _firestoreService;

  // =========================
  // SIGN UP
  // =========================

  Future<void> _onSignUpRequested(
      SignUpRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    try {
      // Step 1: Create account in Firebase Authentication
      final User user = await _authService.signUp(
        email: event.email,
        password: event.password,
      );

      // Step 2: Create user profile in Firestore
      final UserModel userModel = UserModel(
        id: user.uid,
        email: user.email ?? event.email,
      );

      await _firestoreService.createUser(
        user: userModel,
      );

      // Step 3: Signup completed
      emit(Authenticated(user));
    } on FirebaseAuthException catch (error) {
      emit(AuthError(_errorMessage(error)));
    } catch (error) {
      emit(
        const AuthError(
          'Something went wrong. Please try again.',
        ),
      );
    }
  }

  // =========================
  // LOG IN
  // =========================

  Future<void> _onLogInRequested(
      LogInRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    try {
      final User user = await _authService.signIn(
        email: event.email,
        password: event.password,
      );

      emit(Authenticated(user));
    } on FirebaseAuthException catch (error) {
      emit(AuthError(_errorMessage(error)));
    } catch (error) {
      emit(
        const AuthError(
          'Something went wrong. Please try again.',
        ),
      );
    }
  }

  // =========================
  // LOG OUT
  // =========================

  Future<void> _onLogOutRequested(
      LogOutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    try {
      await _authService.signOut();

      emit(const Unauthenticated());
    } catch (error) {
      emit(
        const AuthError(
          'Unable to log out. Please try again.',
        ),
      );
    }
  }

  // =========================
  // CHECK CURRENT USER
  // =========================

  Future<void> _onCheckAuthRequested(
      CheckAuthRequested event,
      Emitter<AuthState> emit,
      ) async {
    final User? user = _authService.currentUser;

    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(const Unauthenticated());
    }
  }

  // =========================
  // FIREBASE ERROR MESSAGES
  // =========================

  String _errorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';

      case 'invalid-email':
        return 'The email address is not valid.';

      case 'wrong-password':
        return 'Incorrect password.';

      case 'user-not-found':
        return 'No account found for this email.';

      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      case 'operation-not-allowed':
        return 'Email and password authentication is not enabled.';

      default:
        return error.message ??
            'Something went wrong. Please try again.';
    }
  }
}