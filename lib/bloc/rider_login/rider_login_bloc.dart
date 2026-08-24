import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/rider_login_service.dart';
import 'rider_login_event.dart';
import 'rider_login_state.dart';

class RiderLoginBloc extends Bloc<RiderLoginEvent, RiderLoginState> {
  RiderLoginBloc({RiderLoginService? service})
      : _service = service ?? RiderLoginService.instance,
        super(const RiderLoginInitial()) {
    on<RiderLoginSubmitted>(_onSubmitted);
  }

  final RiderLoginService _service;

  Future<void> _onSubmitted(
    RiderLoginSubmitted event,
    Emitter<RiderLoginState> emit,
  ) async {
    emit(const RiderLoginLoading());

    try {
      final rider = await _service.login(
        email: event.email,
        password: event.password,
      );

      emit(RiderLoginSuccess(rider));
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
              'This account has been disabled. Please wait for admin approval or contact support.';
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

      emit(RiderLoginFailure(message));
    } catch (error) {
      emit(RiderLoginFailure(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
