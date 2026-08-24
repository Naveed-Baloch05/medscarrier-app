import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/pharmacy_application_model.dart';

class PharmacySignupService {
  PharmacySignupService._();
  static final PharmacySignupService instance = PharmacySignupService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('pharmacy_applications');

  Future<bool> emailExists(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final appQuery = await _applications
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    return appQuery.docs.isNotEmpty;
  }

  Future<PharmacyApplicationModel> submitApplication({
    required String pharmacyName,
    required String contactName,
    required String email,
    required String phone,
    required String businessAddress,
    required String gphcNumber,
    File? licenseDocument,
  }) async {
    final duplicate = await emailExists(email);
    if (duplicate) {
      throw Exception(
        'An application with this email already exists.',
      );
    }

    final appRef = _applications.doc();
    final applicationId = appRef.id;

    await appRef.set({
      'applicationId': applicationId,
      'pharmacyName': pharmacyName.trim(),
      'contactName': contactName.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'businessAddress': businessAddress.trim(),
      'gphcNumber': gphcNumber.trim(),
      'status': 'pending',
      'accountCreated': false,
      'submittedAt': FieldValue.serverTimestamp(),
    });

    if (licenseDocument != null) {
      final docUrl = await _uploadFile(
        path: 'pharmacy_applications/$applicationId/license_document.jpg',
        file: licenseDocument,
      );
      await _applications.doc(applicationId).update({
        'licenseDocumentUrl': docUrl,
      });
    }

    final updatedDoc = await _applications.doc(applicationId).get();
    return PharmacyApplicationModel.fromFirestore(updatedDoc);
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
