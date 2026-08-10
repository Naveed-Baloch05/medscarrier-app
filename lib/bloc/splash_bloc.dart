import 'package:flutter_bloc/flutter_bloc.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashInitial());
}

abstract class SplashEvent {}

abstract class SplashState {}

class SplashInitial extends SplashState {}
