import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/pharmacy_model.dart';

class PharmacyLoginService {
  PharmacyLoginService._();
  static final PharmacyLoginService instance = PharmacyLoginService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<PharmacyModel> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final credential = await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Login failed. Please try again.');
    }

    final uid = firebaseUser.uid;

    DocumentSnapshot<Map<String, dynamic>>? doc;

    // 1. Check direct doc by UID
    final directDoc = await _firestore.collection('pharmacies').doc(uid).get();
    if (directDoc.exists && directDoc.data() != null) {
      doc = directDoc;
    }

    // 2. Look up by 'uid' field in pharmacies collection
    if (doc == null) {
      final uidQuery = await _firestore
          .collection('pharmacies')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (uidQuery.docs.isNotEmpty) {
        doc = uidQuery.docs.first;
      }
    }

    // 3. Look up by 'id' field in pharmacies collection
    if (doc == null) {
      final idQuery = await _firestore
          .collection('pharmacies')
          .where('id', isEqualTo: uid)
          .limit(1)
          .get();
      if (idQuery.docs.isNotEmpty) {
        doc = idQuery.docs.first;
      }
    }

    // 4. Look up by email in pharmacies collection
    if (doc == null) {
      final emailQuery = await _firestore
          .collection('pharmacies')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (emailQuery.docs.isNotEmpty) {
        doc = emailQuery.docs.first;
      }
    }

    // 5. If still not found, check pharmacy_applications
    if (doc == null) {
      final appSnapshot = await _firestore
          .collection('pharmacy_applications')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (appSnapshot.docs.isNotEmpty) {
        final appData = appSnapshot.docs.first.data();
        final status = (appData['status'] as String? ?? '').toLowerCase();
        final rejectionReason = appData['rejectionReason'] as String? ?? '';

        if (status == 'pending') {
          await _auth.signOut();
          throw Exception(
            'Your pharmacy application is still pending admin approval. You will receive an email once approved.',
          );
        } else if (status == 'rejected') {
          await _auth.signOut();
          throw Exception(
            rejectionReason.isNotEmpty
                ? 'Your pharmacy application was rejected: $rejectionReason'
                : 'Your pharmacy application was rejected. Please contact support.',
          );
        }
      }
    }

    if (doc == null || !doc.exists || doc.data() == null) {
      await _auth.signOut();
      throw Exception(
        'Your pharmacy account has not been activated yet. Please wait for admin approval.',
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

    final pharmacyId = (data['id'] as String?)?.isNotEmpty == true
        ? (data['id'] as String)
        : ((data['uid'] as String?)?.isNotEmpty == true
            ? (data['uid'] as String)
            : (doc.id.isNotEmpty ? doc.id : uid));

    // ignore: avoid_print
    print("AUTH UID: ${FirebaseAuth.instance.currentUser?.uid}");
    // ignore: avoid_print
    print("PHARMACY UID: ${data['uid']}");
    // ignore: avoid_print
    print("PHARMACY ID: $pharmacyId");

    final pharmacy = PharmacyModel.fromJson({...data, 'id': pharmacyId});
    return pharmacy;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw Exception('Please enter your email address.');
    }
    await _auth.sendPasswordResetEmail(email: normalized);
  }
}
