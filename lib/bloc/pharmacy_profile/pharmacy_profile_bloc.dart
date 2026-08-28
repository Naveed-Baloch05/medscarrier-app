import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/pharmacy_profile_service.dart';
import 'pharmacy_profile_event.dart';
import 'pharmacy_profile_state.dart';

class PharmacyProfileBloc
    extends Bloc<PharmacyProfileEvent, PharmacyProfileState> {
  PharmacyProfileBloc({PharmacyProfileService? service})
      : _service = service ?? PharmacyProfileService.instance,
        super(const PharmacyProfileInitial()) {
    on<LoadPharmacyProfile>(_onLoaded);
    on<PharmacyProfileUpdated>(_onUpdated);
    on<PharmacyOpenToggled>(_onOpenToggled);
    on<PharmacyProfilePhotoChanged>(_onPhotoChanged);
    on<PharmacyProfilePhotoRemoved>(_onPhotoRemoved);
    on<PharmacyPasswordChanged>(_onPasswordChanged);
  }

  final PharmacyProfileService _service;

  String _uid = '';

  Map<String, dynamic> _currentData() {
    final s = state;
    if (s is PharmacyProfileLoaded) return s.data;
    if (s is PharmacyProfileUpdating) return s.data;
    if (s is PharmacyProfileOperationSuccess) return s.data;
    return <String, dynamic>{'uid': _uid};
  }

  Future<void> _onLoaded(
    LoadPharmacyProfile event,
    Emitter<PharmacyProfileState> emit,
  ) async {
    _uid = event.uid;
    emit(const PharmacyProfileLoading());

    try {
      final data = await _service.getProfile(_uid);
      emit(PharmacyProfileLoaded(data: data));
    } catch (error) {
      emit(PharmacyProfileError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onUpdated(
    PharmacyProfileUpdated event,
    Emitter<PharmacyProfileState> emit,
  ) async {
    final previousData = _currentData();
    emit(PharmacyProfileUpdating(previousData));

    try {
      await _service.updateProfile(
        uid: _uid,
        pharmacyName: event.pharmacyName,
        contactName: event.contactName,
        phone: event.phone,
        email: event.email,
        businessAddress: event.businessAddress,
        gphcNumber: event.gphcNumber,
        openingTime: event.openingTime,
        closingTime: event.closingTime,
        notificationsEnabled: event.notificationsEnabled,
      );

      final data = await _service.getProfile(_uid);
      emit(PharmacyProfileOperationSuccess('Profile updated.', data));
    } catch (error) {
      emit(PharmacyProfileError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onOpenToggled(
    PharmacyOpenToggled event,
    Emitter<PharmacyProfileState> emit,
  ) async {
    final previousData = _currentData();
    emit(PharmacyProfileUpdating(previousData));

    try {
      await _service.togglePharmacyOpen(
        uid: _uid,
        isOpen: event.isOpen,
      );

      final data = await _service.getProfile(_uid);
      emit(PharmacyProfileOperationSuccess(
        event.isOpen ? 'Pharmacy is now open.' : 'Pharmacy is now closed.',
        data,
      ));
    } catch (error) {
      emit(PharmacyProfileError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onPhotoChanged(
    PharmacyProfilePhotoChanged event,
    Emitter<PharmacyProfileState> emit,
  ) async {
    final previousData = _currentData();
    emit(PharmacyProfileUpdating(previousData));

    try {
      await _service.uploadProfilePhoto(
        uid: _uid,
        imageFile: event.imageFile,
      );

      final data = await _service.getProfile(_uid);
      emit(PharmacyProfileOperationSuccess('Profile photo updated.', data));
    } catch (error) {
      emit(PharmacyProfileError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onPhotoRemoved(
    PharmacyProfilePhotoRemoved event,
    Emitter<PharmacyProfileState> emit,
  ) async {
    final previousData = _currentData();
    emit(PharmacyProfileUpdating(previousData));

    try {
      await _service.removeProfilePhoto(_uid);

      final data = await _service.getProfile(_uid);
      emit(PharmacyProfileOperationSuccess('Profile photo removed.', data));
    } catch (error) {
      emit(PharmacyProfileError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onPasswordChanged(
    PharmacyPasswordChanged event,
    Emitter<PharmacyProfileState> emit,
  ) async {
    final previousData = _currentData();
    emit(PharmacyProfileUpdating(previousData));

    try {
      await _service.updatePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      final data = await _service.getProfile(_uid);
      emit(PharmacyProfileOperationSuccess('Password updated.', data));
    } catch (error) {
      emit(PharmacyProfileError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
