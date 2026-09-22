import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../bloc/rider_batch/rider_batch_bloc.dart';
import '../bloc/rider_batch/rider_batch_event.dart';
import '../bloc/rider_batch/rider_batch_state.dart';
import '../core/services/navigation_service.dart';
import '../core/services/rider_map_service.dart';
import '../core/utils/route_utils.dart';
import '../models/delivery_route_model.dart';
import 'rider_batch_summary_screen.dart';
import 'rider_map_screen.dart';

class RiderBatchActiveScreen extends StatefulWidget {
  const RiderBatchActiveScreen({
    super.key,
    required this.bloc,
  });

  final RiderBatchBloc bloc;

  @override
  State<RiderBatchActiveScreen> createState() => _RiderBatchActiveScreenState();
}

class _RiderBatchActiveScreenState extends State<RiderBatchActiveScreen> {
  static const Color primaryColor = Color(0xFF0F7253);
  static const Color secondaryColor = Color(0xFF32C787);

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSub;
  LatLng? _currentRiderLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Live tracking throttling for rider_locations/{riderId}
  DateTime? _lastLocationWriteTime;
  LatLng? _lastLocationWritePos;
  bool _routeCompleted = false;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    if (!_routeCompleted && mounted) {
      final state = widget.bloc.state;
      final riderId = state is RiderBatchActiveDelivery
          ? state.riderId
          : (state is RiderBatchCompletedSummary ? state.riderId : '');
      if (riderId.isNotEmpty) {
        RiderMapService.instance
            .stopRiderBatchTracking(riderId: riderId, completed: false);
      }
    }
    _mapController?.dispose();
    super.dispose();
  }

  void _startLocationTracking() async {
    try {
      final initial = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        final pos = LatLng(initial.latitude, initial.longitude);
        setState(() {
          _currentRiderLocation = pos;
        });
        widget.bloc.add(UpdateRiderBatchPosition(pos));
        _updateMap();
        _publishLiveLocation(pos);
      }

      await _positionSub?.cancel();
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        if (mounted) {
          final latLng = LatLng(pos.latitude, pos.longitude);
          setState(() {
            _currentRiderLocation = latLng;
          });
          widget.bloc.add(UpdateRiderBatchPosition(latLng));
          _updateMap();
          _publishLiveLocation(latLng);
        }
      });
    } catch (_) {}
  }

  /// Writes the rider's live snapshot to `rider_locations/{riderId}`,
  /// throttled to at most one write per 15 seconds or 25 meters moved.
  void _publishLiveLocation(LatLng pos) {
    final state = widget.bloc.state;
    if (state is! RiderBatchActiveDelivery) return;

    final route = state.route;
    final routeId = route?.id ?? '';
    final activeStop = state.activeStop;
    final pharmacyId = route?.pharmacyId.isNotEmpty == true
        ? route!.pharmacyId
        : (activeStop?.pharmacyId ?? '');

    if (state.riderId.trim().isEmpty || routeId.isEmpty) return;

    final now = DateTime.now();
    final timeDiff = _lastLocationWriteTime == null
        ? 999
        : now.difference(_lastLocationWriteTime!).inSeconds;
    final distanceMoved = _lastLocationWritePos == null
        ? 999.0
        : RouteUtils.distanceMeters(pos, _lastLocationWritePos!);

    if (timeDiff < 15 && distanceMoved < 25) return;

    _lastLocationWriteTime = now;
    _lastLocationWritePos = pos;

    RiderMapService.instance.updateRiderBatchLocation(
      riderId: state.riderId,
      pharmacyId: pharmacyId,
      routeId: routeId,
      latitude: pos.latitude,
      longitude: pos.longitude,
      currentStopIndex: state.currentStopIndex,
      currentOrderId: activeStop?.orderId ?? '',
      currentCustomerName: activeStop?.customerName ?? '',
      currentAddress: activeStop?.formattedAddress.isNotEmpty == true
          ? activeStop!.formattedAddress
          : (activeStop?.address ?? ''),
      totalStops: state.totalStops,
      deliveredCount: state.completedCount,
      failedCount: state.failedCount,
    );
  }

  void _updateMap() {
    final state = widget.bloc.state;
    if (state is! RiderBatchActiveDelivery) return;

    final activeStop = state.activeStop;
    _markers.clear();
    _polylines.clear();

    // 1. Rider Live Position Marker
    if (_currentRiderLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('rider_live_marker'),
          position: _currentRiderLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location (Live GPS)'),
        ),
      );
    }

    // 2. All stops markers with sequence numbers
    for (int i = 0; i < state.orderedStops.length; i++) {
      final s = state.orderedStops[i];
      if (s.latLng != null) {
        final isActive = i == state.currentStopIndex;
        _markers.add(
          Marker(
            markerId: MarkerId('stop_${s.id}'),
            position: s.latLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isActive
                  ? BitmapDescriptor.hueRed
                  : (s.isDelivered
                      ? BitmapDescriptor.hueGreen
                      : (s.isFailed ? BitmapDescriptor.hueViolet : BitmapDescriptor.hueOrange)),
            ),
            infoWindow: InfoWindow(
              title: 'Stop #${s.sequence}: ${s.customerName}',
              snippet: '${s.address} (${s.status.toUpperCase()})',
            ),
          ),
        );
      }
    }

    // 3. Polyline from Rider to Active Stop
    if (_currentRiderLocation != null && activeStop?.latLng != null) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('active_leg_path'),
          points: [_currentRiderLocation!, activeStop!.latLng!],
          color: primaryColor,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }

    _fitActiveBounds();
  }

  void _fitActiveBounds() {
    if (_mapController == null) return;
    final state = widget.bloc.state;
    if (state is! RiderBatchActiveDelivery) return;
    final active = state.activeStop;

    if (_currentRiderLocation != null && active?.latLng != null) {
      final p1 = _currentRiderLocation!;
      final p2 = active!.latLng!;

      final minLat = p1.latitude < p2.latitude ? p1.latitude : p2.latitude;
      final maxLat = p1.latitude > p2.latitude ? p1.latitude : p2.latitude;
      final minLng = p1.longitude < p2.longitude ? p1.longitude : p2.longitude;
      final maxLng = p1.longitude > p2.longitude ? p1.longitude : p2.longitude;

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          80,
        ),
      );
    } else if (active?.latLng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(active!.latLng!, 16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: widget.bloc,
      child: BlocConsumer<RiderBatchBloc, RiderBatchState>(
        listener: (context, state) {
          if (state is RiderBatchCompletedSummary) {
            if (!_routeCompleted) {
              _routeCompleted = true;
              _positionSub?.cancel();
              if (state.riderId.isNotEmpty) {
                RiderMapService.instance.stopRiderBatchTracking(
                  riderId: state.riderId,
                  completed: true,
                );
              }
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RiderBatchSummaryScreen(
                  summaryState: state,
                ),
              ),
            );
          } else if (state is RiderBatchActiveDelivery) {
            _updateMap();

            if (state.statusMessage != null && state.statusMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.statusMessage!),
                  backgroundColor: primaryColor,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  // Phase 23: Undo Action
                  action: state.lastProcessedStop != null
                      ? SnackBarAction(
                          label: 'UNDO',
                          textColor: Colors.amberAccent,
                          onPressed: () {
                            widget.bloc.add(const UndoLastStopStatus());
                          },
                        )
                      : null,
                ),
              );
            } else if (state.statusError != null && state.statusError!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.statusError!),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is! RiderBatchActiveDelivery) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: primaryColor)),
            );
          }

          final activeStop = state.activeStop;
          final int stopNum = state.currentStopIndex + 1;
          final int totalStops = state.totalStops;

          return Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  // 1. Google Map
                  Positioned.fill(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: activeStop?.latLng ??
                            _currentRiderLocation ??
                            const LatLng(33.6844, 73.0479),
                        zoom: 15,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        Future.delayed(const Duration(milliseconds: 200), _fitActiveBounds);
                      },
                    ),
                  ),

                  // 2. Top Progress Header Bar (Phase 18 & 24)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: _buildTopProgressBar(context, state, stopNum, totalStops, isDark),
                  ),

                  // 3. Floating Recenter Button
                  Positioned(
                    right: 16,
                    bottom: 390,
                    child: CircleAvatar(
                      backgroundColor: isDark ? const Color(0xFF131D18) : Colors.white,
                      radius: 22,
                      child: IconButton(
                        icon: const Icon(Icons.my_location, color: primaryColor),
                        onPressed: _fitActiveBounds,
                      ),
                    ),
                  ),

                  // 4. Bottom Active Delivery Execution Card (Phase 20)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildActiveDeliveryCard(
                      context,
                      state: state,
                      stop: activeStop,
                      stopNumber: stopNum,
                      isDark: isDark,
                    ),
                  ),

                  // 5. Updating Status Loading Overlay
                  if (state.isUpdating)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopProgressBar(
    BuildContext context,
    RiderBatchActiveDelivery state,
    int currentStop,
    int totalStops,
    bool isDark,
  ) {
    final double progress = totalStops > 0 ? (state.processedCount / totalStops) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D18) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Stop $currentStop of $totalStops',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${state.completedCount} delivered \u00B7 ${state.remainingStops} left',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (state.lastProcessedStop != null) ...[
                    TextButton.icon(
                      onPressed: () {
                        widget.bloc.add(const UndoLastStopStatus());
                      },
                      icon: const Icon(Icons.undo, size: 15, color: Colors.amber),
                      label: const Text('Undo', style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.format_list_numbered, color: primaryColor),
                    onPressed: () => _showStopsDrawer(context, state),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(secondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveryCard(
    BuildContext context, {
    required RiderBatchActiveDelivery state,
    required RouteStopModel? stop,
    required int stopNumber,
    required bool isDark,
  }) {
    if (stop == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D18) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Customer Header & ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${stop.orderId}',
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        if (stop.coldChain) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.cyan.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '❄ Cold-Chain',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.cyan.shade900,
                              ),
                            ),
                          ),
                        ],
                        if (stop.controlledDrug) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '🛡 CD',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stop.customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              // Call Button
              if (stop.customerPhone.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.phone, color: primaryColor, size: 20),
                    tooltip: 'Call recipient',
                    onPressed: () => NavigationService.makePhoneCall(stop.customerPhone),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Address Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C2A22) : const Color(0xFFF2F5F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DELIVERY ADDRESS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stop.address.isNotEmpty ? stop.address : 'No address specified',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Package Items (MedsCarrier Prescription Content)
          if (stop.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16251D) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: secondaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medication_outlined, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRESCRIPTION ITEMS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stop.items.join(', '),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (stop.notes != null && stop.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note, size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      stop.notes!,
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Secondary Quick Actions: Add Notes & Edit Stop
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _showAddNoteDialog(context, stop),
                icon: const Icon(Icons.note_add_outlined, size: 16, color: primaryColor),
                label: const Text('Add Notes', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _showEditStopDialog(context, stop),
                icon: const Icon(Icons.edit_outlined, size: 16, color: primaryColor),
                label: const Text('Edit Stop', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Primary Actions: [ NAVIGATE ] | [ DELIVERED ]
          Row(
            children: [
              // 1. In-App Navigation (RiderMapScreen)
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _fitActiveBounds();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiderMapScreen(
                            routeStop: stop,
                            batchBloc: widget.bloc,
                            riderId: state.route?.riderId,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor, width: 1.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text(
                      'Navigate',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 2. Delivered Action
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeliveredConfirmationModal(context, stop),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      'Delivered',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Secondary Actions: [ FAILED ] | [ SKIP ]
          Row(
            children: [
              // 3. Failed Delivery
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _showFailureReasonModal(context, stop),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text(
                      'Failed',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 4. Skip Stop
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      widget.bloc.add(const SkipActiveStop());
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                      side: BorderSide(color: Colors.grey.shade400, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.skip_next_rounded, size: 18),
                    label: const Text(
                      'Skip Stop',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELIVERED CONFIRMATION MODAL
  // ============================================================

  void _showDeliveredConfirmationModal(BuildContext context, RouteStopModel stop) {
    final nameController = TextEditingController(
      text: stop.customerName.isNotEmpty ? stop.customerName : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131D18) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: primaryColor, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Complete Stop #${stop.sequence}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Confirm delivery to ${stop.customerName}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  'RECIPIENT NAME',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'e.g. Patient or recipient name',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1C2A22) : const Color(0xFFF2F5F3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (stop.coldChain) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.cyan.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.cyan.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.ac_unit, color: Colors.cyan.shade800, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cold-Chain Verified: Medication package maintained at 2–8°C.',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.cyan.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(modalCtx);
                      final confirmedRecipient = nameController.text.trim().isNotEmpty
                          ? nameController.text.trim()
                          : stop.customerName;
                      widget.bloc.add(MarkActiveStopDelivered(
                        recipientName: confirmedRecipient,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Confirm & Next Stop', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PHASE 22: FAILED REASON MODAL
  // ============================================================

  void _showFailureReasonModal(BuildContext context, RouteStopModel stop) {
    String selectedReason = 'Customer not available';
    final noteController = TextEditingController();

    final reasons = [
      'Customer not available',
      'Unable to access premises',
      'Customer refused delivery',
      'Wrong / incomplete address',
      'Damaged medication package',
      'Other reason',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D18) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Mark Delivery as Failed',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Stop #${stop.sequence} \u2022 ${stop.customerName}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SELECT REASON',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ...reasons.map(
                      (r) {
                        final isSelected = selectedReason == r;
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedReason = r;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  size: 18,
                                  color: isSelected ? Colors.red.shade700 : Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    r,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? Colors.red.shade900 : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ADDITIONAL NOTE (OPTIONAL)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Tried calling 3 times, no answer at door',
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1C2A22) : const Color(0xFFF2F5F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(modalCtx);
                          widget.bloc.add(MarkActiveStopFailed(
                            reason: selectedReason,
                            note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirm Failure & Next Stop',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddNoteDialog(BuildContext context, RouteStopModel stop) {
    final noteCtrl = TextEditingController(text: stop.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.note_alt_outlined, color: primaryColor),
            const SizedBox(width: 8),
            Text('Notes for Stop #${stop.sequence}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recipient: ${stop.customerName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Delivery instructions or notes...',
                filled: true,
                fillColor: const Color(0xFFF2F5F3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.bloc.add(AddStopNote(orderId: stop.orderId, note: noteCtrl.text.trim()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  void _showEditStopDialog(BuildContext context, RouteStopModel stop) {
    final customerCtrl = TextEditingController(text: stop.customerName);
    final phoneCtrl = TextEditingController(text: stop.customerPhone);
    final addressCtrl = TextEditingController(text: stop.address);
    final notesCtrl = TextEditingController(text: stop.notes ?? '');

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Stop', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CUSTOMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
              const SizedBox(height: 4),
              TextField(
                controller: customerCtrl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF2F5F3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              const Text('PHONE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
              const SizedBox(height: 4),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF2F5F3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              const Text('ADDRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
              const SizedBox(height: 4),
              TextField(
                controller: addressCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF2F5F3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              const Text('NOTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
              const SizedBox(height: 4),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF2F5F3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updated = stop.copyWith(
                customerName: customerCtrl.text.trim(),
                customerPhone: phoneCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
              );
              Navigator.pop(dlgCtx);
              widget.bloc.add(EditRouteStop(updated));
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showStopsDrawer(BuildContext context, RiderBatchActiveDelivery state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (drawerCtx) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D18) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Stops (${state.totalStops})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${state.completedCount} done \u2022 ${state.failedCount} failed',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: state.orderedStops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final stop = state.orderedStops[index];
                    final isActive = index == state.currentStopIndex;

                    Color statusColor = Colors.grey;
                    String statusLabel = 'Pending';
                    if (stop.isDelivered) {
                      statusColor = secondaryColor;
                      statusLabel = 'Delivered';
                    } else if (stop.isFailed) {
                      statusColor = Colors.red;
                      statusLabel = 'Failed';
                    } else if (isActive) {
                      statusColor = primaryColor;
                      statusLabel = 'Active';
                    }

                    return ListTile(
                      dense: true,
                      tileColor: isActive
                          ? primaryColor.withValues(alpha: 0.08)
                          : (isDark ? const Color(0xFF1B2922) : const Color(0xFFF2F5F3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isActive ? primaryColor : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: statusColor,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        stop.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        stop.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(drawerCtx);
                        widget.bloc.add(SelectStopManually(index));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
