import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/pharmacy_home_service.dart';
import 'pharmacy_home_event.dart';
import 'pharmacy_home_state.dart';

class PharmacyHomeBloc extends Bloc<PharmacyHomeEvent, PharmacyHomeState> {
  PharmacyHomeBloc({PharmacyHomeService? service})
      : _service = service ?? PharmacyHomeService.instance,
        super(const PharmacyHomeInitial()) {
    on<LoadPharmacyHome>(_onLoaded);
    on<PharmacyHomeRefreshed>(_onRefreshed);
  }

  final PharmacyHomeService _service;

  Future<void> _onLoaded(
    LoadPharmacyHome event,
    Emitter<PharmacyHomeState> emit,
  ) async {
    emit(const PharmacyHomeLoading());

    try {
      final pharmacy = await _service.getPharmacy('pharmacy_1');

      if (pharmacy == null) {
        emit(const PharmacyHomeError('Pharmacy profile not found.'));
        return;
      }

      emit(PharmacyHomeLoaded(
        pharmacy: pharmacy,
        totalOrders: 24,
        completedOrders: 18,
        activeOrders: 6,
        newOrders: 2,
        preparingOrders: 3,
        readyOrders: 1,
        deliveredOrders: 18,
      ));
    } catch (error) {
      emit(PharmacyHomeError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRefreshed(
    PharmacyHomeRefreshed event,
    Emitter<PharmacyHomeState> emit,
  ) async {
    add(const LoadPharmacyHome());
  }
}
