import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/subscription_service.dart';
import '../../models/subscription_model.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc
    extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc() : super(const SubscriptionInitial()) {
    on<StartTrialEvent>(_onStartTrial);
    on<CheckSubscriptionEvent>(_onCheckSubscription);
  }

  // =========================
  // Start Free Trial
  // =========================
  Future<void> _onStartTrial(
      StartTrialEvent event,
      Emitter<SubscriptionState> emit,
      ) async {
    emit(const SubscriptionLoading());

    try {
      await SubscriptionService.instance.startFreeTrial(
        userId: event.userId,
        email: event.email,
      );

      emit(const SubscriptionSuccess());
    } catch (e) {
      emit(
        SubscriptionFailure(
          _errorMessage(e),
        ),
      );
    }
  }

  // =========================
  // Check Subscription
  // =========================
  Future<void> _onCheckSubscription(
      CheckSubscriptionEvent event,
      Emitter<SubscriptionState> emit,
      ) async {
    emit(const SubscriptionLoading());

    try {
      final SubscriptionModel? subscription =
      await SubscriptionService.instance.getSubscription(
        event.userId,
      );

      if (subscription == null) {
        emit(const SubscriptionNotFound());
        return;
      }

      if (subscription.isTrialActive) {
        emit(SubscriptionActive(subscription));
      } else {
        emit(SubscriptionExpired(subscription));
      }
    } catch (e) {
      emit(
        SubscriptionFailure(
          _errorMessage(e),
        ),
      );
    }
  }

  String _errorMessage(Object error) {
    return 'Unable to process your subscription. Please try again.';
  }
}