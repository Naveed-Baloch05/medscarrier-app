import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/services/rider_batch_service.dart';
import '../../core/utils/route_utils.dart';
import '../../models/delivery_route_model.dart';
import 'rider_batch_event.dart';
import 'rider_batch_state.dart';

class RiderBatchBloc extends Bloc<RiderBatchEvent, RiderBatchState> {
  RiderBatchBloc({
    RiderBatchService? batchService,
  })  : _batchService = batchService ?? RiderBatchService.instance,
        super(const RiderBatchInitial()) {
    on<CreateNewRoute>(_onCreateNewRoute);
    on<LoadExistingRoute>(_onLoadExistingRoute);
    on<ResumeActiveRoute>(_onResumeActiveRoute);
    on<InitBatchSession>(_onInitSession);
    on<ScanPackageQr>(_onScanPackageQr);
    on<ConfirmScannedDelivery>(_onConfirmScannedDelivery);
    on<EditRouteStop>(_onEditRouteStop);
    on<AddStopNote>(_onAddStopNote);
    on<RemoveScannedPackage>(_onRemoveScannedPackage);
    on<ClearScanFeedback>(_onClearScanFeedback);
    on<OptimizeBatchRoute>(_onOptimizeBatchRoute);
    on<RefineRouteSequence>(_onRefineRouteSequence);
    on<ConfirmOptimizedRoute>(_onConfirmOptimizedRoute);
    on<StartBatchRoute>(_onStartBatchRoute);
    on<UpdateRiderBatchPosition>(_onUpdatePosition);
    on<MarkActiveStopDelivered>(_onMarkActiveStopDelivered);
    on<MarkActiveStopFailed>(_onMarkActiveStopFailed);
    on<UndoLastStopStatus>(_onUndoLastStopStatus);
    on<SelectStopManually>(_onSelectStopManually);
    on<SkipActiveStop>(_onSkipActiveStop);
    on<CompleteBatchRun>(_onCompleteBatchRun);
  }

  final RiderBatchService _batchService;

  Future<void> _onCreateNewRoute(
    CreateNewRoute event,
    Emitter<RiderBatchState> emit,
  ) async {
    debugPrint('=== [BLOC: CreateNewRoute event received] ===');
    debugPrint('Rider ID: ${event.riderId}, Date: ${event.date}, Name: ${event.name}');

    final riderId = event.riderId.trim();
    if (riderId.isEmpty) {
      debugPrint('[BLOC ERROR]: Rider ID is empty.');
      emit(const RiderBatchError(message: 'Rider ID is required to create a delivery route.'));
      return;
    }

    emit(const RiderBatchCreatingRoute());

    try {
      final route = await _batchService.createRoute(
        riderId: riderId,
        date: event.date,
        name: event.name,
        pharmacyId: event.pharmacyId,
        pharmacyName: event.pharmacyName,
        startLocation: event.startLocation,
        carryPreviousStops: event.carryPreviousStops,
      );

      final effectivePharmacyId =
          (event.pharmacyId != null && event.pharmacyId!.isNotEmpty)
              ? event.pharmacyId!
              : route.pharmacyId;
      final effectivePharmacyName = route.pharmacyName.isNotEmpty
          ? route.pharmacyName
          : (event.pharmacyName ?? '');

      LatLng? pharmacyLocation;
      String? pharmacyAddress;
      if (effectivePharmacyId.isNotEmpty) {
        final pharm = await _batchService.fetchPharmacy(effectivePharmacyId);
        if (pharm != null) {
          pharmacyAddress = pharm['address'] as String?;
          final lat = pharm['latitude'] as double?;
          final lng = pharm['longitude'] as double?;
          if (lat != null && lng != null) {
            pharmacyLocation = LatLng(lat, lng);
          }
        }
      }

      debugPrint('=== [BLOC: Route created successfully: ${route.id}] ===');

      emit(RiderBatchScanning(
        riderId: riderId,
        route: route,
        pharmacyId: effectivePharmacyId,
        pharmacyName: effectivePharmacyName,
        pharmacyAddress: pharmacyAddress,
        pharmacyLocation: pharmacyLocation,
        stops: route.stops,
        scanSuccessMessage: 'Route "${route.name}" created successfully.',
      ));
    } catch (e) {
      debugPrint('=== [BLOC: Route creation failed: $e] ===');
      emit(RiderBatchError(
        message: 'Failed to create route: ${_clean(e)}',
      ));
    }
  }

