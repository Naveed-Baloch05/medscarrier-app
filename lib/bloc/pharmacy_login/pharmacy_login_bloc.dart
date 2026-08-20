import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/pharmacy_login_service.dart';
import 'pharmacy_login_event.dart';
import 'pharmacy_login_state.dart';

class PharmacyLoginBloc extends Bloc<PharmacyLoginEvent, PharmacyLoginState> {
  PharmacyLoginBloc({PharmacyLoginService? service})
      : _service = service ?? PharmacyLoginService.instance,
        super(const PharmacyLoginInitial()) {
    on<PharmacyLoginSubmitted>(_onSubmitted);
  }

  final PharmacyLoginService _service;

  Future<void> _onSubmitted(
    PharmacyLoginSubmitted event,
    Emitter<PharmacyLoginState> emit,
  ) async {
    emit(const PharmacyLoginLoading());

    try {
      final pharmacy = await _service.login(
        email: event.email,
        password: event.password,
      );

      emit(PharmacyLoginSuccess(pharmacy));
    } catch (error) {
      emit(PharmacyLoginFailure(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
