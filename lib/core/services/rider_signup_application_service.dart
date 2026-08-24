import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../constants/cloud_functions_config.dart';
import '../../models/rider_application_model.dart';

class RiderSignupApplicationService {
  RiderSignupApplicationService._();
  static final RiderSignupApplicationService instance =
      RiderSignupApplicationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('rider_applications');

  Future<RiderApplicationModel> submitApplication({
    required String fullName,
    required String email,
    required String phone,
    required String vehicleType,
    required String vehicleReg,
    required String password,
  }) async {
    final url = Uri.parse(
      '${CloudFunctionsConfig.baseUrl}/submitRiderApplication',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'vehicleType': vehicleType,
        'vehicleRegistrationNumber': vehicleReg,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'] as String? ?? 'Submission failed.';
      throw Exception(error);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final applicationId = body['applicationId'] as String;

    final doc = await _applications.doc(applicationId).get();
    return RiderApplicationModel.fromFirestore(doc);
  }
}
