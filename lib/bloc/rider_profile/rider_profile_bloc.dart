import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/rider_profile_service.dart';
import 'rider_profile_event.dart';
import 'rider_profile_state.dart';

class RiderProfileBloc extends Bloc<RiderProfileEvent, RiderProfileState> {
  RiderProfileBloc({RiderProfileService? service, Map<String, dynamic>? initialData})
      : _service = service ?? RiderProfileService.instance,
        _riderId = _extractId(initialData),
        super(initialData != null
            ? RiderProfileLoaded(data: initialData)
            : const RiderProfileInitial()) {
    on<LoadRiderProfile>(_onLoaded);
    on<RiderProfileUpdated>(_onUpdated);
    on<RiderAvailabilityToggled>(_onAvailabilityToggled);
    on<RiderProfilePhotoChanged>(_onPhotoChanged);
    on<RiderProfilePhotoRemoved>(_onPhotoRemoved);
    on<RiderPasswordChanged>(_onPasswordChanged);
    on<RiderLoggedOut>(_onLoggedOut);
    if (initialData != null) {
      add(LoadRiderProfile(_riderId));
    }
  }

  static String _extractId(Map<String, dynamic>? data) {
    if (data == null) return '';
    return (data['id'] as String?) ?? (data['uid'] as String?) ?? '';
  }

  final RiderProfileService _service;

  String _riderId = '';

  Map<String, dynamic> _currentData() {
    final s = state;
    if (s is RiderProfileLoaded) return s.data;
    if (s is RiderProfileUpdating) return s.data;
    if (s is RiderProfileOperationSuccess) return s.data;
    return <String, dynamic>{'id': _riderId};
  }

  Future<void> _onLoaded(
    LoadRiderProfile event,
    Emitter<RiderProfileState> emit,
  ) async {
    _riderId = event.riderId;
    final hasData = state is RiderProfileLoaded;
    if (!hasData) {
      emit(const RiderProfileLoading());
    }

    try {
      final data = await _service.getProfile(_riderId);
      if (data.isEmpty || (data['id']?.toString().isEmpty ?? true)) {
        emit(const RiderProfileError('Rider profile not found.'));
        return;
      }
      emit(RiderProfileLoaded(data: data));
    } catch (error) {
      emit(RiderProfileError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onUpdated(
    RiderProfileUpdated event,
    Emitter<RiderProfileState> emit,
  ) async {
    final previousData = _currentData();
    emit(RiderProfileUpdating(previousData));

    try {
      await _service.updateProfile(
        riderId: _riderId,
        fullName: event.fullName,
        phone: event.phone,
        email: event.email,
        vehicleType: event.vehicleType,
        vehicleReg: event.vehicleReg,
        notificationsEnabled: event.notificationsEnabled,
      );

      final data = await _service.getProfile(_riderId);
      emit(RiderProfileOperationSuccess('Profile updated.', data));
    } catch (error) {
      emit(RiderProfileError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onAvailabilityToggled(
    RiderAvailabilityToggled event,
    Emitter<RiderProfileState> emit,
  ) async {
    final previousData = _currentData();
    emit(RiderProfileUpdating(previousData));

    try {
      await _service.toggleAvailability(
        riderId: _riderId,
        isOnline: event.isOnline,
      );

      final data = await _service.getProfile(_riderId);
      emit(RiderProfileOperationSuccess(
        event.isOnline ? 'You are now online.' : 'You are now offline.',
        data,
      ));
    } catch (error) {
      emit(RiderProfileError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onPhotoChanged(
    RiderProfilePhotoChanged event,
    Emitter<RiderProfileState> emit,
  ) async {
    final previousData = _currentData();
    emit(RiderProfileUpdating(previousData));

    try {
      final url = await _service.uploadProfilePhoto(
        riderId: _riderId,
        imageFile: event.imageFile,
      );

      final data = await _service.getProfile(_riderId);
      if (url != null) data['profilePhotoUrl'] = url;
      emit(RiderProfileOperationSuccess('Profile photo updated.', data));
    } catch (error) {
      emit(RiderProfileError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onPhotoRemoved(
    RiderProfilePhotoRemoved event,
    Emitter<RiderProfileState> emit,
  ) async {
    final previousData = _currentData();
    emit(RiderProfileUpdating(previousData));

    try {
      await _service.removeProfilePhoto(_riderId);

      final data = await _service.getProfile(_riderId);
      emit(RiderProfileOperationSuccess('Profile photo removed.', data));
    } catch (error) {
      emit(RiderProfileError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onPasswordChanged(
    RiderPasswordChanged event,
    Emitter<RiderProfileState> emit,
  ) async {
    final previousData = _currentData();
    emit(RiderProfileUpdating(previousData));

    try {
      await _service.updatePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      final data = await _service.getProfile(_riderId);
      emit(RiderProfileOperationSuccess('Password updated.', data));
    } catch (error) {
      emit(RiderProfileError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onLoggedOut(
    RiderLoggedOut event,
    Emitter<RiderProfileState> emit,
  ) async {
    try {
      await _service.logout();
      emit(const RiderProfileOperationSuccess('Logged out.', <String, dynamic>{'id': ''}));
    } catch (error) {
      emit(RiderProfileError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}
