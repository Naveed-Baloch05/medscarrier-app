import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/services/rider_map_service.dart';
import '../../models/route_model.dart';

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
  const RiderMapLoaded({
    required this.session,
    this.routes = const [],
    this.selectedRouteIndex = 0,
    this.currentPosition,
    this.currentHeading,
    this.isOffRoute = false,
    this.isLoadingRoute = false,
    this.routeError,
    this.isNearDestination = false,
    this.currentStepIndex = 0,
    this.distanceToNextManeuverMeters = 0,
    this.liveRemainingDistanceMeters,
    this.liveRemainingDurationSeconds,
  });

  final RiderMapSession session;
  final List<RouteModel> routes;
  final int selectedRouteIndex;
  final LatLng? currentPosition;
  final double? currentHeading;
  final bool isOffRoute;
  final bool isLoadingRoute;
  final String? routeError;
  final bool isNearDestination;
  final int currentStepIndex;
  final int distanceToNextManeuverMeters;
  final int? liveRemainingDistanceMeters;
  final int? liveRemainingDurationSeconds;

  bool get isArrived => session.isArrived;

  bool get isCompleted => session.order.isCompleted;

  RouteModel? get selectedRoute {
    if (routes.isEmpty) return null;
    if (selectedRouteIndex >= 0 && selectedRouteIndex < routes.length) {
      return routes[selectedRouteIndex];
    }
    return routes.first;
  }

  String get activeDistance {
    if (liveRemainingDistanceMeters != null) {
      return RouteStepModel.formatDistance(liveRemainingDistanceMeters!);
    }
    final route = selectedRoute;
    if (route != null && route.distanceText.isNotEmpty) {
      return route.distanceText;
    }
    return session.distance;
  }

  String get activeEta {
    if (liveRemainingDurationSeconds != null) {
      return RouteStepModel.formatDuration(liveRemainingDurationSeconds!);
    }
    final route = selectedRoute;
    if (route != null && route.durationText.isNotEmpty) {
      return route.durationText;
    }
    return session.eta;
  }

  /// Current dynamic step maneuver based on vehicle progress along route
  RouteStepModel? get currentManeuver {
    final route = selectedRoute;
    if (route == null || route.steps.isEmpty) return null;
    if (currentStepIndex >= 0 && currentStepIndex < route.steps.length) {
      return route.steps[currentStepIndex];
    }
    return route.steps.last;
  }

  /// Formatted distance to the next upcoming turn/maneuver
  String get distanceToManeuverText =>
      RouteStepModel.formatDistance(distanceToNextManeuverMeters);

  RiderMapLoaded copyWith({
    RiderMapSession? session,
    List<RouteModel>? routes,
    int? selectedRouteIndex,
    LatLng? currentPosition,
    double? currentHeading,
    bool? isOffRoute,
    bool? isLoadingRoute,
    String? routeError,
    bool? isNearDestination,
    int? currentStepIndex,
    int? distanceToNextManeuverMeters,
    int? liveRemainingDistanceMeters,
    int? liveRemainingDurationSeconds,
  }) {
    return RiderMapLoaded(
      session: session ?? this.session,
      routes: routes ?? this.routes,
      selectedRouteIndex: selectedRouteIndex ?? this.selectedRouteIndex,
      currentPosition: currentPosition ?? this.currentPosition,
      currentHeading: currentHeading ?? this.currentHeading,
      isOffRoute: isOffRoute ?? this.isOffRoute,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      routeError: routeError,
      isNearDestination: isNearDestination ?? this.isNearDestination,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      distanceToNextManeuverMeters:
          distanceToNextManeuverMeters ?? this.distanceToNextManeuverMeters,
      liveRemainingDistanceMeters:
          liveRemainingDistanceMeters ?? this.liveRemainingDistanceMeters,
      liveRemainingDurationSeconds:
          liveRemainingDurationSeconds ?? this.liveRemainingDurationSeconds,
    );
  }

  @override
  List<Object?> get props => [
        session,
        routes,
        selectedRouteIndex,
        currentPosition,
        currentHeading,
        isOffRoute,
        isLoadingRoute,
        routeError,
        isNearDestination,
        currentStepIndex,
        distanceToNextManeuverMeters,
        liveRemainingDistanceMeters,
        liveRemainingDurationSeconds,
      ];
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
