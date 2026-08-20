import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/rider_signup_service.dart';
import 'rider_signup_event.dart';
import 'rider_signup_state.dart';

class RiderSignupBloc extends Bloc<RiderSignupEvent, RiderSignupState> {
  RiderSignupBloc({RiderSignupService? service})
      : _service = service ?? RiderSignupService.instance,
        super(const RiderSignupInitial()) {
    on<RiderSignupSubmitted>(_onSubmitted);
    on<RiderSignupReset>((_, emit) => emit(const RiderSignupInitial()));
  }

  final RiderSignupService _service;

  Future<void> _onSubmitted(
    RiderSignupSubmitted event,
    Emitter<RiderSignupState> emit,
  ) async {
    emit(const RiderSignupLoading());

    try {
      final rider = await _service.register(
        fullName: event.fullName,
        email: event.email,
        phone: event.phone,
        vehicleType: event.vehicleType,
        vehicleReg: event.vehicleReg,
        password: event.password,
      );

      emit(RiderSignupSuccess(rider));
    } catch (error) {
      emit(RiderSignupFailure(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
