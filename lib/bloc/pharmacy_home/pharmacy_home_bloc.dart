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
      final pharmacy = await _service.getPharmacy(event.pharmacyId);

      if (pharmacy == null) {
        emit(const PharmacyHomeError('Pharmacy profile not found.'));
        return;
      }

      final counts = await _service.getOrderCounts(event.pharmacyId);

      emit(PharmacyHomeLoaded(
        pharmacy: pharmacy,
        totalOrders: counts['totalOrders'] ?? 0,
        completedOrders: counts['completedOrders'] ?? 0,
        activeOrders: counts['activeOrders'] ?? 0,
        newOrders: counts['newOrders'] ?? 0,
        preparingOrders: counts['preparingOrders'] ?? 0,
        readyOrders: counts['readyOrders'] ?? 0,
        deliveredOrders: counts['deliveredOrders'] ?? 0,
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
    add(LoadPharmacyHome(event.pharmacyId));
  }
}