  Future<void> _onLoadExistingRoute(
    LoadExistingRoute event,
    Emitter<RiderBatchState> emit,
  ) async {
    try {
      DeliveryRouteModel? route = await _batchService.getRouteById(event.routeId);
      route ??= await _batchService.getActiveRouteForRider(event.routeId);

      if (route == null) {
        emit(const RiderBatchError(message: 'Route not found.'));
        return;
      }

      if (route.status == 'active') {
        int firstPending = 0;
        for (int i = 0; i < route.stops.length; i++) {
          if (route.stops[i].isPending) {
            firstPending = i;
            break;
          }
        }

        emit(RiderBatchActiveDelivery(
          riderId: route.riderId,
          route: route,
          orderedStops: route.stops,
          currentStopIndex: firstPending,
        ));
      } else {
        emit(RiderBatchScanning(
          riderId: route.riderId,
          route: route,
          pharmacyId: route.pharmacyId,
          pharmacyName: route.pharmacyName,
          stops: route.stops,
        ));
      }
    } catch (e) {
      emit(RiderBatchError(message: 'Failed to load route: ${_clean(e)}'));
    }
  }

  void _onResumeActiveRoute(
    ResumeActiveRoute event,
    Emitter<RiderBatchState> emit,
  ) {
    final route = event.route;
    int firstPending = 0;
    for (int i = 0; i < route.stops.length; i++) {
      if (route.stops[i].isPending) {
        firstPending = i;
        break;
      }
    }

    emit(RiderBatchActiveDelivery(
      riderId: route.riderId,
      route: route,
      orderedStops: route.stops,
      currentStopIndex: firstPending,
    ));
  }

  Future<void> _onInitSession(
    InitBatchSession event,
    Emitter<RiderBatchState> emit,
  ) async {
    LatLng? pharmacyLocation;
    String? pharmacyAddress;
    String? resolvedPharmacyName = event.pharmacyName;

    if (event.pharmacyId != null && event.pharmacyId!.isNotEmpty) {
      final pharm = await _batchService.fetchPharmacy(event.pharmacyId!);
      if (pharm != null) {
        resolvedPharmacyName = pharm['name'] as String?;
        pharmacyAddress = pharm['address'] as String?;
        final lat = pharm['latitude'] as double?;
        final lng = pharm['longitude'] as double?;
        if (lat != null && lng != null) {
          pharmacyLocation = LatLng(lat, lng);
        }
      }
    }

    final route = event.existingRoute;

    emit(RiderBatchScanning(
      riderId: event.riderId,
      route: route,
      pharmacyId: event.pharmacyId,
      pharmacyName: resolvedPharmacyName,
      pharmacyAddress: pharmacyAddress,
      pharmacyLocation: pharmacyLocation,
      stops: route?.stops ?? const [],
    ));
  }

