import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/pharmacy_signup_service.dart';
import 'pharmacy_signup_event.dart';
import 'pharmacy_signup_state.dart';

class PharmacySignupBloc extends Bloc<PharmacySignupEvent, PharmacySignupState> {
  PharmacySignupBloc({PharmacySignupService? service})
      : _service = service ?? PharmacySignupService.instance,
        super(const PharmacySignupInitial()) {
    on<PharmacySignupSubmitted>(_onSubmitted);
    on<PharmacySignupReset>((_, emit) => emit(const PharmacySignupInitial()));
  }

  final PharmacySignupService _service;

  Future<void> _onSubmitted(
    PharmacySignupSubmitted event,
    Emitter<PharmacySignupState> emit,
  ) async {
    emit(const PharmacySignupLoading());

    try {
      final application = await _service.submitApplication(
        pharmacyName: event.pharmacyName,
        contactName: event.contactName,
        email: event.email,
        phone: event.phone,
        businessAddress: event.businessAddress,
        gphcNumber: event.gphcNumber,
        licenseDocument: event.licenseDocument,
      );

      emit(PharmacySignupSuccess(application));
    } catch (error) {
      emit(PharmacySignupFailure(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
