import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'admin_notification_service.dart';
import '../../models/rider_application_model.dart';

class RiderSignupService {
  RiderSignupService._();
  static final RiderSignupService instance = RiderSignupService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('rider_applications');

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

  Future<RiderApplicationModel> submitApplication({
    required String fullName,
    required String email,
    required String phone,
    required String vehicleType,
    required String vehicleReg,
    required String password,
    File? licenseFront,
    File? licenseBack,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final duplicate = await emailExists(normalizedEmail);
    if (duplicate) {
      throw Exception('An application with this email already exists.');
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

      // 2. Upload licence documents while authenticated
      String? frontUrl;
      if (licenseFront != null) {
        try {
          frontUrl = await _uploadFile(
            path: 'rider_applications/$applicationId/license_front.jpg',
            file: licenseFront,
          );
        } catch (_) {}
      }

      String? backUrl;
      if (licenseBack != null) {
        try {
          backUrl = await _uploadFile(
            path: 'rider_applications/$applicationId/license_back.jpg',
            file: licenseBack,
          );
        } catch (_) {}
      }

      // 3. Write application document
      final applicationData = <String, dynamic>{
        'applicationId': applicationId,
        'uid': uid ?? applicationId,
        'fullName': fullName.trim(),
        'email': normalizedEmail,
        'phone': phone.trim(),
        'vehicleType': vehicleType,
        'vehicleRegistrationNumber': vehicleReg.trim(),
        if (frontUrl != null) 'drivingLicenceFrontUrl': frontUrl,
        if (backUrl != null) 'drivingLicenceBackUrl': backUrl,
        'termsAccepted': true,
        'rightToWorkConsent': true,
        'backgroundCheckConsent': true,
        'status': 'pending',
        'accountCreated': false,
        'submittedAt': FieldValue.serverTimestamp(),
      };

      await appRef.set(applicationData);

      // 4. Also prepare pending user and rider records if uid is available
      if (uid != null && uid.isNotEmpty) {
        try {
          await _firestore.collection('users').doc(uid).set({
            'id': uid,
            'uid': uid,
            'email': normalizedEmail,
            'role': 'rider',
            'accountStatus': 'pending',
            'name': fullName.trim(),
            'phone': phone.trim(),
            'vehicleType': vehicleType,
            'vehicleRegistrationNumber': vehicleReg.trim(),
            if (frontUrl != null) 'drivingLicenceFrontUrl': frontUrl,
            if (backUrl != null) 'drivingLicenceBackUrl': backUrl,
            'applicationId': applicationId,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          await _firestore.collection('riders').doc(uid).set({
            'id': uid,
            'uid': uid,
            'fullName': fullName.trim(),
            'email': normalizedEmail,
            'phone': phone.trim(),
            'vehicleType': vehicleType,
            'vehicleReg': vehicleReg.trim(),
            'status': 'Pending',
            'active': false,
            'online': false,
            'deliveries': 0,
            'location': 'Location unavailable',
            'applicationId': applicationId,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      // 5. Create notification for Admin
      try {
        await AdminNotificationService.instance.createNotification(
          title: 'New Rider Application',
          body: '${fullName.trim()} has submitted a rider application for approval.',
          type: 'rider',
          referenceId: applicationId,
        );
      } catch (_) {}

      final snapshot = await appRef.get();
      if (snapshot.exists) {
        return RiderApplicationModel.fromFirestore(snapshot);
      } else {
        return RiderApplicationModel(
          applicationId: applicationId,
          uid: uid ?? applicationId,
          fullName: fullName.trim(),
          email: normalizedEmail,
          phone: phone.trim(),
          vehicleType: vehicleType,
          vehicleRegistrationNumber: vehicleReg.trim(),
          drivingLicenceFrontUrl: frontUrl,
          drivingLicenceBackUrl: backUrl,
          termsAccepted: true,
          rightToWorkConsent: true,
          backgroundCheckConsent: true,
          status: 'pending',
          submittedAt: DateTime.now(),
        );
      }
    } finally {
      // 6. Always sign out at the end so the user cannot bypass approval
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
