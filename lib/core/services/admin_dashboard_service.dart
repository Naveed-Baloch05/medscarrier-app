import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/pharmacy_model.dart';
import '../../models/order_model.dart';
import '../../models/rider_application_model.dart';
import 'admin_notification_service.dart';

class AdminDashboardService {
  AdminDashboardService._();
  static final AdminDashboardService instance = AdminDashboardService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _pharmacies =>
      _firestore.collection('pharmacies');
  CollectionReference<Map<String, dynamic>> get _pharmacyApplications =>
      _firestore.collection('pharmacy_applications');
  CollectionReference<Map<String, dynamic>> get _riderApplications =>
      _firestore.collection('rider_applications');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');
  CollectionReference<Map<String, dynamic>> get _riders =>
      _firestore.collection('riders');

  Future<Map<String, int>> fetchDashboardData() async {
    try {
      final results = await Future.wait([
        _safeCount(_firestore.collection('orders')),
        _getActiveOrderCount(),
        _getCompletedOrderCount(),
        _getAverageDeliveryTimeMinutes(),
        _safeCount(_firestore.collection('riders')),
        _getOnlineRiderCount(),
        _getActiveRiderCount(),
        _safeCount(_firestore.collection('pharmacies')),
        _getPendingPharmacyCount(),
        _getActivePharmacyCount(),
        _getPendingRiderCount(),
      ]);

      return {
        'totalOrders': results[0],
        'activeOrders': results[1],
        'completedOrders': results[2],
        'avgDeliveryTime': results[3],
        'totalRiders': results[4],
        'onlineRiders': results[5],
        'activeRiders': results[6],
        'totalPharmacies': results[7],
        'pendingPharmacies': results[8],
        'activePharmacies': results[9],
        'pendingRiders': results[10],
      };
    } catch (_) {
      return {
        'totalOrders': 0,
        'activeOrders': 0,
        'completedOrders': 0,
        'avgDeliveryTime': 0,
        'totalRiders': 0,
        'onlineRiders': 0,
        'activeRiders': 0,
        'totalPharmacies': 0,
        'pendingPharmacies': 0,
        'activePharmacies': 0,
        'pendingRiders': 0,
      };
    }
  }