  Future<void> _onScanPackageQr(
    ScanPackageQr event,
    Emitter<RiderBatchState> emit,
  ) async {
    final current = state;
    if (current is! RiderBatchScanning) return;

    final raw = event.qrValue.trim();
    if (raw.isEmpty) return;

    emit(current.copyWith(
      isProcessing: true,
      clearMessages: true,
      clearDuplicateWarning: true,
    ));

    try {
      final order = await _batchService.lookupOrderByQr(
        qrValue: raw,
        currentRiderId: current.riderId,
        currentPharmacyId: current.pharmacyId,
      );

      // Phase 8: Duplicate protection
      if (current.isAlreadyScanned(order.id)) {
        final existing = current.findExistingStop(order.id);
        emit(current.copyWith(
          isProcessing: false,
          duplicateWarningMessage:
              'This delivery has already been added to this route.',
          duplicateExistingStop: existing,
          lastScannedOrder: order,
        ));
        return;
      }

      // Build RouteStopModel for verification (Phase 5)
      final routeId = current.route?.id ?? '';
      final newStop = RouteStopModel.fromOrderModel(
        order,
        routeId: routeId,
        sequence: current.stops.length + 1,
      );

      emit(current.copyWith(
        isProcessing: false,
        pendingVerificationStop: newStop,
        lastScannedOrder: order,
      ));
    } catch (e) {
      emit(current.copyWith(
        isProcessing: false,
        scanErrorMessage: _clean(e),
      ));
    }
  }

  Future<void> _onConfirmScannedDelivery(
    ConfirmScannedDelivery event,
    Emitter<RiderBatchState> emit,
  ) async {
    final current = state;
    if (current is! RiderBatchScanning) return;

    final stop = event.stop;

    // Check duplicate once more
    if (current.isAlreadyScanned(stop.orderId)) {
      emit(current.copyWith(
        clearPendingVerification: true,
        duplicateWarningMessage:
            'This delivery has already been added to this route.',
      ));
      return;
    }

    emit(current.copyWith(isProcessing: true));

    try {
      var activeRoute = current.route;
      activeRoute ??= await _batchService.createRoute(
        riderId: current.riderId,
        date: DateTime.now(),
        pharmacyId: current.pharmacyId,
        pharmacyName: current.pharmacyName,
        startLocation: current.pharmacyLocation,
      );

      // Save stop to route in Firestore
      await _batchService.addStopToRoute(
        routeId: activeRoute.id,
        stop: stop.copyWith(routeId: activeRoute.id),
      );

      final updatedStops = List<RouteStopModel>.from(current.stops)
        ..add(stop.copyWith(routeId: activeRoute.id));
      final updatedRoute = activeRoute.copyWith(
        stops: updatedStops,
        originalOrderIds: updatedStops.map((s) => s.orderId).toList(),
      );

      emit(current.copyWith(
        stops: updatedStops,
        route: updatedRoute,
        clearPendingVerification: true,
        isProcessing: false,
        scanSuccessMessage:
            'Stop #${stop.sequence} added: ${stop.customerName}',
      ));
    } catch (e) {
      emit(current.copyWith(
        isProcessing: false,
        scanErrorMessage: 'Failed to add stop: ${_clean(e)}',
      ));
    }
  }

  Future<void> _onEditRouteStop(
    EditRouteStop event,
    Emitter<RiderBatchState> emit,
  ) async {
    var stop = event.stop;

    // If coordinates are missing or address changed, try re-geocoding (Phase 9)
    if (stop.latitude == null || stop.longitude == null) {
      final geocoded = await _batchService.geocodeAddress(stop.address);
      if (geocoded != null) {
        stop = stop.copyWith(
          latitude: geocoded.latitude,
          longitude: geocoded.longitude,
        );
      }
    }

    if (state is RiderBatchScanning) {
      final current = state as RiderBatchScanning;
      final updatedStops = current.stops.map((s) {
        return (s.id == stop.id || s.orderId == stop.orderId) ? stop : s;
      }).toList();

      if (current.route != null) {
        await _batchService.updateRouteStop(
          routeId: current.route!.id,
          stop: stop,
        );
      }

      emit(current.copyWith(
        stops: updatedStops,
        scanSuccessMessage: 'Stop #${stop.sequence} updated successfully.',
      ));
    } else if (state is RiderBatchActiveDelivery) {
      final current = state as RiderBatchActiveDelivery;
      final updatedStops = current.orderedStops.map((s) {
        return (s.id == stop.id || s.orderId == stop.orderId) ? stop : s;
      }).toList();

      if (current.route != null) {
        await _batchService.updateRouteStop(
          routeId: current.route!.id,
          stop: stop,
        );
      }

      emit(current.copyWith(
        orderedStops: updatedStops,
        statusMessage: 'Stop #${stop.sequence} updated.',
      ));
    }
  }

