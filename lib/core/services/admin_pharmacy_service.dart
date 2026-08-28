import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../models/pharmacy_application_model.dart';
import 'admin_notification_service.dart';

class AdminPharmacyService {
  AdminPharmacyService._();
  static final AdminPharmacyService instance = AdminPharmacyService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _pharmacies =>
      _firestore.collection('pharmacies');

  CollectionReference<Map<String, dynamic>> get _pharmacyApplications =>
      _firestore.collection('pharmacy_applications');

  // ──────────────────────────────────────────────────────────────
  // EXISTING: Approved pharmacies CRUD
  // ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllPharmacies() async {
    try {
      final snapshot =
          await _pharmacies.get();
      final list = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
      list.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate is Timestamp && bDate is Timestamp) {
          return bDate.compareTo(aDate);
        }
        return 0;
      });
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> approvePharmacy(String pharmacyId) =>
      _setStatus(pharmacyId, 'Approved', true);

  Future<void> rejectPharmacy(String pharmacyId) =>
      _setStatus(pharmacyId, 'Rejected', false);

  Future<void> suspendPharmacy(String pharmacyId) =>
      _setStatus(pharmacyId, 'Suspended', false);

  Future<void> activatePharmacy(String pharmacyId) =>
      _setStatus(pharmacyId, 'Approved', true);

  Future<void> deactivatePharmacy(String pharmacyId) async {
    try {
      await _pharmacies.doc(pharmacyId).update({
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to deactivate pharmacy: $e');
    }
  }

  Future<void> updatePharmacy(
    String pharmacyId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _pharmacies.doc(pharmacyId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update pharmacy: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> pharmaciesStream() {
    return _pharmacies.snapshots().map(
          (snapshot) {
            final list = snapshot.docs.map((doc) {
              return {'id': doc.id, ...doc.data()};
            }).toList();
            list.sort((a, b) {
              final aDate = a['createdAt'];
              final bDate = b['createdAt'];
              if (aDate is Timestamp && bDate is Timestamp) {
                return bDate.compareTo(aDate);
              }
              return 0;
            });
            return list;
          },
        );
  }

  Future<void> _setStatus(
    String pharmacyId,
    String status,
    bool active,
  ) async {
    try {
      await _pharmacies.doc(pharmacyId).update({
        'status': status,
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update pharmacy status: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // NEW: Pending pharmacy applications
  // ──────────────────────────────────────────────────────────────

  Stream<List<PharmacyApplicationModel>> streamPendingPharmacyApplications() {
    return _pharmacyApplications
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return PharmacyApplicationModel.fromFirestore(doc);
      }).toList();

      list.sort((a, b) {
        final aDate = a.submittedAt ?? DateTime(2000);
        final bDate = b.submittedAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return list;
    });
  }

  Future<List<PharmacyApplicationModel>>
      getPendingPharmacyApplications() async {
    try {
      final snapshot = await _pharmacyApplications
          .where('status', isEqualTo: 'pending')
          .get();

      final list = snapshot.docs.map((doc) {
        return PharmacyApplicationModel.fromFirestore(doc);
      }).toList();

      list.sort((a, b) {
        final aDate = a.submittedAt ?? DateTime(2000);
        final bDate = b.submittedAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> approvePharmacyApplication(String applicationId) async {
    final user = FirebaseAuth.instance.currentUser;
    final adminUid = user?.uid ?? 'admin';

    final appDoc = await _pharmacyApplications.doc(applicationId).get();
    if (!appDoc.exists) throw Exception('Application not found.');

    final data = appDoc.data()!;
    final email = (data['email'] as String? ?? '').trim().toLowerCase();
    final pharmacyName = data['pharmacyName'] as String? ?? 'Pharmacy';

    String uid = (data['uid'] as String? ?? '').trim();
    if (uid.isEmpty && email.isNotEmpty) {
      final authUid = await _createAuthAndGetUid(email);
      if (authUid != null && authUid.isNotEmpty) {
        uid = authUid;
      } else {
        uid = applicationId;
      }
    } else if (uid.isEmpty) {
      uid = applicationId;
    }

    final batch = _firestore.batch();

    batch.update(_pharmacyApplications.doc(applicationId), {
      'status': 'approved',
      'accountCreated': true,
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': adminUid,
      'uid': uid,
    });

    batch.set(
      _pharmacies.doc(uid),
      {
        'id': uid,
        'uid': uid,
        'applicationId': applicationId,
        'pharmacyName': data['pharmacyName'] ?? '',
        'contactName': data['contactName'] ?? '',
        'email': email,
        'phone': data['phone'] ?? '',
        'businessAddress': data['businessAddress'] ?? '',
        'gphcNumber': data['gphcNumber'] ?? '',
        'licenseDocumentUrl': data['licenseDocumentUrl'] ?? '',
        'status': 'Approved',
        'active': true,
        'createdAt': data['submittedAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      _firestore.collection('users').doc(uid),
      {
        'id': uid,
        'uid': uid,
        'applicationId': applicationId,
        'name': data['contactName'] ?? data['pharmacyName'] ?? '',
        'email': email,
        'phone': data['phone'] ?? '',
        'role': 'pharmacy',
        'accountStatus': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    if (email.isNotEmpty) {
      await _sendPasswordResetEmail(email);
    }

    try {
      await AdminNotificationService.instance.createNotification(
        title: 'Pharmacy Application Approved',
        body: '$pharmacyName has been approved and a password setup link was sent to $email.',
        type: 'pharmacy',
        referenceId: applicationId,
      );
    } catch (_) {}
  }

  Future<String?> _createAuthAndGetUid(String email) async {
    try {
      final secondaryApp = await _getSecondaryApp();
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final tempPassword = _generateTempPassword();
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );
      final authUid = cred.user!.uid;
      await secondaryAuth.signOut();
      return authUid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      final secondaryApp = await _getSecondaryApp();
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      await secondaryAuth.sendPasswordResetEmail(email: email);
      await secondaryAuth.signOut();
    } catch (_) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      } catch (_) {}
    }
  }

  Future<FirebaseApp> _getSecondaryApp() async {
    try {
      return Firebase.app('pharmacy-approval');
    } catch (_) {
      return Firebase.initializeApp(
        name: 'pharmacy-approval',
        options: Firebase.app().options,
      );
    }
  }

  String _generateTempPassword() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#';
    final rng = DateTime.now().millisecondsSinceEpoch;
    return List.generate(16, (i) => chars[(rng + i * 7) % chars.length]).join();
  }

  Future<void> rejectPharmacyApplication(
    String applicationId, {
    String rejectionReason = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final adminUid = user?.uid ?? 'admin';

    final appDoc = await _pharmacyApplications.doc(applicationId).get();
    if (!appDoc.exists) throw Exception('Application not found.');

    final name = appDoc.data()?['pharmacyName'] as String? ?? 'Pharmacy';

    await _pharmacyApplications.doc(applicationId).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': adminUid,
      if (rejectionReason.isNotEmpty) 'rejectionReason': rejectionReason,
    });

    try {
      await AdminNotificationService.instance.createNotification(
        title: 'Pharmacy Application Rejected',
        body: '$name application was rejected.',
        type: 'pharmacy',
        referenceId: applicationId,
      );
    } catch (_) {}
  }
}
