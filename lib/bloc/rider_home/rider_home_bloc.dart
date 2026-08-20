import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/rider_home_service.dart';
import 'rider_home_event.dart';
import 'rider_home_state.dart';

class RiderHomeBloc extends Bloc<RiderHomeEvent, RiderHomeState> {
  RiderHomeBloc({RiderHomeService? service})
      : _service = service ?? RiderHomeService.instance,
        super(const RiderHomeInitial()) {
    on<LoadRiderHome>(_onLoaded);
    on<RiderHomeRefreshed>(_onRefreshed);
  }

  final RiderHomeService _service;

  Future<void> _onLoaded(
    LoadRiderHome event,
    Emitter<RiderHomeState> emit,
  ) async {
    emit(const RiderHomeLoading());

    try {
      final rider = await _service.getRider('rider_1');

      if (rider == null) {
        emit(const RiderHomeError('Rider profile not found.'));
        return;
      }

      emit(RiderHomeLoaded(
        rider: rider,
        todayDeliveries: 8,
        completedDeliveries: 5,
        pendingDeliveries: 3,
        totalEarnings: 47.50,
      ));
    } catch (error) {
      emit(RiderHomeError(
        error.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onRefreshed(
    RiderHomeRefreshed event,
    Emitter<RiderHomeState> emit,
  ) async {
    add(const LoadRiderHome());
  }
}
