import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String plan;
  final String status;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;

  const SubscriptionModel({
    required this.plan,
    required this.status,
    this.trialStartDate,
    this.trialEndDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'plan': plan,
      'status': status,
      'trialStartDate': trialStartDate != null
          ? Timestamp.fromDate(trialStartDate!)
          : null,
      'trialEndDate': trialEndDate != null
          ? Timestamp.fromDate(trialEndDate!)
          : null,
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      plan: map['plan'] as String? ?? 'free',
      status: map['status'] as String? ?? 'inactive',
      trialStartDate: _timestampToDate(map['trialStartDate']),
      trialEndDate: _timestampToDate(map['trialEndDate']),
    );
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  bool get isTrialActive {
    if (plan != 'trial' || status != 'active') {
      return false;
    }

    if (trialEndDate == null) {
      return false;
    }

    return DateTime.now().isBefore(trialEndDate!);
  }

  bool get isTrialExpired {
    if (trialEndDate == null) {
      return false;
    }

    return DateTime.now().isAfter(trialEndDate!);
  }
}