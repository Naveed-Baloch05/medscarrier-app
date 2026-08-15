import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String plan;
  final String status;
  final DateTime trialStartDate;
  final DateTime trialEndDate;

  SubscriptionModel({
    required this.plan,
    required this.status,
    required this.trialStartDate,
    required this.trialEndDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'plan': plan,
      'status': status,
      'trialStartDate': Timestamp.fromDate(trialStartDate),
      'trialEndDate': Timestamp.fromDate(trialEndDate),
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      plan: map['plan'] ?? 'free',
      status: map['status'] ?? 'active',
      trialStartDate: (map['trialStartDate'] as Timestamp).toDate(),
      trialEndDate: (map['trialEndDate'] as Timestamp).toDate(),
    );
  }
}