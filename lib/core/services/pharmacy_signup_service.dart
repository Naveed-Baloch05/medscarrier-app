import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'admin_notification_service.dart';
import '../../models/pharmacy_application_model.dart';

class PharmacySignupService {
  PharmacySignupService._();
  static final PharmacySignupService instance = PharmacySignupService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('pharmacy_applications');

  Future<bool> emailExists(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final appQuery = await _applications
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();
      return appQuery.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<PharmacyApplicationModel> submitApplication({
    required String pharmacyName,
    required String contactName,
    required String email,
    required String phone,
    required String businessAddress,
    double? latitude,
    double? longitude,
    required String gphcNumber,
    required String password,
    File? licenseDocument,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final duplicate = await emailExists(normalizedEmail);
    if (duplicate) {
      throw Exception(
        'An application with this email already exists.',
      );
    }

    String? uid;

    try {
      // 1. Authenticate user via main FirebaseAuth instance so Firestore and Storage rules have valid permission
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        uid = cred.user?.uid;
      } on FirebaseAuthException catch (fae) {
        if (fae.code == 'email-already-in-use') {
          throw Exception('An account with this email already exists.');
        } else if (fae.code == 'weak-password') {
          throw Exception('The password is too weak. Please use at least 6 characters.');
        } else if (fae.code == 'invalid-email') {
          throw Exception('Please enter a valid email address.');
        } else {
          throw Exception(fae.message ?? 'Signup failed: ${fae.code}');
        }
      }

      final appRef = _applications.doc();
      final applicationId = appRef.id;

      // 2. Upload license document while authenticated
      String? docUrl;
      if (licenseDocument != null) {
        try {
          docUrl = await _uploadFile(
            path: 'pharmacy_applications/$applicationId/license_document.jpg',
            file: licenseDocument,
          );
        } catch (_) {}
      }

      // 3. Write application document
      final applicationData = <String, dynamic>{
        'applicationId': applicationId,
        'uid': uid ?? applicationId,
        'pharmacyName': pharmacyName.trim(),
        'contactName': contactName.trim(),
        'email': normalizedEmail,
        'phone': phone.trim(),
        'businessAddress': businessAddress.trim(),
        if (latitude != null && longitude != null)
          'location': GeoPoint(latitude, longitude),
        'gphcNumber': gphcNumber.trim(),
        if (docUrl != null) 'licenseDocumentUrl': docUrl,
        'status': 'pending',
        'accountCreated': false,
        'submittedAt': FieldValue.serverTimestamp(),
      };

      await appRef.set(applicationData);

      // 4. Also prepare pending user and pharmacy records if uid is available
      if (uid != null && uid.isNotEmpty) {
        try {
          await _firestore.collection('users').doc(uid).set({
            'id': uid,
            'uid': uid,
            'email': normalizedEmail,
            'role': 'pharmacy',
            'accountStatus': 'pending',
            'name': contactName.trim(),
            'pharmacyName': pharmacyName.trim(),
            'phone': phone.trim(),
            'businessAddress': businessAddress.trim(),
            if (latitude != null && longitude != null)
              'location': GeoPoint(latitude, longitude),
            'gphcNumber': gphcNumber.trim(),
            if (docUrl != null) 'licenseDocumentUrl': docUrl,
            'applicationId': applicationId,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          await _firestore.collection('pharmacies').doc(uid).set({
            'id': uid,
            'uid': uid,
            'pharmacyName': pharmacyName.trim(),
            'contactName': contactName.trim(),
            'email': normalizedEmail,
            'phone': phone.trim(),
            'businessAddress': businessAddress.trim(),
            if (latitude != null && longitude != null)
              'location': GeoPoint(latitude, longitude),
            'gphcNumber': gphcNumber.trim(),
            if (docUrl != null) 'licenseDocumentUrl': docUrl,
            'status': 'Pending',
            'active': false,
            'applicationId': applicationId,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      // 5. Create an immediate notification for Admin
      try {
        await AdminNotificationService.instance.createNotification(
          title: 'New Pharmacy Application',
          body: '${pharmacyName.trim()} has submitted an application for approval.',
          type: 'pharmacy',
          referenceId: applicationId,
        );
      } catch (_) {}

      final snapshot = await appRef.get();
      if (snapshot.exists) {
        return PharmacyApplicationModel.fromFirestore(snapshot);
      } else {
        return PharmacyApplicationModel(
          applicationId: applicationId,
          uid: uid ?? applicationId,
          pharmacyName: pharmacyName.trim(),
          contactName: contactName.trim(),
          email: normalizedEmail,
          phone: phone.trim(),
          businessAddress: businessAddress.trim(),
          gphcNumber: gphcNumber.trim(),
          licenseDocumentUrl: docUrl,
          status: 'pending',
          submittedAt: DateTime.now(),
        );
      }
    } finally {
      // 6. Always sign out at the end so the user cannot enter without admin approval
      try {
        await _auth.signOut();
      } catch (_) {}
    }
  }

  Future<String> _uploadFile({
    required String path,
    required File file,
  }) async {
    if (!file.existsSync()) {
      throw Exception('File does not exist: ${file.path}');
    }

    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    await uploadTask;

    final url = await ref.getDownloadURL();
    if (url.isEmpty) {
      throw Exception('Upload succeeded but download URL is empty.');
    }
    return url;
  }
}
