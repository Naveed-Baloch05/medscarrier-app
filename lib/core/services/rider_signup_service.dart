import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/rider_application_model.dart';

class RiderSignupService {
  RiderSignupService._();
  static final RiderSignupService instance = RiderSignupService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('rider_applications');

  Future<bool> emailExists(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    final appQuery = await _applications
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    return appQuery.docs.isNotEmpty;
  }

  Future<RiderApplicationModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String vehicleType,
    required String vehicleReg,
    required String password,
    File? profilePhoto,
    File? drivingLicenceFront,
    File? drivingLicenceBack,
  }) async {
    final duplicate = await emailExists(email);
    if (duplicate) {
      throw Exception(
        'An application or account with this email already exists.',
      );
    }

    UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('An account with this email already exists.');
      }
      throw Exception('Failed to create account. Please try again.');
    }

    final uid = credential.user!.uid;

    final appRef = _applications.doc();
    final applicationId = appRef.id;

    await appRef.set({
      'applicationId': applicationId,
      'uid': uid,
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'vehicleType': vehicleType,
      'vehicleRegistrationNumber': vehicleReg.trim(),
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
      'termsAccepted': true,
      'rightToWorkConsent': true,
      'backgroundCheckConsent': true,
    });

    final Map<String, dynamic> updates = {};

    if (profilePhoto != null) {
      final photoUrl = await _uploadFile(
        path: 'rider_applications/$applicationId/profile_photo.jpg',
        file: profilePhoto,
      );
      updates['profilePhotoUrl'] = photoUrl;
    }

    if (drivingLicenceFront != null) {
      final frontUrl = await _uploadFile(
        path: 'rider_applications/$applicationId/driving_licence_front.jpg',
        file: drivingLicenceFront,
      );
      updates['drivingLicenceFrontUrl'] = frontUrl;
    }

    if (drivingLicenceBack != null) {
      final backUrl = await _uploadFile(
        path: 'rider_applications/$applicationId/driving_licence_back.jpg',
        file: drivingLicenceBack,
      );
      updates['drivingLicenceBackUrl'] = backUrl;
    }

    if (updates.isNotEmpty) {
      await _applications.doc(applicationId).update(updates);
    }

    await _auth.signOut();

    final updatedDoc = await _applications.doc(applicationId).get();
    return RiderApplicationModel.fromFirestore(updatedDoc);
  }

  Future<String> _uploadFile({
    required String path,
    required File file,
  }) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
