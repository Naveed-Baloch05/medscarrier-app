import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/pharmacy_login_service.dart';
import 'pharmacy_login_event.dart';
import 'pharmacy_login_state.dart';

class PharmacyLoginBloc extends Bloc<PharmacyLoginEvent, PharmacyLoginState> {
  PharmacyLoginBloc({PharmacyLoginService? service})
      : _service = service ?? PharmacyLoginService.instance,
        super(const PharmacyLoginInitial()) {
    on<PharmacyLoginSubmitted>(_onSubmitted);
    on<PharmacyLoginReset>((_, emit) => emit(const PharmacyLoginInitial()));
  }

  final PharmacyLoginService _service;

  Future<void> _onSubmitted(
    PharmacyLoginSubmitted event,
    Emitter<PharmacyLoginState> emit,
  ) async {
    emit(const PharmacyLoginLoading());

    try {
      final pharmacy = await _service.login(
        email: event.email,
        password: event.password,
      );

      emit(PharmacyLoginSuccess(pharmacy));
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
          message =
              'This account has been disabled. Please contact support.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = 'Login failed. Please try again.';
      }

      emit(PharmacyLoginFailure(message));
    } catch (error) {
      emit(PharmacyLoginFailure(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
