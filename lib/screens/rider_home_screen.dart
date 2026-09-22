import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../bloc/rider_batch/rider_batch_bloc.dart';
import '../bloc/rider_batch/rider_batch_event.dart';
import '../bloc/rider_batch/rider_batch_state.dart';
import '../bloc/rider_home/rider_home_bloc.dart';
import '../bloc/rider_home/rider_home_event.dart';
import '../bloc/rider_home/rider_home_state.dart';
import '../core/services/rider_batch_service.dart';
import '../models/delivery_route_model.dart';
import '../models/order_model.dart';
import 'rider_batch_active_screen.dart';
import 'rider_batch_scan_screen.dart';
import 'rider_deliveries_screen.dart';
import 'rider_map_screen.dart';
import 'rider_profile_screen.dart';

void main() {
  runApp(const MedsCarrierRiderApp());
}

class MedsCarrierRiderApp extends StatelessWidget {
  const MedsCarrierRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MedsCarrier Rider',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F5F3),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0F7253),
          secondary: Color(0xFF32C787),
          surface: Colors.white,
          onSurface: Color(0xFF191C1B),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B120E),
        cardColor: const Color(0xFF131D18),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF32C787),
          secondary: Color(0xFF0F7253),
          surface: Color(0xFF131D18),
          onSurface: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const RiderHomeScreen(riderId: 'mock-rider-001'),
    );
  }
}

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({
    super.key,
    required this.riderId,
    this.bloc,
  });

  final String riderId;
  final RiderHomeBloc? bloc;

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  late final RiderHomeBloc _bloc;
  bool _internalBloc = false;

  GoogleMapController? _mapController;
  LatLng? _currentRiderLocation;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<DeliveryRouteModel?>? _routeSubscription;
  DeliveryRouteModel? _activeRoute;

  @override
  void initState() {
    super.initState();
    if (widget.bloc != null) {
      _bloc = widget.bloc!;
    } else {
      _internalBloc = true;
      _bloc = RiderHomeBloc()..add(LoadRiderHome(widget.riderId));
    }
    _initLocationAndRoute();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _routeSubscription?.cancel();
    _mapController?.dispose();
    if (_internalBloc) {
      _bloc.close();
    }
    super.dispose();
  }

  Future<void> _initLocationAndRoute() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _currentRiderLocation = LatLng(pos.latitude, pos.longitude);
        });
      }

      await _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).listen((p) {
        if (mounted) {
          setState(() {
            _currentRiderLocation = LatLng(p.latitude, p.longitude);
          });
        }
      });
    } catch (_) {}

    try {
      final active =
          await RiderBatchService.instance.getActiveRouteForRider(widget.riderId);
      if (mounted && active != null) {
        setState(() {
          _activeRoute = active;
        });
      }
    } catch (_) {}

    await _routeSubscription?.cancel();
    _routeSubscription = RiderBatchService.instance
        .streamActiveRouteForRider(widget.riderId)
        .listen((active) {
      if (mounted) {
        setState(() {
          _activeRoute = active;
        });
      }
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatTimeOnRoad(List<OrderModel> completedToday) {
    int totalMinutes = 0;
    for (final order in completedToday) {
      if (order.deliveryTimeMinutes != null) {
        totalMinutes += order.deliveryTimeMinutes!;
      }
    }
    if (totalMinutes == 0) return '0:00';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return '$hours:${mins.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider<RiderHomeBloc>.value(
      value: _bloc,
      child: BlocBuilder<RiderHomeBloc, RiderHomeState>(
        builder: (context, state) {
            return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: _buildBody(context, state, isDark),
            ),
            floatingActionButton: (_activeRoute != null && _activeRoute!.isActive)
                ? null
                : FloatingActionButton.extended(
                    onPressed: () => _showCreateRouteModal(context),
                    backgroundColor: const Color(0xFF0F7253),
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add_road_rounded),
                    label: const Text(
                      '+ Create Route',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
            bottomNavigationBar: _buildBottomNav(context, isDark, theme),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RiderHomeState state,
    bool isDark,
  ) {
    if (state is RiderHomeLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0F7253)),
      );
    }

    if (state is RiderHomeError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF191C1B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF8B9B94) : Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () =>
                    _bloc.add(LoadRiderHome(widget.riderId)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F7253),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is! RiderHomeLoaded) {
      return const SizedBox.shrink();
    }

    final rider = state.rider;
    final activeOrder = state.activeOrder;
    final upcomingOrders = state.upcomingOrders;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final completedToday = state.orders
        .where((o) =>
            o.isCompleted &&
            o.deliveredAt != null &&
            o.deliveredAt!.isAfter(todayStart))
        .toList();

    final timeOnRoad = _formatTimeOnRoad(completedToday);
    final distanceText =
        state.totalDistanceKm > 0
            ? state.totalDistanceKm.toStringAsFixed(1)
            : '0.0';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, rider.fullName, rider.online, isDark),
                const SizedBox(height: 12),
                _buildMapHeroCard(context, isDark),
                const SizedBox(height: 16),
                _buildMetricsRow(
                  context,
                  '${state.todayCompletedCount}',
                  distanceText,
                  timeOnRoad,
                ),
                if (activeOrder != null && (_activeRoute == null || !_activeRoute!.isActive)) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C4DFF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Assigned delivery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF191C1B),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        if (activeOrder != null && (_activeRoute == null || !_activeRoute!.isActive))
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: _buildActiveDeliveryCard(context, activeOrder, isDark),
            ),
          ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next up',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF191C1B),
                  ),
                ),
                Text(
                  '${upcomingOrders.length} assigned',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF8C9894) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: upcomingOrders.isEmpty
              ? SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF131D18)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'No pending deliveries',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF8B9B94)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = upcomingOrders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildNextUpItem(context, order, isDark),
                      );
                    },
                    childCount: upcomingOrders.length,
                  ),
                ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildMapHeroCard(BuildContext context, bool isDark) {
    final hasActiveRoute = _activeRoute != null;
    final isRouteActive = hasActiveRoute && _activeRoute!.isActive;
    final isRoutePlanning = hasActiveRoute &&
        (_activeRoute!.status == 'draft' ||
            _activeRoute!.status == 'building' ||
            _activeRoute!.status == 'optimized');

    final Set<Marker> markers = {};

    if (_currentRiderLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_rider_loc'),
          position: _currentRiderLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    if (hasActiveRoute) {
      for (int i = 0; i < _activeRoute!.stops.length; i++) {
        final stop = _activeRoute!.stops[i];
        if (stop.latLng != null) {
          markers.add(
            Marker(
              markerId: MarkerId('route_stop_${stop.id}'),
              position: stop.latLng!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                stop.isDelivered
                    ? BitmapDescriptor.hueGreen
                    : BitmapDescriptor.hueOrange,
              ),
              infoWindow: InfoWindow(
                title: 'Stop #${stop.sequence}: ${stop.customerName}',
                snippet: stop.address,
              ),
            ),
          );
        }
      }
    }

    final gpsCoordText = _currentRiderLocation != null
        ? '${_currentRiderLocation!.latitude.toStringAsFixed(4)}, ${_currentRiderLocation!.longitude.toStringAsFixed(4)}'
        : 'Acquiring GPS...';

    // Find the next pending stop on active route if available
    RouteStopModel? nextPendingStop;
    if (isRouteActive && _activeRoute!.stops.isNotEmpty) {
      for (final s in _activeRoute!.stops) {
        if (s.isPending) {
          nextPendingStop = s;
          break;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D18) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Google Map View
            SizedBox(
              height: hasActiveRoute ? 180 : 140,
              width: double.infinity,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentRiderLocation ?? const LatLng(33.6844, 73.0479),
                      zoom: hasActiveRoute ? 13 : 14,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    markers: markers,
                    onMapCreated: (ctrl) {
                      _mapController = ctrl;
                    },
                  ),
                  // GPS Live Badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location, size: 12, color: Color(0xFF32C787)),
                          const SizedBox(width: 4),
                          Text(
                            'GPS: $gpsCoordText',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Recenter button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      backgroundColor: isDark ? const Color(0xFF131D18) : Colors.white,
                      radius: 16,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.crop_free, size: 18, color: Color(0xFF0F7253)),
                        onPressed: () {
                          if (_currentRiderLocation != null && _mapController != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newLatLngZoom(_currentRiderLocation!, 15),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Route Content & Workflow Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRouteActive) ...[
                    // --- CASE A: ROUTE IN PROGRESS ---
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF32C787)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, size: 8, color: Color(0xFF0F7253)),
                              SizedBox(width: 5),
                              Text(
                                'ROUTE IN PROGRESS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F7253),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _activeRoute!.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_activeRoute!.deliveredCount} / ${_activeRoute!.totalStops} Stops Completed',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${_activeRoute!.pendingCount} remaining',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF8B9B94) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _activeRoute!.totalStops > 0
                            ? (_activeRoute!.deliveredCount / _activeRoute!.totalStops)
                            : 0.0,
                        minHeight: 7,
                        backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF32C787)),
                      ),
                    ),
                    if (nextPendingStop != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1B2A22) : const Color(0xFFF3FAF6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF32C787).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.near_me_rounded, size: 18, color: Color(0xFF0F7253)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Next: Stop #${nextPendingStop.sequence} \u2022 ${nextPendingStop.customerName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    nextPendingStop.address,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (nextPendingStop.coldChain)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Text('❄', style: TextStyle(fontSize: 14)),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RiderBatchActiveScreen(
                                bloc: RiderBatchBloc()
                                  ..add(ResumeActiveRoute(_activeRoute!)),
                              ),
                            ),
                          ).then((_) => _initLocationAndRoute());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F7253),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.navigation_rounded, size: 20),
                        label: const Text(
                          'RESUME ROUTE',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ] else if (isRoutePlanning) ...[
                    // --- CASE B: ROUTE IN SETUP / PLANNING ---
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade400),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 8, color: Colors.amber.shade900),
                              const SizedBox(width: 5),
                              Text(
                                'ROUTE IN SETUP',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.amber.shade900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _activeRoute!.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_activeRoute!.totalStops} Stops Added',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activeRoute!.status == 'optimized'
                          ? 'Route is optimized and ready to launch.'
                          : 'Continue scanning medication packages to finalize stops.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_activeRoute!.status == 'optimized') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RiderBatchActiveScreen(
                                  bloc: RiderBatchBloc()
                                    ..add(ResumeActiveRoute(_activeRoute!)),
                                ),
                              ),
                            ).then((_) => _initLocationAndRoute());
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RiderBatchScanScreen(
                                  riderId: widget.riderId,
                                  route: _activeRoute,
                                  pharmacyId: _activeRoute!.pharmacyId,
                                  pharmacyName: _activeRoute!.pharmacyName,
                                ),
                              ),
                            ).then((_) => _initLocationAndRoute());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F7253),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(
                          _activeRoute!.status == 'optimized'
                              ? Icons.play_arrow_rounded
                              : Icons.qr_code_scanner_rounded,
                          size: 20,
                        ),
                        label: Text(
                          _activeRoute!.status == 'optimized'
                              ? 'REVIEW & START ROUTE'
                              : 'CONTINUE SCANNING',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // --- CASE C: NO ACTIVE ROUTE (READY TO START) ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_road_rounded,
                            size: 24,
                            color: Color(0xFF0F7253),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ready for Delivery Shift',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Create a route, scan prescription packages, and get your optimized delivery stops.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF8B9B94) : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _showCreateRouteModal(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F7253),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text(
                          'CREATE ROUTE',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
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

  void _showCreateRouteModal(BuildContext context) {
    final now = DateTime.now();
    DateTime selectedDate = DateTime(now.year, now.month, now.day);
    String dateSelection = 'Today';
    bool carryPrevious = false;
    final nameController = TextEditingController(
      text: 'Route - ${_formatDateShort(now)}',
    );

    final homeNav = Navigator.of(context);
    final homeMessenger = ScaffoldMessenger.of(context);
    final batchBloc = RiderBatchBloc();
    bool isNavigatingToScan = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return BlocProvider<RiderBatchBloc>.value(
          value: batchBloc,
          child: BlocConsumer<RiderBatchBloc, RiderBatchState>(
            listener: (sheetCtx, state) {
              if (state is RiderBatchScanning && state.route != null) {
                isNavigatingToScan = true;
                debugPrint('=== [NAVIGATING TO SCAN SCREEN] ===');
                debugPrint('Route ID: ${state.route!.id}, Name: ${state.route!.name}');

                if (mounted) {
                  setState(() {
                    _activeRoute = state.route;
                  });
                }

                if (modalCtx.mounted) {
                  Navigator.of(modalCtx).pop();
                }

                if (mounted) {
                  homeNav.push(
                    MaterialPageRoute(
                      builder: (_) => RiderBatchScanScreen(
                        riderId: widget.riderId,
                        route: state.route,
                        pharmacyId: state.pharmacyId ?? state.route?.pharmacyId,
                        pharmacyName: state.pharmacyName ?? state.route?.pharmacyName,
                        bloc: batchBloc,
                      ),
                    ),
                  ).then((_) {
                    batchBloc.close();
                    if (mounted) _initLocationAndRoute();
                  });
                }
              } else if (state is RiderBatchError) {
                debugPrint('=== [CREATE ROUTE ERROR]: ${state.message} ===');
                homeMessenger.showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (sheetCtx, state) {
              final isCreating = state is RiderBatchCreatingRoute;

              return StatefulBuilder(
                builder: (innerContext, setModalState) {
                  final theme = Theme.of(innerContext);
                  final isDark = theme.brightness == Brightness.dark;

                  return Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.of(innerContext).viewInsets.bottom + 24,
                    ),
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
                            width: 40,
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F7253).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_road_rounded, color: Color(0xFF0F7253), size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create Delivery Route',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Set up your run and scan delivery boxes',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Route Name
                        const Text(
                          'ROUTE NAME (OPTIONAL)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Morning Delivery Run',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1C2A22) : const Color(0xFFF2F5F3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Route Date Selector
                        const Text(
                          'ROUTE DATE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: Center(
                                  child: Text(
                                    'Today (${_formatDateShort(now)})',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                selected: dateSelection == 'Today',
                                selectedColor: const Color(0xFF0F7253),
                                labelStyle: TextStyle(
                                  color: dateSelection == 'Today'
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setModalState(() {
                                      dateSelection = 'Today';
                                      selectedDate = DateTime(now.year, now.month, now.day);
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(
                                  child: Text('Tomorrow', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                selected: dateSelection == 'Tomorrow',
                                selectedColor: const Color(0xFF0F7253),
                                labelStyle: TextStyle(
                                  color: dateSelection == 'Tomorrow'
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    final tomorrow = now.add(const Duration(days: 1));
                                    setModalState(() {
                                      dateSelection = 'Tomorrow';
                                      selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: innerContext,
                                initialDate: selectedDate,
                                firstDate: now.subtract(const Duration(days: 7)),
                                lastDate: now.add(const Duration(days: 60)),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  dateSelection = 'Custom';
                                  selectedDate = picked;
                                });
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: dateSelection == 'Custom' ? const Color(0xFF0F7253) : Colors.grey,
                              side: BorderSide(
                                color: dateSelection == 'Custom' ? const Color(0xFF0F7253) : Colors.grey.shade400,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.calendar_month, size: 16),
                            label: Text(
                              dateSelection == 'Custom'
                                  ? 'Selected Date: ${_formatDateShort(selectedDate)}'
                                  : 'Pick a Specific Date',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Carry Previous Stops
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Carry Previous Stops', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          subtitle: const Text('Include pending stops from earlier runs', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          value: carryPrevious,
                          activeTrackColor: const Color(0xFF0F7253),
                          onChanged: (val) {
                            setModalState(() {
                              carryPrevious = val;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Confirm Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isCreating
                                ? null
                                : () {
                                    final riderId = widget.riderId.trim();
                                    if (riderId.isEmpty) {
                                      homeMessenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Cannot create route: Rider ID is missing.'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }

                                    final rawName = nameController.text.trim();
                                    final routeName = rawName.isNotEmpty
                                        ? rawName
                                        : 'Route - ${_formatDateShort(selectedDate)}';

                                    debugPrint('=== [CONFIRM & START SCANNING TAPPED] ===');
                                    debugPrint('Rider: $riderId, Name: $routeName, Date: $selectedDate, Carry: $carryPrevious');

                                    batchBloc.add(
                                      CreateNewRoute(
                                        riderId: riderId,
                                        date: selectedDate,
                                        name: routeName,
                                        startLocation: _currentRiderLocation,
                                        carryPreviousStops: carryPrevious,
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F7253),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: isCreating
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Creating Route...',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Confirm & Start Scanning',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    ).then((_) {
      if (!isNavigatingToScan && !batchBloc.isClosed) {
        batchBloc.close();
      }
    });
  }

  static String _formatDateShort(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  Widget _buildHeader(
    BuildContext context,
    String name,
    bool isOnline,
    bool isDark,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isDark
              ? const Color(0xFF1A382B)
              : const Color(0xFF0F7253),
          child: Text(
            _initials(name),
            style: TextStyle(
              color: isDark ? const Color(0xFF32C787) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF8B9B94)
                      : Colors.grey,
                ),
              ),
              Text(
                name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF191C1B),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            _bloc.add(RiderHomeToggleOnline(widget.riderId, !isOnline));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOnline
                  ? (isDark
                      ? const Color(0xFF10281E)
                      : const Color(0xFFDCEFE6))
                  : (isDark
                      ? const Color(0xFF1D2622)
                      : const Color(0xFFF0F0F0)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFF32C787)
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOnline
                        ? (isDark
                            ? const Color(0xFF32C787)
                            : const Color(0xFF0F7253))
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(
    BuildContext context,
    String deliveries,
    String distance,
    String timeOnRoad,
  ) {
    return Row(
      children: [
        _buildMetricCard(context, deliveries, 'Deliveries'),
        const SizedBox(width: 8),
        _buildMetricCard(context, distance, 'Distance', unit: 'km'),
        const SizedBox(width: 8),
        _buildMetricCard(context, timeOnRoad, 'On road', unit: 'h'),
      ],
    );
  }

  Widget _buildActiveDeliveryCard(
    BuildContext context,
    OrderModel order,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    final String statusLabel;
    final Color statusColor;
    switch (order.status) {
      case 'Picked Up':
        statusLabel = 'Picked up';
        statusColor = const Color(0xFFFFA726);
        break;
      case 'On the Way':
        statusLabel = 'On the way';
        statusColor = const Color(0xFF7C4DFF);
        break;
      default:
        statusLabel = order.status;
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '#${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF32C787),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF133327)
                      : const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront,
                  size: 18,
                  color: Color(0xFF32C787),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PICKUP',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      order.pharmacyName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      order.pickupAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 2, bottom: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 17,
                  child: Column(
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        width: 2,
                        height: 4,
                        color: Colors.grey.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1D2622)
                      : const Color(0xFFF0F0F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DROP-OFF',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      order.customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      order.dropoffAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F1814)
                  : const Color(0xFFF7F9F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      RichText(
                        text: TextSpan(
                          text: '${order.distanceKm?.toStringAsFixed(1) ?? '--'} ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          children: const [
                            TextSpan(
                              text: 'km',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Distance',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        order.estimatedTime ?? '--',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'ETA',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (order.controlledDrug)
            _buildSafetyToggleTile(
              context,
              title: 'Carrying a Controlled Drug',
              subtitle: 'Signature required at handover',
              icon: Icons.verified_user_outlined,
              accentColor: const Color(0xFFFFB74D),
              bgColor: isDark
                  ? const Color(0xFF282115)
                  : const Color(0xFFFAF0E6),
              borderColor: isDark
                  ? const Color(0xFF42331C)
                  : const Color(0xFFF5DDC2),
              value: true,
              onChanged: (val) {
                _bloc.add(RiderHomeConfirmDelivery(
                  orderId: order.id,
                  cdConfirmed: val,
                  coldChainConfirmed: true,
                ));
              },
            ),
          if (order.controlledDrug) const SizedBox(height: 8),
          if (order.coldChain)
            _buildSafetyToggleTile(
              context,
              title: 'Carrying cold-chain medicine',
              subtitle: 'Keep in cool box \u2022 2\u20138\u00B0C',
              icon: Icons.ac_unit,
              accentColor: const Color(0xFF4DD0E1),
              bgColor: isDark
                  ? const Color(0xFF12282C)
                  : const Color(0xFFE6F7F9),
              borderColor: isDark
                  ? const Color(0xFF193F46)
                  : const Color(0xFFC3EEF3),
              value: true,
              onChanged: (val) {
                _bloc.add(RiderHomeConfirmDelivery(
                  orderId: order.id,
                  cdConfirmed: true,
                  coldChainConfirmed: val,
                ));
              },
            ),
          if (order.coldChain) const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF32C787)
                          : const Color(0xFF0F7253),
                      foregroundColor: isDark
                          ? const Color(0xFF0B120E)
                          : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiderMapScreen(
                            riderId: widget.riderId,
                            initialOrderId: order.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    label: const Text(
                      'Navigate',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF19241E)
                          : const Color(0xFFF5F7F6),
                      side: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _showCompleteDeliveryDialog(context, order, isDark);
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: theme.colorScheme.onSurface,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Complete',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Confirm delivery',
                            style: TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ),
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

  void _showCompleteDeliveryDialog(
    BuildContext context,
    OrderModel order,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF131D18) : Colors.white,
          title: Text(
            'Complete Delivery',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF191C1B),
            ),
          ),
          content: Text(
            'Mark delivery #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)} as delivered?',
            style: TextStyle(
              color: isDark ? const Color(0xFF8B9B94) : Colors.grey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _bloc.add(RiderHomeOrderStatusChanged(
                  order.id,
                  'Delivered',
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delivery marked as completed!'),
                    backgroundColor: Color(0xFF0F7253),
                  ),
                );
              },
              child: const Text(
                'Complete',
                style: TextStyle(
                  color: Color(0xFF0F7253),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark, ThemeData theme) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor:
          isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253),
      unselectedItemColor: Colors.grey,
      backgroundColor: theme.cardColor,
      elevation: 8,
      onTap: (index) {
        if (index == 0) return;
        if (index == 1) {
          // Tab 1: In-App Map / Navigation
          if (_activeRoute != null &&
              (_activeRoute!.isActive ||
                  _activeRoute!.status == 'optimized' ||
                  _activeRoute!.status == 'in_progress')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RiderBatchActiveScreen(
                  bloc: RiderBatchBloc()..add(ResumeActiveRoute(_activeRoute!)),
                ),
              ),
            ).then((_) => _initLocationAndRoute());
            return;
          }

          final homeState = context.read<RiderHomeBloc>().state;
          String? activeOrderId;
          if (homeState is RiderHomeLoaded) {
            try {
              final activeOrder = homeState.orders.firstWhere((o) => o.isActive);
              activeOrderId = activeOrder.id;
            } catch (_) {}
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RiderMapScreen(
                riderId: widget.riderId,
                initialOrderId: activeOrderId,
              ),
            ),
          ).then((_) => _initLocationAndRoute());
          return;
        }
        if (index == 2) {
          final homeState = context.read<RiderHomeBloc>().state;
          List<OrderModel>? initialOrders;
          if (homeState is RiderHomeLoaded) {
            initialOrders = homeState.orders;
          }
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => RiderDeliveriesScreen(
                        riderId: widget.riderId,
                        initialOrders: initialOrders,
                      )));
          return;
        }
        if (index == 3) {
          final homeState = context.read<RiderHomeBloc>().state;
          Map<String, dynamic>? initialData;
          if (homeState is RiderHomeLoaded) {
            initialData = homeState.rider.toJson();
          }
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => RiderProfileScreen(
                        riderId: widget.riderId,
                        initialData: initialData,
                      )));
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          activeIcon: Icon(Icons.local_shipping),
          label: 'Deliveries',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String value,
    String label, {
    String? unit,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D18) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? Colors.white : const Color(0xFF191C1B),
                ),
                children: [
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyToggleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: accentColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNextUpItem(
    BuildContext context,
    OrderModel order,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF12241C)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.storefront,
              size: 18,
              color: Color(0xFF32C787),
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
                        '#${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length).toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (order.coldChain) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF12282C)
                              : const Color(0xFFE0F7FA),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF4DD0E1),
                            width: 0.6,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.ac_unit,
                              size: 10,
                              color: Color(0xFF4DD0E1),
                            ),
                            SizedBox(width: 2),
                            Text(
                              '2\u20138\u00B0C',
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF4DD0E1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.pharmacyName} \u2022 ${order.status}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            order.distance ?? '--',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
    );
  }
}
