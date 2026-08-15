import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/subscription_model.dart';

class SubscriptionService {
  SubscriptionService._();

  static final SubscriptionService instance = SubscriptionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================
  // Start Free Trial
  // =========================
  Future<void> startFreeTrial({
    required String userId,
    required String email,
  }) async {
    final DateTime trialStartDate = DateTime.now();

    final DateTime trialEndDate = trialStartDate.add(
      const Duration(days: 14),
    );

    await _firestore.collection('users').doc(userId).set(
      {
        'email': email,
        'plan': 'trial',
        'status': 'active',
        'trialStartDate': Timestamp.fromDate(trialStartDate),
        'trialEndDate': Timestamp.fromDate(trialEndDate),
      },
      SetOptions(merge: true),
    );
  }

  // =========================
  // Get Subscription
  // =========================
  Future<SubscriptionModel?> getSubscription(String userId) async {
    final document = await _firestore
        .collection('users')
        .doc(userId)
        .get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    final data = document.data()!;

    // User has no subscription information yet.
    if (!data.containsKey('plan') ||
        !data.containsKey('status')) {
      return null;
    }

    return SubscriptionModel.fromMap(data);
  }

  // =========================
  // Check Active Trial
  // =========================
  Future<bool> hasActiveTrial(String userId) async {
    final subscription = await getSubscription(userId);

    if (subscription == null) {
      return false;
    }

    return subscription.isTrialActive;
  }
}