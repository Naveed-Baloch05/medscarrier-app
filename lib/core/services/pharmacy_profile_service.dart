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
    final docPath = 'pharmacies/$uid';
    final doc = await _pharmacyDoc(uid).get();
    // ignore: avoid_print
    print('[PROFILE-DEBUG] authUid=${_auth.currentUser?.uid} pharmacyId=$uid '
        'doc=$docPath exists=${doc.exists} hasData=${doc.data() != null}');
    final data = (doc.exists && doc.data() != null)
        ? {'uid': uid, ...doc.data()!}
        : {'uid': uid};

    // If pharmacyCode is missing on the pharmacies document (e.g. a pharmacy
    // created before pharmacyCode was written to pharmacies/{uid}), reuse the
    // existing pharmacyCode stored elsewhere in Firebase. Never generate one.
    final code = (data['pharmacyCode'] as String? ?? '').trim();
    // ignore: avoid_print
    print('[PROFILE-DEBUG] pharmacies.pharmacyCode=${code.isEmpty ? '<missing>' : code}');
    if (code.isEmpty) {
      final fallbackCode = await _findExistingPharmacyCode(uid);
      // ignore: avoid_print
      print('[PROFILE-DEBUG] fallback pharmacyCode=${fallbackCode.isEmpty ? '<missing>' : fallbackCode}');
      if (fallbackCode.isNotEmpty) {
        data['pharmacyCode'] = fallbackCode;
      }
    }

    return data;
  }

  /// Reads an existing pharmacyCode from `users/{uid}` and then from the
  /// matching `pharmacy_applications` document (by uid). Reuses the value the
  /// registration flow already stored; never generates a new code.
  Future<String> _findExistingPharmacyCode(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final code = (userDoc.data()!['pharmacyCode'] as String? ?? '').trim();
        if (code.isNotEmpty) return code;
      }
    } catch (_) {}

    try {
      final appQuery = await _firestore
          .collection('pharmacy_applications')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (appQuery.docs.isNotEmpty) {
        final code =
            (appQuery.docs.first.data()['pharmacyCode'] as String? ?? '').trim();
        if (code.isNotEmpty) return code;
      }
    } catch (_) {}

    return '';
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