  Future<void> _onAddStopNote(
    AddStopNote event,
    Emitter<RiderBatchState> emit,
  ) async {
    if (state is RiderBatchScanning) {
      final current = state as RiderBatchScanning;
      final target = current.stops.firstWhere((s) => s.orderId == event.orderId);
      final updated = target.copyWith(notes: event.note);
      add(EditRouteStop(updated));
    } else if (state is RiderBatchActiveDelivery) {
      final current = state as RiderBatchActiveDelivery;
      final target = current.orderedStops.firstWhere((s) => s.orderId == event.orderId);
      final updated = target.copyWith(notes: event.note);
      add(EditRouteStop(updated));
    }
  }

  Future<void> _onRemoveScannedPackage(
    RemoveScannedPackage event,
    Emitter<RiderBatchState> emit,
  ) async {
    final current = state;
    if (current is! RiderBatchScanning) return;

    try {
      if (current.route != null) {
        await _batchService.removeStopFromRoute(
          routeId: current.route!.id,
          orderId: event.orderId,
        );
      }

      final updatedStops = current.stops.where((s) => s.orderId != event.orderId).toList();
      for (int i = 0; i < updatedStops.length; i++) {
        updatedStops[i] = updatedStops[i].copyWith(sequence: i + 1);
      }

      emit(current.copyWith(
        stops: updatedStops,
        clearLastScan: current.lastScannedOrder?.id == event.orderId,
        scanSuccessMessage: 'Package removed from route.',
      ));
    } catch (e) {
      emit(current.copyWith(scanErrorMessage: 'Failed to remove package: ${_clean(e)}'));
    }
  }

  void _onClearScanFeedback(
    ClearScanFeedback event,
    Emitter<RiderBatchState> emit,
  ) {
    if (state is RiderBatchScanning) {
      emit((state as RiderBatchScanning).copyWith(
        clearMessages: true,
        clearDuplicateWarning: true,
      ));
    }
  }

  Future<void> _onOptimizeBatchRoute(
    OptimizeBatchRoute event,
    Emitter<RiderBatchState> emit,
  ) async {
    final current = state;
    if (current is! RiderBatchScanning) return;
    if (current.stops.isEmpty) {
      emit(current.copyWith(
        scanErrorMessage: 'Please scan at least one delivery package before optimizing.',
      ));
      return;
    }

    // Phase 14: Optimization State progression
    emit(RiderBatchOptimizing(
      stops: current.stops,
      riderId: current.riderId,
      route: current.route,
      stepText: 'Analyzing your stops...',
      progress: 0.35,
    ));

    await Future.delayed(const Duration(milliseconds: 400));

    emit(RiderBatchOptimizing(
      stops: current.stops,
      riderId: current.riderId,
      route: current.route,
      stepText: 'Creating your route...',
      progress: 0.75,
    ));

    await Future.delayed(const Duration(milliseconds: 400));

    // Resolve starting origin: Rider GPS > Pharmacy coordinates > First stop > Default
    LatLng origin = event.origin ??
        current.pharmacyLocation ??
        (current.stops.first.latLng ?? const LatLng(33.6844, 73.0479));

    // Convert RouteStopModel -> OrderModel for TSP calculation
    final orderModels = current.stops.map((s) => s.toOrderModel()).toList();

    // TSP Reordering based on real coordinates
    final optimizedOrders = RouteUtils.optimizeOrderSequence(
      origin: origin,
      orders: orderModels,
    );

    // Map back to ordered RouteStopModel list
    final orderedStops = <RouteStopModel>[];
    for (int i = 0; i < optimizedOrders.length; i++) {
      final ord = optimizedOrders[i];
      final original = current.stops.firstWhere(
        (s) => s.orderId == ord.id,
        orElse: () => RouteStopModel.fromOrderModel(ord, routeId: current.route?.id ?? ''),
      );
      orderedStops.add(original.copyWith(sequence: i + 1));
    }

    // Compute total distance & polyline
    final totalDistanceMeters = RouteUtils.totalRouteDistance(
      origin: origin,
      orderedStops: optimizedOrders,
    );

    // Estimated duration: ~30 km/h average speed in seconds + 3 mins per stop
    final estimatedDurationSeconds =
        (totalDistanceMeters / 8.33).round() + (orderedStops.length * 180);

    // Build route polylines connecting origin -> stops
    final polylinePoints = <LatLng>[origin];
    for (final stop in orderedStops) {
      if (stop.latLng != null) {
        polylinePoints.add(stop.latLng!);
      }
    }

    emit(RiderBatchRouteOverview(
      riderId: current.riderId,
      route: current.route,
      pharmacyId: current.pharmacyId,
      pharmacyName: current.pharmacyName,
      pharmacyLocation: current.pharmacyLocation,
      origin: origin,
      orderedStops: orderedStops,
      originalStops: current.stops,
      totalDistanceMeters: totalDistanceMeters,
      estimatedDurationSeconds: estimatedDurationSeconds,
      routePolylines: polylinePoints,
    ));
  }

