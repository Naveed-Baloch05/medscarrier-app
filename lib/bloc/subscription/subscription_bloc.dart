import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  SubscriptionBloc() : super(SubscriptionInitial()) {
    on<StartTrialEvent>(_onStartTrial);
  }

  Future<void> _onStartTrial(
    StartTrialEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 14));

      await _firestore.collection('users').doc(event.userId).set({
        'email': event.email,
        'plan': 'trial',
        'status': 'active',
        'trialStartDate': Timestamp.fromDate(now),
        'trialEndDate': Timestamp.fromDate(endDate),
      }, SetOptions(merge: true));

      emit(SubscriptionSuccess());
    } catch (e) {
      emit(SubscriptionFailure(e.toString()));
    }
  }
}