import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/admin_pharmacy_service.dart';
import 'admin_pharmacy_event.dart';
import 'admin_pharmacy_state.dart';

class AdminPharmacyBloc
    extends Bloc<AdminPharmacyEvent, AdminPharmacyState> {
  AdminPharmacyBloc({
    AdminPharmacyService? service,
  })  : _service = service ?? AdminPharmacyService.instance,
        super(const AdminPharmacyInitial()) {
    on<AdminPharmacyLoadRequested>(_onLoadRequested);
    on<AdminPharmacyApproved>(_onApproved);
    on<AdminPharmacyRejected>(_onRejected);
    on<AdminPharmacySuspended>(_onSuspended);
    on<AdminPharmacyActivated>(_onActivated);
    on<AdminPharmacyDeactivated>(_onDeactivated);
    on<AdminPharmacyUpdated>(_onUpdated);
    on<AdminPharmacyRefreshed>(_onRefreshed);
    on<AdminPharmacyApplicationApprove>(_onApplicationApprove);
    on<AdminPharmacyApplicationReject>(_onApplicationReject);
  }

  final AdminPharmacyService _service;

  Future<void> _loadData(Emitter<AdminPharmacyState> emit) async {
    final pharmacies = await _service.getAllPharmacies();
    try {
      final pendingApps = await _service.getPendingPharmacyApplications();
      emit(AdminPharmacyLoadedWithApplications(pharmacies, pendingApps));
    } catch (_) {
      emit(AdminPharmacyLoaded(pharmacies));
    }
  }

  Future<void> _onLoadRequested(
    AdminPharmacyLoadRequested event,
    Emitter<AdminPharmacyState> emit,
  ) async {
    emit(const AdminPharmacyLoading());
    try {
      await _loadData(emit);
    } catch (error) {
      emit(AdminPharmacyError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRefreshed(
    AdminPharmacyRefreshed event,
    Emitter<AdminPharmacyState> emit,
  ) async {
    try {
      await _loadData(emit);
    } catch (error) {
      emit(AdminPharmacyError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onApproved(
    AdminPharmacyApproved event,
    Emitter<AdminPharmacyState> emit,
  ) async {
    try {
      await _service.approvePharmacy(event.pharmacyId);
      emit(const AdminPharmacyOperationSuccess('Pharmacy approved.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminPharmacyError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRejected(
    AdminPharmacyRejected event,
    Emitter<AdminPharmacyState> emit,
  ) async {
    try {
      await _service.rejectPharmacy(event.pharmacyId);
      emit(const AdminPharmacyOperationSuccess('Pharmacy rejected.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminPharmacyError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onSuspended(
    AdminPharmacySuspended event,
    Emitter<AdminPharmacyState> emit,
  ) async {
    try {
      await _service.suspendPharmacy(event.pharmacyId);
      emit(const AdminPharmacyOperationSuccess('Pharmacy suspended.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminPharmacyError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onActivated(
    AdminPharmacyActivated event,
    Emitter<AdminPharmacyState> emit,
  ) async {
    try {
      await _service.activatePharmacy(event.pharmacyId);
      emit(const AdminPharmacyOperationSuccess('Pharmacy activated.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminPharmacyError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onDeactivated(
    AdminPharmacyDeactivated event,
    Emitter<AdminPharmacyState> emit,
  ) async {
    try {
      await _service.deactivatePharmacy(event.pharmacyId);
      emit(const AdminPharmacyOperationSuccess('Pharmacy deactivated.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminPharmacyError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onUpdated(
    AdminPharmacyUpdated event,
    Emitter<AdminPharmacyState> emit,
  ) async {
    try {
      await _service.updatePharmacy(event.pharmacyId, event.data);
      emit(const AdminPharmacyOperationSuccess('Pharmacy updated.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminPharmacyError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onApplicationApprove(
    AdminPharmacyApplicationApprove event,
    Emitter<AdminPharmacyState> emit,
  ) async {
    try {
      await _service.approvePharmacyApplication(event.applicationId);
      emit(const AdminPharmacyOperationSuccess('Pharmacy application approved.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminPharmacyError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onApplicationReject(
    AdminPharmacyApplicationReject event,
    Emitter<AdminPharmacyState> emit,
  ) async {
    try {
      await _service.rejectPharmacyApplication(
        event.applicationId,
        rejectionReason: event.rejectionReason,
      );
      emit(const AdminPharmacyOperationSuccess('Pharmacy application rejected.'));
      await _loadData(emit);
    } catch (error) {
      emit(AdminPharmacyError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
