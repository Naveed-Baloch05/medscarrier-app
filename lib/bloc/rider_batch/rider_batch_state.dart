import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/delivery_route_model.dart';
import '../../models/order_model.dart';
import '../../models/route_model.dart';

abstract class RiderBatchState extends Equatable {
  const RiderBatchState();

  @override
  List<Object?> get props => [];
}

class RiderBatchInitial extends RiderBatchState {
  const RiderBatchInitial();
}

class RiderBatchCreatingRoute extends RiderBatchState {
  const RiderBatchCreatingRoute({this.message = 'Creating route document...'});
  final String message;

  @override
  List<Object?> get props => [message];
}

/// State during physical box package scanning and route building
class RiderBatchScanning extends RiderBatchState {
  const RiderBatchScanning({
    required this.riderId,
    this.route,
    this.pharmacyId,
    this.pharmacyName,
    this.pharmacyAddress,
    this.pharmacyLocation,
    this.stops = const [],
    this.pendingVerificationStop,
    this.lastScannedOrder,
    this.duplicateWarningMessage,
    this.duplicateExistingStop,
    this.scanSuccessMessage,
    this.scanErrorMessage,
    this.isProcessing = false,
  });

  final String riderId;
  final DeliveryRouteModel? route;
  final String? pharmacyId;
  final String? pharmacyName;
  final String? pharmacyAddress;
  final LatLng? pharmacyLocation;
  final List<RouteStopModel> stops;
  final RouteStopModel? pendingVerificationStop;
  final OrderModel? lastScannedOrder;
  final String? duplicateWarningMessage;
  final RouteStopModel? duplicateExistingStop;
  final String? scanSuccessMessage;
  final String? scanErrorMessage;
  final bool isProcessing;

  int get totalScanned => stops.length;

  List<OrderModel> get scannedOrders => stops.map((s) => s.toOrderModel()).toList();

  bool isAlreadyScanned(String orderId) {
    return stops.any((s) => s.orderId == orderId || s.id == orderId);
  }

  RouteStopModel? findExistingStop(String orderId) {
    try {
      return stops.firstWhere((s) => s.orderId == orderId || s.id == orderId);
    } catch (_) {
      return null;
    }
  }

