import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartTrialEvent extends SubscriptionEvent {
  final String userId;
  final String email;

  StartTrialEvent({required this.userId, required this.email});

  @override
  List<Object?> get props => [userId, email];
}