import 'package:equatable/equatable.dart';

import '../../core/services/rider_map_service.dart';

abstract class RiderMapState extends Equatable {
  const RiderMapState();

  @override
  List<Object?> get props => [];
}

class RiderMapInitial extends RiderMapState {
  const RiderMapInitial();
}

class RiderMapLoading extends RiderMapState {
  const RiderMapLoading();
}

class RiderMapLoaded extends RiderMapState {
  const RiderMapLoaded(this.session);

  final RiderMapSession session;

  bool get isArrived => session.isArrived;

  bool get isCompleted => session.order.isCompleted;

  @override
  List<Object?> get props => [session];
}

class RiderMapUpdating extends RiderMapState {
  const RiderMapUpdating(this.session);

  final RiderMapSession session;

  @override
  List<Object?> get props => [session];
}

class RiderMapOperationSuccess extends RiderMapState {
  const RiderMapOperationSuccess({
    required this.message,
    required this.session,
  });

  final String message;
  final RiderMapSession session;

  @override
  List<Object?> get props => [message, session];
}

class RiderMapError extends RiderMapState {
  const RiderMapError({
    required this.message,
    this.session,
  });

  final String message;
  final RiderMapSession? session;

  @override
  List<Object?> get props => [message, session];
}