  void _onRefineRouteSequence(
    RefineRouteSequence event,
    Emitter<RiderBatchState> emit,
  ) {
    final current = state;
    if (current is! RiderBatchRouteOverview) return;

    final reordered = List<RouteStopModel>.from(event.reorderedStops);
    for (int i = 0; i < reordered.length; i++) {
      reordered[i] = reordered[i].copyWith(sequence: i + 1);
    }

    final orderModels = reordered.map((s) => s.toOrderModel()).toList();
    final newDistance = RouteUtils.totalRouteDistance(
      origin: current.origin,
      orderedStops: orderModels,
    );
    final newDuration =
        (newDistance / 8.33).round() + (reordered.length * 180);

    final polylinePoints = <LatLng>[current.origin];
    for (final stop in reordered) {
      if (stop.latLng != null) {
        polylinePoints.add(stop.latLng!);
      }
    }

    emit(current.copyWith(
      orderedStops: reordered,
      totalDistanceMeters: newDistance,
      estimatedDurationSeconds: newDuration,
      routePolylines: polylinePoints,
    ));
  }

  Future<void> _onConfirmOptimizedRoute(
    ConfirmOptimizedRoute event,
    Emitter<RiderBatchState> emit,
  ) async {
    final current = state;
    if (current is! RiderBatchRouteOverview) return;

    try {
      if (current.route != null) {
        await _batchService.saveOptimizedRoute(
          routeId: current.route!.id,
          orderedStops: current.orderedStops,
          totalDistanceMeters: current.totalDistanceMeters,
          totalDurationSeconds: current.estimatedDurationSeconds,
          riderId: current.riderId,
        );
      }
    } catch (_) {}

    emit(RiderBatchActiveDelivery(
      riderId: current.riderId,
      route: current.route?.copyWith(status: 'active'),
      orderedStops: current.orderedStops,
      currentStopIndex: 0,
      riderPosition: current.origin,
      activeLegPolyline: current.routePolylines,
    ));
  }

  Future<void> _onStartBatchRoute(
    StartBatchRoute event,
    Emitter<RiderBatchState> emit,
  ) async {
    add(const ConfirmOptimizedRoute());
  }

  void _onUpdatePosition(
    UpdateRiderBatchPosition event,
    Emitter<RiderBatchState> emit,
  ) {
    final current = state;
    if (current is! RiderBatchActiveDelivery) return;

    emit(current.copyWith(riderPosition: event.position));
  }

