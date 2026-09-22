import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  EmailService._();
  static final EmailService instance = EmailService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String pharmacyApprovalSubject =
      'Your MedsCarrier Pharmacy Account Has Been Approved!';

  static const String pharmacyApprovalBody =
      'Your pharmacy account has been reviewed and approved by our admin team. '
      'Your account is now active and ready to use. You can log in using your registered '
      'email address and password.\n\n'
      'Welcome to MedsCarrier!';

  static String _buildPharmacyApprovalHtml({String pharmacyName = 'Partner'}) {
    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your MedsCarrier Pharmacy Account Has Been Approved!</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #2D3748; margin: 0; padding: 24px; background-color: #F7FAFC;">
  <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; padding: 32px; border: 1px solid #E2E8F0; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);">
    <div style="margin-bottom: 24px;">
      <h2 style="color: #2E7D32; margin-top: 0; font-size: 22px;">Your MedsCarrier Pharmacy Account Has Been Approved!</h2>
    </div>
    <p style="font-size: 15px; color: #4A5568;">
      Your pharmacy account has been reviewed and approved by our admin team. Your account is now active and ready to use. You can log in using your registered email address and password.
    </p>
    <div style="margin-top: 28px; padding-top: 20px; border-top: 1px solid #EDF2F7;">
      <p style="font-weight: 600; font-size: 16px; color: #1B5E20; margin: 0;">Welcome to MedsCarrier!</p>
    </div>
  </div>
</body>
</html>''';
  }

  /// Sends the pharmacy approval email by queuing it to the Firestore 'mail'
  /// collection (compatible with Firebase Trigger Email extension / Cloud Functions)
  /// and sends an in-app notification to the pharmacy if [uid] is provided.
  Future<void> sendPharmacyApprovalEmail({
    required String email,
    String? pharmacyName,
    String? uid,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return;

    try {
      // 1. Queue to Firestore 'mail' collection (Firebase Trigger Email extension standard)
      await _firestore.collection('mail').add({
        'to': [normalizedEmail],
        'message': {
          'subject': pharmacyApprovalSubject,
          'text': pharmacyApprovalBody,
          'html': _buildPharmacyApprovalHtml(
            pharmacyName: pharmacyName ?? 'Partner',
          ),
        },
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        if (uid != null && uid.isNotEmpty) 'pharmacyId': uid,
      });
      developer.log(
        'Queued approval email to $normalizedEmail',
        name: 'EmailService',
      );
    } catch (e) {
      developer.log(
        'Failed to queue approval email: $e',
        name: 'EmailService',
      );
    }

    // 2. Deliver in-app notification to pharmacy notifications subcollection
    if (uid != null && uid.isNotEmpty) {
      try {
        await _firestore
            .collection('pharmacies')
            .doc(uid)
            .collection('notifications')
            .add({
          'title': pharmacyApprovalSubject,
          'body': pharmacyApprovalBody,
          'type': 'account_approved',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      } catch (e) {
        developer.log(
          'Failed to add in-app notification: $e',
          name: 'EmailService',
        );
      }
    }
  }

  static const String riderApprovalSubject =
      'Your MedsCarrier Rider Account Has Been Approved!';

  static const String riderApprovalBody =
      'Your rider account has been reviewed and approved by our admin team. '
      'Your account is now active and ready to use. You can log in to the '
      'MedsCarrier Rider App using your registered email address and password.\n\n'
      'Welcome to the MedsCarrier team!';

  static String _buildRiderApprovalHtml({String riderName = 'Rider'}) {
    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your MedsCarrier Rider Account Has Been Approved!</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #2D3748; margin: 0; padding: 24px; background-color: #F7FAFC;">
  <div style="max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; padding: 32px; border: 1px solid #E2E8F0; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);">
    <div style="margin-bottom: 24px;">
      <h2 style="color: #2E7D32; margin-top: 0; font-size: 22px;">Your MedsCarrier Rider Account Has Been Approved!</h2>
    </div>
    <p style="font-size: 15px; color: #4A5568;">
      Your rider account has been reviewed and approved by our admin team. Your account is now active and ready to use. You can log in to the MedsCarrier Rider App using your registered email address and password.
    </p>
    <div style="margin-top: 28px; padding-top: 20px; border-top: 1px solid #EDF2F7;">
      <p style="font-weight: 600; font-size: 16px; color: #1B5E20; margin: 0;">Welcome to the MedsCarrier team!</p>
    </div>
  </div>
</body>
</html>''';
  }

  /// Sends the rider approval email by queuing it to the Firestore 'mail'
  /// collection (compatible with Firebase Trigger Email extension / Cloud Functions)
  /// and sends an in-app notification to the rider if [uid] is provided.
  Future<void> sendRiderApprovalEmail({
    required String email,
    String? riderName,
    String? uid,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return;

    try {
      // 1. Queue to Firestore 'mail' collection
      await _firestore.collection('mail').add({
        'to': [normalizedEmail],
        'message': {
          'subject': riderApprovalSubject,
          'text': riderApprovalBody,
          'html': _buildRiderApprovalHtml(
            riderName: riderName ?? 'Rider',
          ),
        },
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        if (uid != null && uid.isNotEmpty) 'riderId': uid,
      });
      developer.log(
        'Queued rider approval email to $normalizedEmail',
        name: 'EmailService',
      );
    } catch (e) {
      developer.log(
        'Failed to queue rider approval email: $e',
        name: 'EmailService',
      );
    }

    // 2. Deliver in-app notification to rider notifications subcollection
    if (uid != null && uid.isNotEmpty) {
      try {
        await _firestore
            .collection('riders')
            .doc(uid)
            .collection('notifications')
            .add({
          'title': riderApprovalSubject,
          'body': riderApprovalBody,
          'type': 'account_approved',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      } catch (e) {
        developer.log(
          'Failed to add rider in-app notification: $e',
          name: 'EmailService',
        );
      }
    }
  }
}
