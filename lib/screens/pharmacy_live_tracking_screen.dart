import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../bloc/pharmacy_tracking/pharmacy_tracking_bloc.dart';
import '../bloc/pharmacy_tracking/pharmacy_tracking_event.dart';
import '../bloc/pharmacy_tracking/pharmacy_tracking_state.dart';
import '../models/delivery_route_model.dart';
import '../models/order_model.dart';
import '../widgets/pharmacy_order_status_badge.dart';

class PharmacyLiveTrackingScreen extends StatelessWidget {
  const PharmacyLiveTrackingScreen({
    super.key,
    required this.pharmacyId,
    this.riderId = '',
    this.riderName = '',
    this.routeId,
    this.initialOrderId,
  });

  final String pharmacyId;
  final String riderId;
  final String riderName;
  final String? routeId;
  final String? initialOrderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PharmacyTrackingBloc>(
      create: (_) => PharmacyTrackingBloc()
        ..add(
          InitPharmacyTracking(
            pharmacyId: pharmacyId,
            riderId: riderId,
            routeId: routeId,
            initialOrderId: initialOrderId,
          ),
        ),
      child: _PharmacyLiveTrackingView(
        pharmacyId: pharmacyId,
        riderId: riderId,
        riderName: riderName,
      ),
    );
  }
}

class _PharmacyLiveTrackingView extends StatefulWidget {
  const _PharmacyLiveTrackingView({
    required this.pharmacyId,
    required this.riderId,
    required this.riderName,
  });

  final String pharmacyId;
  final String riderId;
  final String riderName;

  @override
  State<_PharmacyLiveTrackingView> createState() =>
      _PharmacyLiveTrackingViewState();
}

