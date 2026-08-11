import 'package:flutter_bloc/flutter_bloc.dart';

class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  WelcomeBloc() : super(WelcomeInitial()) {
    on<SignupPressed>((event, emit) {
      emit(NavigateToSignup());
    });
    on<LoginPressed>((event, emit) {
      emit(NavigateToLogin());
    });
  }
}

abstract class WelcomeEvent {}

class SignupPressed extends WelcomeEvent {}

class LoginPressed extends WelcomeEvent {}

abstract class WelcomeState {}

class WelcomeInitial extends WelcomeState {}

class NavigateToSignup extends WelcomeState {}

class NavigateToLogin extends WelcomeState {}
