import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../models/user_model.dart';
import 'admin_profile_event.dart';
import 'admin_profile_state.dart';

class AdminProfileBloc
    extends Bloc<AdminProfileEvent, AdminProfileState> {
  AdminProfileBloc({
    AuthService? authService,
    FirestoreService? firestoreService,
  })  : _authService = authService ?? AuthService.instance,
        _firestoreService =
            firestoreService ?? FirestoreService.instance,
        super(const AdminProfileInitial()) {
    on<AdminProfileLoadRequested>(_onLoadRequested);
    on<AdminProfileUpdateRequested>(_onUpdateRequested);
    on<AdminProfileCleared>(_onCleared);
  }

  final AuthService _authService;
  final FirestoreService _firestoreService;

  Future<void> _onLoadRequested(
    AdminProfileLoadRequested event,
    Emitter<AdminProfileState> emit,
  ) async {
    emit(const AdminProfileLoading());

    try {
      final User? firebaseUser =
          FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        emit(const AdminProfileUnauthorized());
        return;
      }

      final bool admin =
          await _firestoreService.isAdmin(firebaseUser.uid);

      if (!admin) {
        emit(const AdminProfileUnauthorized());
        return;
      }

      final UserModel? adminProfile =
          await _firestoreService.getUser(firebaseUser.uid);

      if (adminProfile == null) {
        emit(const AdminProfileError(
          'Admin profile was not found.',
        ));
        return;
      }

      emit(AdminProfileLoaded(adminProfile));
    } catch (error) {
      emit(const AdminProfileError(
        'Unable to load admin profile. Please try again.',
      ));
    }
  }

  Future<void> _onUpdateRequested(
    AdminProfileUpdateRequested event,
    Emitter<AdminProfileState> emit,
  ) async {
    try {
      final User? firebaseUser =
          FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        emit(const AdminProfileUnauthorized());
        return;
      }

      final bool admin =
          await _firestoreService.isAdmin(firebaseUser.uid);

      if (!admin) {
        emit(const AdminProfileUnauthorized());
        return;
      }

      final UserModel? currentAdmin =
          await _firestoreService.getUser(firebaseUser.uid);

      if (currentAdmin == null) {
        emit(const AdminProfileError(
          'Admin profile was not found.',
        ));
        return;
      }

      final UserModel updatedAdmin = UserModel(
        id: currentAdmin.id,
        email: currentAdmin.email,
        name: event.name,
        phone: event.phone,
        role: currentAdmin.role,
        createdAt: currentAdmin.createdAt,
      );

      emit(AdminProfileUpdating(updatedAdmin));

      await _firestoreService.updateUser(
        uid: firebaseUser.uid,
        name: event.name,
        phone: event.phone,
      );

      final UserModel? refreshedAdmin =
          await _firestoreService.getUser(firebaseUser.uid);

      emit(AdminProfileLoaded(
        refreshedAdmin ?? updatedAdmin,
      ));
    } catch (error) {
      emit(const AdminProfileError(
        'Unable to update admin profile. Please try again.',
      ));
    }
  }

  Future<void> _onCleared(
    AdminProfileCleared event,
    Emitter<AdminProfileState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('admin_keep_signed_in', false);
      await _authService.signOut();
      emit(const AdminProfileClearedState());
    } catch (error) {
      emit(const AdminProfileError(
        'Unable to logout. Please try again.',
      ));
    }
  }
}