class _PharmacyLiveTrackingViewState extends State<_PharmacyLiveTrackingView> {
  GoogleMapController? _mapController;
  bool _didInitialCameraFit = false;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _fitAllMarkers(Set<Marker> markers) {
    if (_mapController == null || markers.isEmpty) return;

    if (markers.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(markers.first.position, 15),
      );
      return;
    }

    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final m in markers) {
      if (m.position.latitude < minLat) minLat = m.position.latitude;
      if (m.position.latitude > maxLat) maxLat = m.position.latitude;
      if (m.position.longitude < minLng) minLng = m.position.longitude;
      if (m.position.longitude > maxLng) maxLng = m.position.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 70),
    );
  }

  void _copyPhone(String phone) {
    if (phone.isEmpty) return;
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied phone number $phone to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C1310) : Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Delivery Tracking',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.riderName.isNotEmpty ? 'Rider: ${widget.riderName}' : 'Monitoring assigned rider',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Fit route on map',
            onPressed: () {
              final state = context.read<PharmacyTrackingBloc>().state;
              if (state is PharmacyTrackingLoaded) {
                _fitAllMarkers(state.markers);
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<PharmacyTrackingBloc, PharmacyTrackingState>(
        listener: (context, state) {
          if (state is PharmacyTrackingLoaded && !_didInitialCameraFit && state.markers.isNotEmpty) {
            _didInitialCameraFit = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitAllMarkers(state.markers);
            });
          }
        },
        builder: (context, state) {
          if (state is PharmacyTrackingLoading || state is PharmacyTrackingInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PharmacyTrackingError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PharmacyTrackingBloc>().add(
                              InitPharmacyTracking(
                                pharmacyId: widget.pharmacyId,
                                riderId: widget.riderId,
                              ),
                            );
                      },
                      child: const Text('Retry Tracking'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is! PharmacyTrackingLoaded) {
            return const SizedBox.shrink();
          }

          final initialPos = state.liveLocation?.latLng ??
              state.rider?.latLng ??
              state.pharmacyLocation ??
              (state.orders.isNotEmpty && state.orders.first.dropoffLatLng != null
                  ? state.orders.first.dropoffLatLng!
                  : const LatLng(51.5074, -0.1278));

          return Stack(
            children: [
              // 1. Google Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialPos,
                  zoom: 14.0,
                ),
                markers: state.markers,
                polylines: state.polylines,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (state.markers.isNotEmpty) {
                    _fitAllMarkers(state.markers);
                  }
                },
              ),

              // 2. Floating Map Action Buttons
              PositionTileControls(
                onFitAll: () => _fitAllMarkers(state.markers),
                onRiderFocus: () {
                  final pos = state.liveLocation?.latLng ?? state.rider?.latLng;
                  if (pos != null && _mapController != null) {
                    _mapController!.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
                  }
                },
              ),

              // 3. Bottom Assigned Deliveries Sheet
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomDeliveriesSheet(context, state, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomDeliveriesSheet(
    BuildContext context,
    PharmacyTrackingLoaded state,
    bool isDark,
  ) {
    final rider = state.rider;
    final total = state.totalCount;
    final delivered = state.deliveredCount;
    final inTransit = state.inTransitCount;
    final failed = state.failedCount;

    final progressRatio = total > 0 ? (delivered / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      constraints: const BoxConstraints(maxHeight: 380),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141F1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // RIDER INFO BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F7253).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delivery_dining_rounded,
                      color: Color(0xFF0F7253),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Rider: ${rider?.fullName.isNotEmpty == true ? rider!.fullName : (state.route?.riderName.isNotEmpty == true ? state.route!.riderName : (widget.riderName.isNotEmpty ? widget.riderName : 'Assigned Rider'))}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (state.routeStatusDisplay == 'Completed'
                                        ? Colors.green
                                        : (state.routeStatusDisplay == 'Delivering'
                                            ? const Color(0xFF0F7253)
                                            : Colors.orange))
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                state.routeStatusDisplay.toUpperCase(),
                                style: TextStyle(
                                  color: state.routeStatusDisplay == 'Completed'
                                      ? Colors.green
                                      : (state.routeStatusDisplay == 'Delivering'
                                          ? const Color(0xFF0F7253)
                                          : Colors.orange.shade800),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rider?.phone.isNotEmpty == true
                              ? rider!.phone
                              : 'Status: ${state.routeStatusDisplay} • In Transit',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rider?.phone.isNotEmpty == true)
                    IconButton(
                      onPressed: () => _copyPhone(rider!.phone),
                      icon: const Icon(Icons.phone_rounded, color: Color(0xFF0F7253)),
                      tooltip: 'Copy rider phone',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF0F7253).withValues(alpha: 0.12),
                      ),
                    ),
                ],
              ),
),

            // LIVE CURRENT DELIVERY PROGRESS
            if (state.liveLocation != null &&
                state.liveLocation!.isActivelyDelivering) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F7253).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0F7253).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delivery_dining_rounded,
                        color: Color(0xFF0F7253),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stop ${state.liveLocation!.stopNumber} of ${state.liveLocation!.totalStops}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            if (state.liveLocation!.currentCustomerName
                                    .isNotEmpty ||
                                state.liveLocation!.currentAddress.isNotEmpty)
                              Text(
                                '${state.liveLocation!.currentCustomerName}${state.liveLocation!.currentAddress.isNotEmpty ? ' · ${state.liveLocation!.currentAddress}' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // PROGRESS BAR & METRICS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assigned Deliveries ($total)',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(
                        'Progress: $delivered / $total completed',
                        style: const TextStyle(
                          color: Color(0xFF0F7253),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressRatio,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0F7253)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildMetricChip(
                        label: 'Delivered',
                        count: delivered,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildMetricChip(
                        label: 'In Transit',
                        count: inTransit,
                        color: Colors.deepPurple,
                      ),
                      if (failed > 0) ...[
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          label: 'Failed',
                          count: failed,
                          color: Colors.red,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // SEQUENCED STOPS OR MULTI-DELIVERY ORDER CARDS LIST
            Expanded(
              child: state.stops.isNotEmpty
                  ? ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: state.stops.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final stop = state.stops[index];
                        final isSelected = state.selectedStop?.id == stop.id;
                        final isCurrent = state.activeStop?.id == stop.id ||
                            (state.activeStop == null && !stop.isDelivered && !stop.isFailed && index == delivered);

                        return _buildRouteStopCard(
                          context,
                          stop,
                          stopNumber: stop.sequence > 0 ? stop.sequence : index + 1,
                          isSelected: isSelected,
                          isCurrent: isCurrent,
                          isDark: isDark,
                        );
                      },
                    )
                  : (state.orders.isNotEmpty
                      ? ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: state.orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final order = state.orders[index];
                            final isSelected = state.selectedOrder?.id == order.id;

                            return _buildDeliveryStopCard(
                              context,
                              order,
                              stopNumber: index + 1,
                              isSelected: isSelected,
                              isDark: isDark,
                            );
                          },
                        )
                      : const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'No deliveries found for this route',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRouteStopCard(
    BuildContext context,
    RouteStopModel stop, {
    required int stopNumber,
    required bool isSelected,
    required bool isCurrent,
    required bool isDark,
  }) {
    Color badgeColor;
    String badgeText;

    if (stop.isDelivered) {
      badgeColor = Colors.green;
      badgeText = '✓ Delivered';
    } else if (stop.isFailed) {
      badgeColor = Colors.red;
      badgeText = '✕ Failed';
    } else if (isCurrent) {
      badgeColor = Colors.cyan;
      badgeText = '● Current';
    } else {
      badgeColor = Colors.grey;
      badgeText = '○ Pending';
    }

    return InkWell(
      onTap: () {
        context.read<PharmacyTrackingBloc>().add(SelectTrackedStop(stop.id));
        final dropoff = stop.latLng;
        if (dropoff != null && _mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLngZoom(dropoff, 16));
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F7253).withValues(alpha: 0.08)
              : (isDark ? const Color(0xFF1B2922) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F7253)
                : (isCurrent
                    ? Colors.cyan
                    : (isDark ? const Color(0xFF263D33) : Colors.grey.shade200)),
            width: isSelected || isCurrent ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Stop Number Badge
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? Colors.cyan
                        : (stop.isDelivered
                            ? Colors.green
                            : (stop.isFailed
                                ? Colors.red
                                : (isSelected
                                    ? const Color(0xFF0F7253)
                                    : Colors.grey.shade700))),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stopNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stop.customerName.isNotEmpty
                        ? stop.customerName
                        : 'Customer #$stopNumber',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Customer Address & Details
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.formattedAddress.isNotEmpty
                        ? stop.formattedAddress
                        : stop.address,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Medicine Tags
                  if (stop.controlledDrug || stop.coldChain) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (stop.controlledDrug)
                          const Text(
                            '🔒 CD • ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber,
                            ),
                          ),
                        if (stop.coldChain)
                          const Text(
                            '❄️ Cold Chain (2-8°C)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.cyan,
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Failure Reason Alert
                  if (stop.isFailed &&
                      stop.failureReason != null &&
                      stop.failureReason!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Reason: ${stop.failureReason}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStopCard(
    BuildContext context,
    OrderModel order, {
    required int stopNumber,
    required bool isSelected,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        context.read<PharmacyTrackingBloc>().add(SelectTrackedOrder(order.id));
        final dropoff = order.dropoffLatLng;
        if (dropoff != null && _mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLngZoom(dropoff, 16));
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F7253).withValues(alpha: 0.08)
              : (isDark ? const Color(0xFF1B2922) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F7253)
                : (isDark ? const Color(0xFF263D33) : Colors.grey.shade200),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Stop Number Badge
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F7253) : Colors.grey.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stopNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.orderId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PharmacyOrderStatusBadge(status: order.displayStatus),
              ],
            ),
            const SizedBox(height: 6),

            // Customer Name & Address
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.dropoffAddress,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Medicine Tags
                  if (order.controlledDrug || order.coldChain) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (order.controlledDrug)
                          const Text(
                            '🔒 CD • ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber,
                            ),
                          ),
                        if (order.coldChain)
                          const Text(
                            '❄️ Cold Chain (2-8°C)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.cyan,
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Failure Reason Alert
                  if (order.isFailed && order.failureReason != null && order.failureReason!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Reason: ${order.failureReason}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PositionTileControls extends StatelessWidget {
  const PositionTileControls({
    super.key,
    required this.onFitAll,
    required this.onRiderFocus,
  });

  final VoidCallback onFitAll;
  final VoidCallback onRiderFocus;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_fit_all',
            onPressed: onFitAll,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F7253),
            tooltip: 'Fit route',
            child: const Icon(Icons.fullscreen_rounded),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'fab_rider_focus',
            onPressed: onRiderFocus,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F7253),
            tooltip: 'Focus on rider',
            child: const Icon(Icons.two_wheeler_rounded),
          ),
        ],
      ),
    );
  }
}
