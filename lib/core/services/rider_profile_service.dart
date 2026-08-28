import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RiderProfileService {
  RiderProfileService._();
  static final RiderProfileService instance = RiderProfileService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> _riderDoc(String riderId) =>
      _firestore.collection('riders').doc(riderId);

  Future<DocumentReference<Map<String, dynamic>>> _resolveRiderDoc(
      String riderId) async {
    final directDoc = await _riderDoc(riderId).get();
    if (directDoc.exists) return _riderDoc(riderId);

    DocumentSnapshot<Map<String, dynamic>>? doc;
    final uidQuery = await _firestore
        .collection('riders')
        .where('uid', isEqualTo: riderId)
        .limit(1)
        .get();
    if (uidQuery.docs.isNotEmpty) {
      doc = uidQuery.docs.first;
    }
    if (doc == null) {
      final idQuery = await _firestore
          .collection('riders')
          .where('id', isEqualTo: riderId)
          .limit(1)
          .get();
      if (idQuery.docs.isNotEmpty) {
        doc = idQuery.docs.first;
      }
    }

    if (doc != null) return doc.reference;

    // Fallback: the doc doesn't exist anywhere; use the passed id directly so
    // a new/merged write still lands under a predictable key.
    return _riderDoc(riderId);
  }

  Future<Map<String, dynamic>> getProfile(String riderId) async {
    final directDoc = await _riderDoc(riderId).get();
    if (directDoc.exists && directDoc.data() != null) {
      return {'id': riderId, ...directDoc.data()!};
    }

    // Fallback lookups by uid / id / email
    DocumentSnapshot<Map<String, dynamic>>? doc;
    final uidQuery = await _firestore
        .collection('riders')
        .where('uid', isEqualTo: riderId)
        .limit(1)
        .get();
    if (uidQuery.docs.isNotEmpty) {
      doc = uidQuery.docs.first;
    }
    if (doc == null) {
      final idQuery = await _firestore
          .collection('riders')
          .where('id', isEqualTo: riderId)
          .limit(1)
          .get();
      if (idQuery.docs.isNotEmpty) {
        doc = idQuery.docs.first;
      }
    }

    if (doc != null && doc.data() != null) {
      return {if (doc.id.isNotEmpty) 'id': doc.id, ...doc.data()!};
    }
    return {'id': riderId};
  }

  Future<void> updateProfile({
    required String riderId,
    required String fullName,
    required String phone,
    required String email,
    required String vehicleType,
    required String vehicleReg,
    bool? notificationsEnabled,
  }) async {
    final ref = await _resolveRiderDoc(riderId);
    final data = <String, dynamic>{
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'vehicleType': vehicleType,
      'vehicleReg': vehicleReg,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (notificationsEnabled != null) {
      data['notificationsEnabled'] = notificationsEnabled;
    }

    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> toggleAvailability({
    required String riderId,
    required bool isOnline,
  }) async {
    final ref = await _resolveRiderDoc(riderId);
    await ref.set({
      'online': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> uploadProfilePhoto({
    required String riderId,
    required File imageFile,
  }) async {
    final ref = await _resolveRiderDoc(riderId);
    final photoRef = _storage.ref().child('rider_profiles/$riderId/profile.jpg');
    await photoRef.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await photoRef.getDownloadURL();
    await ref.set({
      'profilePhotoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return url;
  }

  Future<void> removeProfilePhoto(String riderId) async {
    final ref = await _resolveRiderDoc(riderId);
    try {
      await _storage
          .ref()
          .child('rider_profiles/$riderId/profile.jpg')
          .delete();
    } catch (_) {}
    await ref.set({
      'profilePhotoUrl': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No authenticated user found.');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