  Future<int> _safeCount(CollectionReference collection) async {
    try {
      final snap = await collection.count().get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Stream<List<PharmacyModel>> streamPendingPharmacies() {
    return _pharmacyApplications
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return PharmacyModel(
          id: doc.id,
          pharmacyName: data['pharmacyName'] as String? ?? 'Pharmacy',
          contactName: data['contactName'] as String? ?? '',
          email: data['email'] as String? ?? '',
          phone: data['phone'] as String? ?? '',
          businessAddress: data['businessAddress'] as String? ?? '',
          gphcNumber: data['gphcNumber'] as String? ?? '',
          licenseDocumentUrl: data['licenseDocumentUrl'] as String? ??
              data['licenseUrl'] as String? ??
              data['licenseDocument'] as String?,
          status: 'Pending',
          active: false,
          createdAt: _parseDate(data['submittedAt'] ?? data['createdAt']),
        );
      }).toList();

      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return list;
    });
  }

  Future<List<PharmacyModel>> fetchPendingPharmacies() async {
    try {
      final snapshot = await _pharmacyApplications
          .where('status', isEqualTo: 'pending')
          .get();

      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return PharmacyModel(
          id: doc.id,
          pharmacyName: data['pharmacyName'] as String? ?? 'Pharmacy',
          contactName: data['contactName'] as String? ?? '',
          email: data['email'] as String? ?? '',
          phone: data['phone'] as String? ?? '',
          businessAddress: data['businessAddress'] as String? ?? '',
          gphcNumber: data['gphcNumber'] as String? ?? '',
          licenseDocumentUrl: data['licenseDocumentUrl'] as String? ??
              data['licenseUrl'] as String? ??
              data['licenseDocument'] as String?,
          status: 'Pending',
          active: false,
          createdAt: _parseDate(data['submittedAt'] ?? data['createdAt']),
        );
      }).toList();

      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return list;
    } catch (_) {
      return [];
    }
  }

  Stream<List<RiderApplicationModel>> streamPendingRiders() {
    return _riderApplications
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => RiderApplicationModel.fromFirestore(doc))
          .toList();

      list.sort((a, b) {
        final aDate = a.submittedAt ?? DateTime(2000);
        final bDate = b.submittedAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      return list;
    });
  }

  Future<List<RiderApplicationModel>> fetchPendingRiders() async {
    try {
      final snapshot = await _riderApplications
          .where('status', isEqualTo: 'pending')
          .get();

      final list = snapshot.docs
          .map((doc) => RiderApplicationModel.fromFirestore(doc))
          .toList();

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

  Future<List<RiderApplicationModel>> getPendingApplications() async {
    final snapshot = await _riderApplications
        .where('status', isEqualTo: 'pending')
        .get();

    final list = snapshot.docs
        .map((doc) => RiderApplicationModel.fromFirestore(doc))
        .toList();

    list.sort((a, b) {
      final aDate = a.submittedAt ?? DateTime(2000);
      final bDate = b.submittedAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return list;
  }

  Future<List<RiderApplicationModel>> getAllApplications() async {
    final snapshot = await _riderApplications.get();

    final list = snapshot.docs
        .map((doc) => RiderApplicationModel.fromFirestore(doc))
        .toList();

    list.sort((a, b) {
      final aDate = a.submittedAt ?? DateTime(2000);
      final bDate = b.submittedAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return list;
  }

  Future<void> approveRider(String applicationId) async {
    await approveRiderApplication(applicationId: applicationId);
  }

  Future<void> rejectRider(String applicationId, {String reason = ''}) async {
    await rejectRiderApplication(
      applicationId: applicationId,
      rejectionReason: reason,
    );
  }

  // ============================================================
  // RIDER APPLICATION APPROVE / REJECT (mirrors pharmacy inline flow)
  // ============================================================

  Future<void> approveRiderApplication({
    required String applicationId,
  }) async {
    final adminUser = FirebaseAuth.instance.currentUser;
    final adminUid = adminUser?.uid ?? 'admin';

    final appDoc = await _riderApplications.doc(applicationId).get();
    if (!appDoc.exists) throw Exception('Application not found.');

    final appData = appDoc.data()!;
    final status = appData['status'] as String? ?? '';

    if (status != 'pending') {
      throw Exception('Application is already $status.');
    }

    final riderEmail = (appData['email'] as String? ?? '').trim().toLowerCase();
    final riderName = (appData['fullName'] as String? ?? 'Rider').trim();

    // Resolve the rider uid, creating the Firebase Auth user if necessary
    var riderUid = (appData['uid'] as String? ?? '').trim();
    if (riderUid.isEmpty) {
      final authUid = await _createRiderAuthAndGetUid(riderEmail);
      if (authUid != null && authUid.isNotEmpty) {
        riderUid = authUid;
      } else {
        riderUid = applicationId;
      }
    }

    final batch = _firestore.batch();

    batch.update(_riderApplications.doc(applicationId), {
      'status': 'approved',
      'accountCreated': true,
      'approvedAt': FieldValue.serverTimestamp(),
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
      'uid': riderUid,
    });

    final userRef = _firestore.collection('users').doc(riderUid);
    batch.set(userRef, {
      'id': riderUid,
      'uid': riderUid,
      'name': appData['fullName'] ?? '',
      'email': riderEmail,
      'phone': appData['phone'] ?? '',
      'role': 'rider',
      'vehicleType': appData['vehicleType'] ?? '',
      'vehicleRegistrationNumber': appData['vehicleRegistrationNumber'] ?? '',
      'profilePhotoUrl': appData['profilePhotoUrl'],
      'drivingLicenceFrontUrl': appData['drivingLicenceFrontUrl'],
      'drivingLicenceBackUrl': appData['drivingLicenceBackUrl'],
      'accountStatus': 'active',
      'applicationId': applicationId,
      'createdAt': appData['submittedAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final riderRef = _riders.doc(riderUid);
    batch.set(riderRef, {
      'id': riderUid,
      'uid': riderUid,
      'fullName': appData['fullName'] ?? '',
      'email': riderEmail,
      'phone': appData['phone'] ?? '',
      'vehicleType': appData['vehicleType'] ?? '',
      'vehicleReg': appData['vehicleRegistrationNumber'] ?? '',
      'status': 'Approved',
      'active': true,
      'online': false,
      'deliveries': 0,
      'currentOrder': null,
      'location': 'Location unavailable',
      'createdAt': appData['submittedAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    // Send password creation / setup link email to the rider
    if (riderEmail.isNotEmpty) {
      await _sendRiderPasswordResetEmail(riderEmail);
    }

    try {
      await AdminNotificationService.instance.createNotification(
        title: 'Rider Application Approved',
        body: '$riderName application has been approved and a password setup link was sent to $riderEmail.',
        type: 'rider',
        referenceId: applicationId,
      );
    } catch (_) {}
  }

  Future<void> rejectRiderApplication({
    required String applicationId,
    required String rejectionReason,
  }) async {
    final adminUser = FirebaseAuth.instance.currentUser;
    final adminUid = adminUser?.uid ?? 'admin';

    final appRef = _riderApplications.doc(applicationId);
    final appDoc = await appRef.get();
    if (!appDoc.exists) throw Exception('Application not found.');

    final appData = appDoc.data()!;
    final status = appData['status'] as String? ?? '';
    final riderName = (appData['fullName'] as String? ?? 'Rider').trim();

    if (status != 'pending') {
      throw Exception('Application is already $status.');
    }

    await appRef.update({
      'status': 'rejected',
      'rejectionReason': rejectionReason,
      'rejectedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminUid,
    });

    try {
      await AdminNotificationService.instance.createNotification(
        title: 'Rider Application Rejected',
        body: '$riderName application was rejected.',
        type: 'rider',
        referenceId: applicationId,
      );
    } catch (_) {}
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<List<OrderModel>> fetchReadyOrders() async {
    try {
      final snapshot = await _orders
          .where('status', isEqualTo: 'Ready')
          .limit(20)
          .get();
      final list = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list.take(10).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<OrderModel>> fetchActiveOrders() async {
    try {
      final snapshot = await _orders
          .where('status', whereIn: ['Assigned', 'Collecting', 'Picked Up', 'On the Way'])
          .limit(20)
          .get();
      final list = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(2000);
        final bDate = b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list.take(10).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> approvePharmacy(String applicationId) async {
    final user = FirebaseAuth.instance.currentUser;
    final adminUid = user?.uid ?? 'admin';

    final appDoc = await _pharmacyApplications.doc(applicationId).get();

    if (!appDoc.exists) {
      await _pharmacies.doc(applicationId).update({
        'status': 'Approved',
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

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

    // Send the password creation / reset link email to the pharmacy user
    if (email.isNotEmpty) {
      await _sendPasswordResetEmail(email);
    }

    // Add confirmation notification
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

  Future<String?> _createRiderAuthAndGetUid(String email) async {
    try {
      final secondaryApp = await _getRiderSecondaryApp();
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

  Future<void> _sendRiderPasswordResetEmail(String email) async {
    try {
      final secondaryApp = await _getRiderSecondaryApp();
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      await secondaryAuth.sendPasswordResetEmail(email: email);
      await secondaryAuth.signOut();
    } catch (_) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      } catch (_) {}
    }
  }

  Future<FirebaseApp> _getRiderSecondaryApp() async {
    try {
      return Firebase.app('rider-approval');
    } catch (_) {
      return Firebase.initializeApp(
        name: 'rider-approval',
        options: Firebase.app().options,
      );
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

  Future<void> rejectPharmacy(String applicationId, {String reason = ''}) async {
    final user = FirebaseAuth.instance.currentUser;
    final adminUid = user?.uid ?? 'admin';

    final appRef = _pharmacyApplications.doc(applicationId);
    final appDoc = await appRef.get();
    if (appDoc.exists) {
      final name = appDoc.data()?['pharmacyName'] as String? ?? 'Pharmacy';
      await appRef.update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': adminUid,
      });
      try {
        await AdminNotificationService.instance.createNotification(
          title: 'Pharmacy Application Rejected',
          body: '$name application was rejected.',
          type: 'pharmacy',
          referenceId: applicationId,
        );
      } catch (_) {}
    } else {
      await _pharmacies.doc(applicationId).update({
        'status': 'Rejected',
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> assignOrder(String orderId, String riderId) async {
    await _orders.doc(orderId).update({
      'riderId': riderId,
      'status': 'Assigned',
      'assignedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> autoAssignOrder(String orderId) async {
    final ridersSnapshot = await _riders
        .where('online', isEqualTo: true)
        .where('active', isEqualTo: true)
        .get();

    final candidates = ridersSnapshot.docs.toList();
    if (candidates.isEmpty) {
      throw Exception('No online active riders available');
    }

    final activeStatuses = ['Assigned', 'Collecting', 'Picked Up', 'On the Way'];
    String? bestRiderId;
    int bestLoad = 999;

    for (final riderDoc in candidates) {
      final riderOrders = await _orders
          .where('riderId', isEqualTo: riderDoc.id)
          .get();
      final load = riderOrders.docs
          .where((doc) => activeStatuses.contains(doc.data()['status']))
          .length;

      if (load < bestLoad) {
        bestRiderId = riderDoc.id;
        bestLoad = load;
      }
    }

    if (bestRiderId == null) {
      throw Exception('No suitable rider found for assignment');
    }

    await assignOrder(orderId, bestRiderId);
  }

  Future<int> _getActiveOrderCount() async {
    final snapshot = await _firestore
        .collection('orders')
        .where('status', whereIn: [
          'Assigned',
          'Collecting',
          'Picked Up',
          'On the Way',
        ])
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getCompletedOrderCount() async {
    final snapshot = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'Delivered')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getAverageDeliveryTimeMinutes() async {
    final snapshot = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'Delivered')
        .where('deliveryTimeMinutes', isGreaterThan: 0)
        .orderBy('deliveryTimeMinutes')
        .limit(100)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    int total = 0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['deliveryTimeMinutes'] as int?) ?? 0;
    }
    return total ~/ snapshot.docs.length;
  }

  Future<int> _getOnlineRiderCount() async {
    final snapshot = await _firestore
        .collection('riders')
        .where('online', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getActiveRiderCount() async {
    final snapshot = await _firestore
        .collection('riders')
        .where('active', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getPendingPharmacyCount() async {
    final snapshot = await _firestore
        .collection('pharmacy_applications')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getActivePharmacyCount() async {
    final snapshot = await _firestore
        .collection('pharmacies')
        .where('active', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<int> _getPendingRiderCount() async {
    final snapshot = await _firestore
        .collection('rider_applications')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    return snapshot.count ?? 0;
  }
}
