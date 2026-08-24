import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/rider_application_model.dart';

class RiderApplicationService {
  RiderApplicationService._();
  static final RiderApplicationService instance =
      RiderApplicationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('rider_applications');

  // ============================================================
  // GET PENDING APPLICATIONS (for admin)
  // ============================================================

  Future<List<RiderApplicationModel>> getPendingApplications() async {
    final snapshot = await _applications
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => RiderApplicationModel.fromFirestore(doc),
        )
        .toList();
  }

  Future<List<RiderApplicationModel>> getAllApplications() async {
    final snapshot =
        await _applications.orderBy('submittedAt', descending: true).get();

    return snapshot.docs
        .map(
          (doc) => RiderApplicationModel.fromFirestore(doc),
        )
        .toList();
  }

  // ============================================================
  // APPROVE APPLICATION (direct Firestore writes)
  // ============================================================

  Future<void> approveApplication({
    required String applicationId,
  }) async {
    final adminUser = _auth.currentUser;
    if (adminUser == null) throw Exception('Admin not authenticated.');

    final appDoc = await _applications.doc(applicationId).get();
    if (!appDoc.exists) throw Exception('Application not found.');

    final appData = appDoc.data()!;
    final status = appData['status'] as String? ?? '';

    if (status != 'pending') {
      throw Exception('Application is already $status.');
    }

    final riderUid = appData['uid'] as String;
    final batch = _firestore.batch();

    batch.update(_applications.doc(applicationId), {
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUser.uid,
    });

    final userRef = _firestore.collection('users').doc(riderUid);
    batch.set(userRef, {
      'uid': riderUid,
      'name': appData['fullName'],
      'email': appData['email'],
      'phone': appData['phone'],
      'role': 'rider',
      'vehicleType': appData['vehicleType'],
      'vehicleRegistrationNumber': appData['vehicleRegistrationNumber'],
      'profilePhotoUrl': appData['profilePhotoUrl'],
      'drivingLicenceFrontUrl': appData['drivingLicenceFrontUrl'],
      'drivingLicenceBackUrl': appData['drivingLicenceBackUrl'],
      'accountStatus': 'active',
      'applicationId': applicationId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final riderRef = _firestore.collection('riders').doc(riderUid);
    batch.set(riderRef, {
      'id': riderUid,
      'fullName': appData['fullName'],
      'email': appData['email'],
      'phone': appData['phone'],
      'vehicleType': appData['vehicleType'],
      'vehicleReg': appData['vehicleRegistrationNumber'],
      'active': true,
      'online': false,
      'deliveries': 0,
      'currentOrder': null,
      'location': 'Location unavailable',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // ============================================================
  // REJECT APPLICATION (direct Firestore writes)
  // ============================================================

  Future<void> rejectApplication({
    required String applicationId,
    required String rejectionReason,
  }) async {
    final adminUser = _auth.currentUser;
    if (adminUser == null) throw Exception('Admin not authenticated.');

    final appDoc = await _applications.doc(applicationId).get();
    if (!appDoc.exists) throw Exception('Application not found.');

    final appData = appDoc.data()!;
    final status = appData['status'] as String? ?? '';

    if (status != 'pending') {
      throw Exception('Application is already $status.');
    }

    await _applications.doc(applicationId).update({
      'status': 'rejected',
      'rejectionReason': rejectionReason,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUser.uid,
    });
  }
}
