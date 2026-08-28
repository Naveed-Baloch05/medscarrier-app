import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/rider_model.dart';

class RiderLoginService {
  RiderLoginService._();
  static final RiderLoginService instance = RiderLoginService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<RiderModel> login({
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
    final directDoc = await _firestore.collection('riders').doc(uid).get();
    if (directDoc.exists && directDoc.data() != null) {
      doc = directDoc;
    }

    // 2. Look up by 'uid' field
    if (doc == null) {
      final uidQuery = await _firestore
          .collection('riders')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (uidQuery.docs.isNotEmpty) {
        doc = uidQuery.docs.first;
      }
    }

    // 3. Look up by 'id' field
    if (doc == null) {
      final idQuery = await _firestore
          .collection('riders')
          .where('id', isEqualTo: uid)
          .limit(1)
          .get();
      if (idQuery.docs.isNotEmpty) {
        doc = idQuery.docs.first;
      }
    }

    // 4. Look up by email in riders collection
    if (doc == null) {
      final emailQuery = await _firestore
          .collection('riders')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      if (emailQuery.docs.isNotEmpty) {
        doc = emailQuery.docs.first;
      }
    }

    // 5. If not found in riders collection, check rider_applications
    if (doc == null) {
      final appSnapshot = await _firestore
          .collection('rider_applications')
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
            'Your rider application is still pending admin approval. You will receive an email once approved.',
          );
        } else if (status == 'rejected') {
          await _auth.signOut();
          throw Exception(
            rejectionReason.isNotEmpty
                ? 'Your rider application was rejected: $rejectionReason'
                : 'Your rider application was rejected. Please contact support.',
          );
        }
      }
    }

    if (doc == null || !doc.exists || doc.data() == null) {
      await _auth.signOut();
      throw Exception(
        'Your rider account has not been activated yet. Please wait for admin approval.',
      );
    }

    final data = doc.data()!;
    final active = data['active'] as bool? ?? false;

    if (!active) {
      await _auth.signOut();
      throw Exception(
        'Your rider account is not active. Please contact support.',
      );
    }

    final riderId = (data['id'] as String?)?.isNotEmpty == true
        ? (data['id'] as String)
        : ((data['uid'] as String?)?.isNotEmpty == true
            ? (data['uid'] as String)
            : (doc.id.isNotEmpty ? doc.id : uid));

    return RiderModel(
      id: riderId,
      fullName: data['fullName'] as String? ?? data['name'] as String? ?? '',
      email: data['email'] as String? ?? normalizedEmail,
      phone: data['phone'] as String? ?? '',
      vehicleType: data['vehicleType'] as String? ?? '',
      vehicleReg: data['vehicleReg'] as String? ??
          data['vehicleRegistrationNumber'] as String? ??
          '',
      online: data['online'] as bool? ?? false,
      active: active,
      location: data['location'] is Map
          ? Map<String, dynamic>.from(data['location'] as Map)
          : null,
      deliveries: data['deliveries'] as int? ?? 0,
      currentOrder: data['currentOrder'] as String?,
      lastSeen: _parseTimestamp(data['lastSeen']),
      deliveryStatus: data['deliveryStatus'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw Exception('Please enter your email address.');
    }
    await _auth.sendPasswordResetEmail(email: normalized);
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
