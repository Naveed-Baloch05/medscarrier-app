import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../models/pharmacy_application_model.dart';

class AdminPharmacyService {
  AdminPharmacyService._();
  static final AdminPharmacyService instance = AdminPharmacyService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _backendBaseUrl = 'http://10.0.2.2:3000';

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
          await _pharmacies.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch pharmacies: $e');
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
    return _pharmacies.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList(),
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

  Future<List<PharmacyApplicationModel>>
      getPendingPharmacyApplications() async {
    try {
      final snapshot = await _pharmacyApplications
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return PharmacyApplicationModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch pharmacy applications: $e');
    }
  }

  Future<void> approvePharmacyApplication(String applicationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated.');

    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse(
        '$_backendBaseUrl/admin/pharmacy-applications/$applicationId/approve',
      ),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to approve application.');
    }
  }

  Future<void> rejectPharmacyApplication(
    String applicationId, {
    String rejectionReason = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not authenticated.');

    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse(
        '$_backendBaseUrl/admin/pharmacy-applications/$applicationId/reject',
      ),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (rejectionReason.isNotEmpty) 'rejectionReason': rejectionReason,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to reject application.');
    }
  }
}
