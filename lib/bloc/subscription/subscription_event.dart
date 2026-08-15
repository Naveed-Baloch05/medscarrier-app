import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

// Start the user's 14-day free trial.
class StartTrialEvent extends SubscriptionEvent {
  const StartTrialEvent({
    required this.userId,
    required this.email,
  });

  final String userId;
  final String email;

  @override
  List<Object?> get props => [userId, email];
}

// Check whether the user already has an active subscription/trial.
class CheckSubscriptionEvent extends SubscriptionEvent {
  const CheckSubscriptionEvent({
    required this.userId,
  });

  final String userId;

  @override
  List<Object?> get props => [userId];
}