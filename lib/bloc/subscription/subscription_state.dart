import 'package:equatable/equatable.dart';

import '../../models/subscription_model.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

// Initial state.
class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

// Loading state while communicating with Firebase.
class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

// Trial successfully started.
class SubscriptionSuccess extends SubscriptionState {
  const SubscriptionSuccess();
}

// No subscription/trial information exists.
class SubscriptionNotFound extends SubscriptionState {
  const SubscriptionNotFound();
}

// User has an active trial/subscription.
class SubscriptionActive extends SubscriptionState {
  const SubscriptionActive(this.subscription);

  final SubscriptionModel subscription;

  @override
  List<Object?> get props => [subscription];
}

// User's trial/subscription has expired.
class SubscriptionExpired extends SubscriptionState {
  const SubscriptionExpired(this.subscription);

  final SubscriptionModel subscription;

  @override
  List<Object?> get props => [subscription];
}

// Something went wrong.
class SubscriptionFailure extends SubscriptionState {
  const SubscriptionFailure(this.error);

  final String error;

  @override
  List<Object?> get props => [error];
}