  RiderBatchScanning copyWith({
    String? riderId,
    DeliveryRouteModel? route,
    String? pharmacyId,
    String? pharmacyName,
    String? pharmacyAddress,
    LatLng? pharmacyLocation,
    List<RouteStopModel>? stops,
    RouteStopModel? pendingVerificationStop,
    OrderModel? lastScannedOrder,
    String? duplicateWarningMessage,
    RouteStopModel? duplicateExistingStop,
    String? scanSuccessMessage,
    String? scanErrorMessage,
    bool? isProcessing,
    bool clearPendingVerification = false,
    bool clearDuplicateWarning = false,
    bool clearLastScan = false,
    bool clearMessages = false,
  }) {
    return RiderBatchScanning(
      riderId: riderId ?? this.riderId,
      route: route ?? this.route,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyAddress: pharmacyAddress ?? this.pharmacyAddress,
      pharmacyLocation: pharmacyLocation ?? this.pharmacyLocation,
      stops: stops ?? this.stops,
      pendingVerificationStop: clearPendingVerification
          ? null
          : (pendingVerificationStop ?? this.pendingVerificationStop),
      lastScannedOrder:
          clearLastScan ? null : (lastScannedOrder ?? this.lastScannedOrder),
      duplicateWarningMessage: clearDuplicateWarning
          ? null
          : (duplicateWarningMessage ?? this.duplicateWarningMessage),
      duplicateExistingStop: clearDuplicateWarning
          ? null
          : (duplicateExistingStop ?? this.duplicateExistingStop),
      scanSuccessMessage:
          clearMessages ? null : (scanSuccessMessage ?? this.scanSuccessMessage),
      scanErrorMessage:
          clearMessages ? null : (scanErrorMessage ?? this.scanErrorMessage),
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  @override
  List<Object?> get props => [
        riderId,
        route,
        pharmacyId,
        pharmacyName,
        pharmacyAddress,
        pharmacyLocation,
        stops,
        pendingVerificationStop,
        lastScannedOrder,
        duplicateWarningMessage,
        duplicateExistingStop,
        scanSuccessMessage,
        scanErrorMessage,
        isProcessing,
      ];
}

/// State while computing route optimization with step feedback
class RiderBatchOptimizing extends RiderBatchState {
  const RiderBatchOptimizing({
    required this.stops,
    required this.riderId,
    this.route,
    this.stepText = 'Analyzing your stops...',
    this.progress = 0.5,
  });

  final List<RouteStopModel> stops;
  final String riderId;
  final DeliveryRouteModel? route;
  final String stepText;
  final double progress;

  List<OrderModel> get scannedOrders => stops.map((s) => s.toOrderModel()).toList();

  @override
  List<Object?> get props => [stops, riderId, route, stepText, progress];
}

/// State displaying the optimized route on the map with ordered stops
class RiderBatchRouteOverview extends RiderBatchState {
  const RiderBatchRouteOverview({
    required this.riderId,
    this.route,
    this.pharmacyId,
    this.pharmacyName,
    this.pharmacyLocation,
    required this.origin,
    required this.orderedStops,
    required this.originalStops,
    required this.totalDistanceMeters,
    required this.estimatedDurationSeconds,
    this.routePolylines = const [],
  });

  final String riderId;
  final DeliveryRouteModel? route;
  final String? pharmacyId;
  final String? pharmacyName;
  final LatLng? pharmacyLocation;
  final LatLng origin;
  final List<RouteStopModel> orderedStops;
  final List<RouteStopModel> originalStops;
  final double totalDistanceMeters;
  final int estimatedDurationSeconds;
  final List<LatLng> routePolylines;

  int get stopCount => orderedStops.length;

  List<OrderModel> get orderedOrders => orderedStops.map((s) => s.toOrderModel()).toList();

  String get formattedTotalDistance =>
      RouteStepModel.formatDistance(totalDistanceMeters.round());

  String get formattedTotalDuration =>
      RouteStepModel.formatDuration(estimatedDurationSeconds);

  String get formattedMiles {
    final miles = totalDistanceMeters * 0.000621371;
    return '${miles.toStringAsFixed(1)} miles';
  }

  String get summaryText {
    final mins = (estimatedDurationSeconds / 60).round();
    final miles = (totalDistanceMeters * 0.000621371).toStringAsFixed(1);
    return '$mins min \u00B7 $stopCount stops \u00B7 $miles miles';
  }

  RiderBatchRouteOverview copyWith({
    String? riderId,
    DeliveryRouteModel? route,
    String? pharmacyId,
    String? pharmacyName,
    LatLng? pharmacyLocation,
    LatLng? origin,
    List<RouteStopModel>? orderedStops,
    List<RouteStopModel>? originalStops,
    double? totalDistanceMeters,
    int? estimatedDurationSeconds,
    List<LatLng>? routePolylines,
  }) {
    return RiderBatchRouteOverview(
      riderId: riderId ?? this.riderId,
      route: route ?? this.route,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyLocation: pharmacyLocation ?? this.pharmacyLocation,
      origin: origin ?? this.origin,
      orderedStops: orderedStops ?? this.orderedStops,
      originalStops: originalStops ?? this.originalStops,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      estimatedDurationSeconds:
          estimatedDurationSeconds ?? this.estimatedDurationSeconds,
      routePolylines: routePolylines ?? this.routePolylines,
    );
  }

  @override
  List<Object?> get props => [
        riderId,
        route,
        pharmacyId,
        pharmacyName,
        pharmacyLocation,
        origin,
        orderedStops,
        originalStops,
        totalDistanceMeters,
        estimatedDurationSeconds,
        routePolylines,
      ];
}

/// State representing the active multi-stop delivery progression
class RiderBatchActiveDelivery extends RiderBatchState {
  const RiderBatchActiveDelivery({
    required this.riderId,
    this.route,
    required this.orderedStops,
    required this.currentStopIndex,
    this.lastProcessedStop,
    this.riderPosition,
    this.activeLegPolyline = const [],
    this.isUpdating = false,
    this.statusError,
    this.statusMessage,
  });

  final String riderId;
  final DeliveryRouteModel? route;
  final List<RouteStopModel> orderedStops;
  final int currentStopIndex;
  final RouteStopModel? lastProcessedStop;
  final LatLng? riderPosition;
  final List<LatLng> activeLegPolyline;
  final bool isUpdating;
  final String? statusError;
  final String? statusMessage;

  int get totalStops => orderedStops.length;

  int get completedCount => orderedStops.where((s) => s.isDelivered).length;

  int get failedCount => orderedStops.where((s) => s.isFailed).length;

  int get processedCount => completedCount + failedCount;

  int get remainingStops => totalStops - processedCount;

  bool get isAllProcessed => remainingStops <= 0;

  RouteStopModel? get activeStop =>
      (currentStopIndex >= 0 && currentStopIndex < orderedStops.length)
          ? orderedStops[currentStopIndex]
          : null;

  OrderModel? get activeOrder => activeStop?.toOrderModel();

  List<OrderModel> get orderedOrders => orderedStops.map((s) => s.toOrderModel()).toList();

  bool isStopCompleted(String orderId) =>
      orderedStops.any((s) => s.orderId == orderId && s.isDelivered);

  bool isStopFailed(String orderId) =>
      orderedStops.any((s) => s.orderId == orderId && s.isFailed);

  String? getStopFailureReason(String orderId) {
    try {
      return orderedStops.firstWhere((s) => s.orderId == orderId).failureReason;
    } catch (_) {
      return null;
    }
  }

  RiderBatchActiveDelivery copyWith({
    String? riderId,
    DeliveryRouteModel? route,
    List<RouteStopModel>? orderedStops,
    int? currentStopIndex,
    RouteStopModel? lastProcessedStop,
    LatLng? riderPosition,
    List<LatLng>? activeLegPolyline,
    bool? isUpdating,
    String? statusError,
    String? statusMessage,
    bool clearStatusMessages = false,
    bool clearLastProcessed = false,
  }) {
    return RiderBatchActiveDelivery(
      riderId: riderId ?? this.riderId,
      route: route ?? this.route,
      orderedStops: orderedStops ?? this.orderedStops,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      lastProcessedStop: clearLastProcessed
          ? null
          : (lastProcessedStop ?? this.lastProcessedStop),
      riderPosition: riderPosition ?? this.riderPosition,
      activeLegPolyline: activeLegPolyline ?? this.activeLegPolyline,
      isUpdating: isUpdating ?? this.isUpdating,
      statusError: clearStatusMessages ? null : (statusError ?? this.statusError),
      statusMessage:
          clearStatusMessages ? null : (statusMessage ?? this.statusMessage),
    );
  }

  @override
  List<Object?> get props => [
        riderId,
        route,
        orderedStops,
        currentStopIndex,
        lastProcessedStop,
        riderPosition,
        activeLegPolyline,
        isUpdating,
        statusError,
        statusMessage,
      ];
}

/// Final summary screen when all batch stops have been processed
class RiderBatchCompletedSummary extends RiderBatchState {
  const RiderBatchCompletedSummary({
    required this.riderId,
    this.route,
    required this.totalDeliveries,
    required this.deliveredStops,
    required this.failedStops,
    this.pharmacyName,
  });

  final String riderId;
  final DeliveryRouteModel? route;
  final int totalDeliveries;
  final List<RouteStopModel> deliveredStops;
  final List<RouteStopModel> failedStops;
  final String? pharmacyName;

  int get deliveredCount => deliveredStops.length;
  int get failedCount => failedStops.length;

  List<OrderModel> get deliveredOrders =>
      deliveredStops.map((s) => s.toOrderModel()).toList();
  List<OrderModel> get failedOrders =>
      failedStops.map((s) => s.toOrderModel()).toList();

  Map<String, String> get failedReasons {
    final map = <String, String>{};
    for (final s in failedStops) {
      if (s.failureReason != null) {
        map[s.orderId] = s.failureReason!;
      }
    }
    return map;
  }

  @override
  List<Object?> get props => [
        riderId,
        route,
        totalDeliveries,
        deliveredStops,
        failedStops,
        pharmacyName,
      ];
}

/// Generic error state
class RiderBatchError extends RiderBatchState {
  const RiderBatchError({required this.message, this.previousState});

  final String message;
  final RiderBatchState? previousState;

  @override
  List<Object?> get props => [message, previousState];
}
