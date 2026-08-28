import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/pharmacy_medicine_service.dart';
import 'pharmacy_medicines_event.dart';
import 'pharmacy_medicines_state.dart';

class PharmacyMedicinesBloc
    extends Bloc<PharmacyMedicinesEvent, PharmacyMedicinesState> {
  PharmacyMedicinesBloc({PharmacyMedicineService? service})
      : _service = service ?? PharmacyMedicineService.instance,
        super(const PharmacyMedicinesInitial()) {
    on<LoadPharmacyMedicines>(_onLoaded);
    on<PharmacyMedicinesRefreshed>(_onRefreshed);
    on<PharmacyMedicineAdded>(_onAdded);
    on<PharmacyMedicineUpdated>(_onUpdated);
    on<PharmacyMedicineDeleted>(_onDeleted);
  }

  final PharmacyMedicineService _service;
  String _pharmacyId = '';

  Future<void> _onLoaded(
    LoadPharmacyMedicines event,
    Emitter<PharmacyMedicinesState> emit,
  ) async {
    _pharmacyId = event.pharmacyId;
    emit(const PharmacyMedicinesLoading());

    try {
      final medicines = await _service.getMedicines(_pharmacyId);
      emit(PharmacyMedicinesLoaded(medicines: medicines));
    } catch (error) {
      emit(PharmacyMedicinesError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRefreshed(
    PharmacyMedicinesRefreshed event,
    Emitter<PharmacyMedicinesState> emit,
  ) async {
    try {
      final medicines = await _service.getMedicines(_pharmacyId);
      emit(PharmacyMedicinesLoaded(medicines: medicines));
    } catch (error) {
      emit(PharmacyMedicinesError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onAdded(
    PharmacyMedicineAdded event,
    Emitter<PharmacyMedicinesState> emit,
  ) async {
    try {
      await _service.addMedicine(
        pharmacyId: _pharmacyId,
        name: event.name,
        genericName: event.genericName,
        category: event.category,
        stock: event.stock,
        price: event.price,
        prescription: event.prescription,
        lowStockThreshold: event.lowStockThreshold,
      );

      final medicines = await _service.getMedicines(_pharmacyId);
      emit(PharmacyMedicinesLoaded(medicines: medicines));
    } catch (error) {
      emit(PharmacyMedicinesError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onUpdated(
    PharmacyMedicineUpdated event,
    Emitter<PharmacyMedicinesState> emit,
  ) async {
    try {
      await _service.updateMedicine(
        pharmacyId: _pharmacyId,
        medicineId: event.medicineId,
        name: event.name,
        genericName: event.genericName,
        category: event.category,
        stock: event.stock,
        price: event.price,
        prescription: event.prescription,
        lowStockThreshold: event.lowStockThreshold,
      );

      final medicines = await _service.getMedicines(_pharmacyId);
      emit(PharmacyMedicinesLoaded(medicines: medicines));
    } catch (error) {
      emit(PharmacyMedicinesError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onDeleted(
    PharmacyMedicineDeleted event,
    Emitter<PharmacyMedicinesState> emit,
  ) async {
    try {
      await _service.deleteMedicine(
        pharmacyId: _pharmacyId,
        medicineId: event.medicineId,
      );

      final medicines = await _service.getMedicines(_pharmacyId);
      emit(PharmacyMedicinesLoaded(medicines: medicines));
    } catch (error) {
      emit(PharmacyMedicinesError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
