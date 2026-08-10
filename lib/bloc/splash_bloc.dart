import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashInitial()) {
    on<AppStarted>((event, emit) async {
      await Future<void>.delayed(const Duration(seconds: 3));
      emit(SplashNavigated());
    });
  }
}

abstract class SplashEvent {}

class AppStarted extends SplashEvent {}

abstract class SplashState {}

class SplashInitial extends SplashState {}

class SplashNavigated extends SplashState {}
