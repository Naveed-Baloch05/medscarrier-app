import 'package:flutter_bloc/flutter_bloc.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(AppInitial()) {
    on<AppEvent>((event, emit) {
      // TODO: Implement event handlers
    });
  }
}

abstract class AppEvent {}
abstract class AppState {}

class AppInitial extends AppState {}
