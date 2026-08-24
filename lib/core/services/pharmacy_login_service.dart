import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/pharmacy_model.dart';

class PharmacyLoginService {
  PharmacyLoginService._();
  static final PharmacyLoginService instance = PharmacyLoginService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<PharmacyModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Login failed. Please try again.');
    }

    final uid = firebaseUser.uid;

    final doc = await _firestore.collection('pharmacies').doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      final appSnapshot = await _firestore
          .collection('pharmacy_applications')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (appSnapshot.docs.isNotEmpty) {
        final appData = appSnapshot.docs.first.data();
        final status = appData['status'] as String? ?? '';

        await _auth.signOut();

        if (status == 'pending') {
          throw Exception(
            'Your pharmacy application is still waiting for admin approval.',
          );
        } else if (status == 'rejected') {
          throw Exception(
            'Your pharmacy application was rejected.',
          );
        }
      }

      await _auth.signOut();
      throw Exception(
        'Your account has not been created yet. Please wait for admin approval.',
      );
    }

    final data = doc.data()!;
    final active = data['active'] as bool? ?? false;

    if (!active) {
      await _auth.signOut();
      throw Exception(
        'Your pharmacy account is not active. Please contact support.',
      );
    }

    return PharmacyModel.fromJson({'id': doc.id, ...data});
  }
}