  Future<void> _onMarkActiveStopDelivered(
    MarkActiveStopDelivered event,
    Emitter<RiderBatchState> emit,
  ) async {
    final current = state;
    if (current is! RiderBatchActiveDelivery) return;

    final active = current.activeStop;
    if (active == null) return;

    emit(current.copyWith(isUpdating: true, clearStatusMessages: true));

    try {
      await _batchService.markStopDelivered(
        routeId: current.route?.id,
        orderId: active.orderId,
        riderId: current.riderId,
        recipientName: event.recipientName,
      );

      final deliveredStop = active.copyWith(
        status: 'delivered',
        deliveredAt: DateTime.now(),
        recipientName: event.recipientName,
      );

      final updatedStops = current.orderedStops.map((s) {
        return s.orderId == active.orderId ? deliveredStop : s;
      }).toList();

      final nextIndex = _findNextPendingIndex(
        orderedStops: updatedStops,
        currentIndex: current.currentStopIndex,
      );

      // Check if all stops are now processed (Phase 26)
      if (nextIndex == -1 || updatedStops.every((s) => !s.isPending)) {
        if (current.route != null) {
          await _batchService.completeRoute(routeId: current.route!.id);
        }

        final delivered = updatedStops.where((s) => s.isDelivered).toList();
        final failed = updatedStops.where((s) => s.isFailed).toList();

        emit(RiderBatchCompletedSummary(
          riderId: current.riderId,
          route: current.route?.copyWith(status: 'completed'),
          totalDeliveries: updatedStops.length,
          deliveredStops: delivered,
          failedStops: failed,
          pharmacyName: active.pharmacyName,
        ));
      } else {
        emit(current.copyWith(
          orderedStops: updatedStops,
          currentStopIndex: nextIndex,
          lastProcessedStop: deliveredStop,
          isUpdating: false,
          statusMessage: 'Stop #${active.sequence} delivered! Moving to next stop.',
        ));
      }
    } catch (e) {
      emit(current.copyWith(
        isUpdating: false,
        statusError: 'Failed to record delivery in Firebase: ${_clean(e)}',
      ));
    }
  }

  Future<void> _onMarkActiveStopFailed(
    MarkActiveStopFailed event,
    Emitter<RiderBatchState> emit,
  ) async {
    final current = state;
    if (current is! RiderBatchActiveDelivery) return;

    final active = current.activeStop;
    if (active == null) return;

    emit(current.copyWith(isUpdating: true, clearStatusMessages: true));

    try {
      await _batchService.markStopFailed(
        routeId: current.route?.id,
        orderId: active.orderId,
        riderId: current.riderId,
        reason: event.reason,
        note: event.note,
      );

      final failedStop = active.copyWith(
        status: 'failed',
        failureReason: event.reason,
        failureNote: event.note,
        failedAt: DateTime.now(),
      );

      final updatedStops = current.orderedStops.map((s) {
        return s.orderId == active.orderId ? failedStop : s;
      }).toList();

      final nextIndex = _findNextPendingIndex(
        orderedStops: updatedStops,
        currentIndex: current.currentStopIndex,
      );

      if (nextIndex == -1 || updatedStops.every((s) => !s.isPending)) {
        if (current.route != null) {
          await _batchService.completeRoute(routeId: current.route!.id);
        }

        final delivered = updatedStops.where((s) => s.isDelivered).toList();
        final failed = updatedStops.where((s) => s.isFailed).toList();

        emit(RiderBatchCompletedSummary(
          riderId: current.riderId,
          route: current.route?.copyWith(status: 'completed'),
          totalDeliveries: updatedStops.length,
          deliveredStops: delivered,
          failedStops: failed,
          pharmacyName: active.pharmacyName,
        ));
      } else {
        emit(current.copyWith(
          orderedStops: updatedStops,
          currentStopIndex: nextIndex,
          lastProcessedStop: failedStop,
          isUpdating: false,
          statusMessage: 'Stop #${active.sequence} marked as Failed. Moving to next stop.',
        ));
      }
    } catch (e) {
      emit(current.copyWith(
        isUpdating: false,
        statusError: 'Failed to record failure in Firebase: ${_clean(e)}',
      ));
    }
  }

