import 'package:equatable/equatable.dart';

abstract class SubscriptionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}
class SubscriptionLoading extends SubscriptionState {}
class SubscriptionSuccess extends SubscriptionState {}
class SubscriptionFailure extends SubscriptionState {
  final String error;
  SubscriptionFailure(this.error);

  @override
  List<Object?> get props => [error];
}