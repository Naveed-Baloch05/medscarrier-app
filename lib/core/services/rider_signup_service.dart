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
    UserCredential credential;

    // 1. Create Auth user
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('An account with this email already exists.');
      }
      throw Exception(e.message ?? 'Failed to create account. Please try again.');
    }

    final uid = credential.user!.uid;

    try {
      // 2. Upload files while user IS authenticated
      String? profilePhotoUrl;
      String? licenceFrontUrl;
      String? licenceBackUrl;

      if (profilePhoto != null) {
        profilePhotoUrl = await _uploadFile(
          path: 'rider_applications/$uid/profile_photo.jpg',
          file: profilePhoto,
        );
      }

      if (drivingLicenceFront != null) {
        licenceFrontUrl = await _uploadFile(
          path: 'rider_applications/$uid/driving_licence_front.jpg',
          file: drivingLicenceFront,
        );
      }

      if (drivingLicenceBack != null) {
        licenceBackUrl = await _uploadFile(
          path: 'rider_applications/$uid/driving_licence_back.jpg',
          file: drivingLicenceBack,
        );
      }

      // 3. Prepare application data (Document ID and uid field MUST match)
      final applicationData = <String, dynamic>{
        'applicationId': uid,
        'uid': uid,
        'fullName': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'vehicleType': vehicleType,
        'vehicleRegistrationNumber': vehicleReg.trim(),
        'profilePhotoUrl': profilePhotoUrl,
        'drivingLicenceFrontUrl': licenceFrontUrl,
        'drivingLicenceBackUrl': licenceBackUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'termsAccepted': true,
        'rightToWorkConsent': true,
        'backgroundCheckConsent': true,
      };

      // 4. Save to Firestore under doc(uid) to satisfy security rules
      final docRef = _applications.doc(uid);
      await docRef.set(applicationData);

      // 5. Read back document and sign out user
      final docSnapshot = await docRef.get();
      await _auth.signOut();

      return RiderApplicationModel.fromFirestore(docSnapshot);
    } catch (e) {
      // Rollback: delete Auth user if document creation or file upload fails
      await credential.user?.delete();
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<String> _uploadFile({
    required String path,
    required File file,
  }) async {
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }
}