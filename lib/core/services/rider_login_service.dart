import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/rider_model.dart';

/// Set to `true` to skip Firebase login entirely during development.
/// Set to `false` for real Firebase authentication.
const bool kUseMockRiderLogin = true;

class RiderLoginService {
  RiderLoginService._();
  static final RiderLoginService instance = RiderLoginService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<RiderModel> login({
    required String email,
    required String password,
  }) async {
    if (kUseMockRiderLogin) {
      return RiderModel(
        id: 'mock-rider-001',
        fullName: 'Dev Rider',
        email: email.trim(),
        phone: '07000000000',
        vehicleType: 'Car',
        vehicleReg: 'MOCK 1A',
        active: true,
        createdAt: DateTime.now(),
      );
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Login failed. Please try again.');
    }

    final uid = firebaseUser.uid;

    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      final appSnapshot = await _firestore
          .collection('rider_applications')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (appSnapshot.docs.isNotEmpty) {
        final appData = appSnapshot.docs.first.data();
        final status = appData['status'] as String? ?? '';

        await _auth.signOut();

        if (status == 'pending') {
          throw Exception(
            'Your application is still waiting for admin approval.',
          );
        } else if (status == 'rejected') {
          throw Exception(
            'Your rider application was rejected.',
          );
        }
      }

      await _auth.signOut();
      throw Exception(
        'Account not found. Your application may still be pending.',
      );
    }

    final data = doc.data()!;
    final role = data['role'] as String? ?? '';
    final accountStatus = data['accountStatus'] as String? ?? '';

    if (role != 'rider') {
      await _auth.signOut();
      throw Exception('Access denied. This account is not a rider.');
    }

    if (accountStatus != 'active') {
      await _auth.signOut();
      throw Exception(
        'Your account is not active. Please wait for admin approval.',
      );
    }

    return RiderModel(
      id: uid,
      fullName: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      vehicleType: data['vehicleType'] as String? ?? '',
      vehicleReg: data['vehicleRegistrationNumber'] as String? ?? '',
      active: true,
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