  Future<void> _onUndoLastStopStatus(
    UndoLastStopStatus event,
    Emitter<RiderBatchState> emit,
  ) async {
    final current = state;
    if (current is! RiderBatchActiveDelivery) return;

    final last = current.lastProcessedStop;
    if (last == null) return;

    emit(current.copyWith(isUpdating: true, clearStatusMessages: true));

    try {
      await _batchService.undoStopStatus(
        routeId: current.route?.id,
        orderId: last.orderId,
        riderId: current.riderId,
      );

      final revertedStop = last.copyWith(
        status: 'pending',
        failureReason: null,
        failureNote: null,
        deliveredAt: null,
        failedAt: null,
      );

      final updatedStops = current.orderedStops.map((s) {
        return s.orderId == last.orderId ? revertedStop : s;
      }).toList();

      // Set active stop back to the reverted stop index
      final revertedIndex = updatedStops.indexWhere((s) => s.orderId == last.orderId);

      emit(current.copyWith(
        orderedStops: updatedStops,
        currentStopIndex: revertedIndex >= 0 ? revertedIndex : current.currentStopIndex,
        isUpdating: false,
        clearLastProcessed: true,
        statusMessage: 'Stop #${last.sequence} restored to Pending.',
      ));
    } catch (e) {
      emit(current.copyWith(
        isUpdating: false,
        statusError: 'Failed to undo stop status: ${_clean(e)}',
      ));
    }
  }

  void _onSelectStopManually(
    SelectStopManually event,
    Emitter<RiderBatchState> emit,
  ) {
    final current = state;
    if (current is! RiderBatchActiveDelivery) return;

    if (event.index >= 0 && event.index < current.orderedStops.length) {
      emit(current.copyWith(currentStopIndex: event.index));
    }
  }

  void _onSkipActiveStop(
    SkipActiveStop event,
    Emitter<RiderBatchState> emit,
  ) {
    final current = state;
    if (current is! RiderBatchActiveDelivery) return;

    final active = current.activeStop;
    if (active == null) return;

    final nextIndex = _findNextPendingIndex(
      orderedStops: current.orderedStops,
      currentIndex: current.currentStopIndex,
    );

    if (nextIndex != -1 && nextIndex != current.currentStopIndex) {
      final nextStop = current.orderedStops[nextIndex];
      emit(current.copyWith(
        currentStopIndex: nextIndex,
        statusMessage:
            'Skipped Stop #${active.sequence}. Switched to Stop #${nextStop.sequence} (${nextStop.customerName}).',
      ));
    } else {
      emit(current.copyWith(
        statusMessage: 'No other pending stops to switch to.',
      ));
    }
  }

  Future<void> _onCompleteBatchRun(
    CompleteBatchRun event,
    Emitter<RiderBatchState> emit,
  ) async {
    final current = state;
    if (current is! RiderBatchActiveDelivery) return;

    try {
      if (current.route != null) {
        await _batchService.completeRoute(routeId: current.route!.id);
      }
    } catch (_) {}

    final delivered = current.orderedStops.where((s) => s.isDelivered).toList();
    final failed = current.orderedStops.where((s) => s.isFailed).toList();

    emit(RiderBatchCompletedSummary(
      riderId: current.riderId,
      route: current.route?.copyWith(status: 'completed'),
      totalDeliveries: current.totalStops,
      deliveredStops: delivered,
      failedStops: failed,
      pharmacyName: current.activeStop?.pharmacyName,
    ));
  }

  int _findNextPendingIndex({
    required List<RouteStopModel> orderedStops,
    required int currentIndex,
  }) {
    for (int i = currentIndex + 1; i < orderedStops.length; i++) {
      if (orderedStops[i].isPending) {
        return i;
      }
    }
    for (int i = 0; i < currentIndex; i++) {
      if (orderedStops[i].isPending) {
        return i;
      }
    }
    return -1;
  }

  String _clean(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
