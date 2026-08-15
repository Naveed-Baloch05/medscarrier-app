import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<SignUpRequested>((event, emit) {
      emit(const AuthError('Not implemented yet'));
    });
    on<LogInRequested>((event, emit) {
      emit(const AuthError('Not implemented yet'));
    });
    on<LogOutRequested>((event, emit) {
      emit(Unauthenticated());
    });
  }
}
