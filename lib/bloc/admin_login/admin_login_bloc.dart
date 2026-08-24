import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../models/user_model.dart';

import 'admin_login_event.dart';
import 'admin_login_state.dart';

const String _kAdminKeepSignedIn = 'admin_keep_signed_in';

class AdminLoginBloc
    extends Bloc<AdminLoginEvent, AdminLoginState> {
  AdminLoginBloc({
    AuthService? authService,
    FirestoreService? firestoreService,
  })  : _authService =
            authService ?? AuthService.instance,
        _firestoreService =
            firestoreService ?? FirestoreService.instance,
        super(const AdminLoginInitial()) {
    on<AdminLoginSubmitted>(_onAdminLoginSubmitted);

    on<AdminLoginLoadRequested>(
      _onAdminLoginLoadRequested,
    );

    on<AdminLoginCleared>(
      _onAdminLoginCleared,
    );

    on<AdminLoginPasswordResetRequested>(
      _onPasswordResetRequested,
    );
  }

  final AuthService _authService;
  final FirestoreService _firestoreService;

  // ============================================================
  // KEEP ME SIGNED IN — helpers
  // ============================================================

  Future<void> _saveKeepSignedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAdminKeepSignedIn, value);
  }

  Future<bool> isKeepSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAdminKeepSignedIn) ?? false;
  }

  // ============================================================
  // SIGN IN
  // ============================================================

  Future<void> _onAdminLoginSubmitted(
    AdminLoginSubmitted event,
    Emitter<AdminLoginState> emit,
  ) async {
    emit(const AdminLoginSubmitting());

    try {
      final User firebaseUser = await _authService.signIn(
        email: event.email,
        password: event.password,
      );

      final bool admin = await _firestoreService.isAdmin(
        firebaseUser.uid,
      );

      if (!admin) {
        await _authService.signOut();
        emit(
          const AdminLoginError(
            'Access denied. This account is not an admin.',
          ),
        );
        return;
      }

      final UserModel? adminProfile =
          await _firestoreService.getUser(
        firebaseUser.uid,
      );

      if (adminProfile == null) {
        await _authService.signOut();
        emit(
          const AdminLoginError(
            'Admin profile not found.',
          ),
        );
        return;
      }

      await _saveKeepSignedIn(event.keepSignedIn);

      emit(AdminLoginSuccess(adminProfile));
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found for this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        default:
          message = 'Login failed. Please try again.';
      }

      emit(AdminLoginError(message));
    } catch (error) {
      emit(
        AdminLoginError(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  // ============================================================
  // AUTO-LOGIN (called from splash screen)
  // ============================================================

  Future<void> _onAdminLoginLoadRequested(
    AdminLoginLoadRequested event,
    Emitter<AdminLoginState> emit,
  ) async {
    emit(const AdminLoginLoading());

    try {
      final bool keepSignedIn = await isKeepSignedIn();

      if (!keepSignedIn) {
        emit(const AdminLoginUnauthorized());
        return;
      }

      final User? firebaseUser =
          FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        emit(const AdminLoginUnauthorized());
        return;
      }

      final bool admin = await _firestoreService.isAdmin(
        firebaseUser.uid,
      );

      if (!admin) {
        emit(const AdminLoginUnauthorized());
        return;
      }

      final UserModel? adminProfile =
          await _firestoreService.getUser(
        firebaseUser.uid,
      );

      if (adminProfile == null) {
        emit(
          const AdminLoginError(
            'Admin profile was not found.',
          ),
        );
        return;
      }

      emit(AdminLoginSuccess(adminProfile));
    } catch (error) {
      emit(
        const AdminLoginError(
          'Unable to load admin profile. Please try again.',
        ),
      );
    }
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================

  Future<void> _onPasswordResetRequested(
    AdminLoginPasswordResetRequested event,
    Emitter<AdminLoginState> emit,
  ) async {
    try {
      await _authService.sendPasswordReset(
        email: event.email,
      );

      emit(const AdminLoginPasswordResetSent());
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found for this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        default:
          message = 'Could not send reset email. Please try again.';
      }

      emit(AdminLoginError(message));
    } catch (error) {
      emit(
        AdminLoginError(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  // ============================================================
  // CLEAR ADMIN (logout)
  // ============================================================

  Future<void> _onAdminLoginCleared(
    AdminLoginCleared event,
    Emitter<AdminLoginState> emit,
  ) async {
    await _saveKeepSignedIn(false);
    await _authService.signOut();
    emit(const AdminLoginClearedState());
  }
}
