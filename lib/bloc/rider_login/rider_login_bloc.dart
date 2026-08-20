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
    } catch (error) {
      emit(RiderLoginFailure(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
