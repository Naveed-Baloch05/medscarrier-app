import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PharmacyProfileService {
  PharmacyProfileService._();
  static final PharmacyProfileService instance =
      PharmacyProfileService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> _pharmacyDoc(String uid) =>
      _firestore.collection('pharmacies').doc(uid);

  Future<Map<String, dynamic>> getProfile(String uid) async {
    final doc = await _pharmacyDoc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return {'uid': uid};
    }
    return {'uid': uid, ...doc.data()!};
  }

  Future<void> updateProfile({
    required String uid,
    required String pharmacyName,
    required String contactName,
    required String phone,
    required String email,
    required String businessAddress,
    required String gphcNumber,
    String? openingTime,
    String? closingTime,
    bool? notificationsEnabled,
  }) async {
    final data = <String, dynamic>{
      'pharmacyName': pharmacyName,
      'contactName': contactName,
      'phone': phone,
      'email': email,
      'businessAddress': businessAddress,
      'gphcNumber': gphcNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (openingTime != null) data['openingTime'] = openingTime;
    if (closingTime != null) data['closingTime'] = closingTime;
    if (notificationsEnabled != null) {
      data['notificationsEnabled'] = notificationsEnabled;
    }

    await _pharmacyDoc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> togglePharmacyOpen({
    required String uid,
    required bool isOpen,
  }) async {
    await _pharmacyDoc(uid).set({
      'active': isOpen,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required File imageFile,
  }) async {
    final ref = _storage.ref().child('pharmacy_profiles/$uid/profile.jpg');
    await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final url = await ref.getDownloadURL();
    await _pharmacyDoc(uid).set({
      'profilePhotoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return url;
  }

  Future<void> removeProfilePhoto(String uid) async {
    try {
      await _storage.ref().child('pharmacy_profiles/$uid/profile.jpg').delete();
    } catch (_) {}
    await _pharmacyDoc(uid).set({
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
}
