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
      final application = await _service.register(
        fullName: event.fullName,
        email: event.email,
        phone: event.phone,
        vehicleType: event.vehicleType,
        vehicleReg: event.vehicleReg,
        password: event.password,
        profilePhoto: event.profilePhoto,
        drivingLicenceFront: event.drivingLicenceFront,
        drivingLicenceBack: event.drivingLicenceBack,
      );

      emit(RiderSignupSuccess(application));
    } catch (error) {
      emit(RiderSignupFailure(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
