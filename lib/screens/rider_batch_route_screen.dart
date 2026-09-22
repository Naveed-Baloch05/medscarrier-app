import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../bloc/rider_batch/rider_batch_bloc.dart';
import '../bloc/rider_batch/rider_batch_event.dart';
import '../bloc/rider_batch/rider_batch_state.dart';
import '../models/delivery_route_model.dart';
import 'rider_batch_active_screen.dart';

class RiderBatchRouteScreen extends StatefulWidget {
  const RiderBatchRouteScreen({
    super.key,
    required this.bloc,
    required this.overviewState,
  });

  final RiderBatchBloc bloc;
  final RiderBatchRouteOverview overviewState;

  @override
  State<RiderBatchRouteScreen> createState() => _RiderBatchRouteScreenState();
}

class _RiderBatchRouteScreenState extends State<RiderBatchRouteScreen> {
  static const Color primaryColor = Color(0xFF0F7253);
  static const Color secondaryColor = Color(0xFF32C787);

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  late RiderBatchRouteOverview _currentOverview;

  @override
  void initState() {
    super.initState();
    _currentOverview = widget.overviewState;
    _buildMapElements(_currentOverview);
  }

  void _buildMapElements(RiderBatchRouteOverview state) {
    _markers.clear();
    _polylines.clear();

    // 1. Origin Marker (Rider / Pharmacy start point)
    _markers.add(
      Marker(
        markerId: const MarkerId('origin_marker'),
        position: state.origin,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: state.pharmacyName ?? 'Start Point',
          snippet: 'Route Origin',
        ),
      ),
    );

    // 2. Numbered Stop Markers (1, 2, 3, 4, 5...)
    for (int i = 0; i < state.orderedStops.length; i++) {
      final stop = state.orderedStops[i];
      if (stop.latLng != null) {
        _markers.add(
          Marker(
            markerId: MarkerId('stop_${stop.id}'),
            position: stop.latLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              i == 0 ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: 'Stop #${i + 1}: ${stop.customerName}',
              snippet: stop.address,
            ),
          ),
        );
      }
    }

    // 3. Polyline connecting origin and all stops
    if (state.routePolylines.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('optimized_batch_route'),
          points: state.routePolylines,
          color: primaryColor,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }
  }

  void _fitMapBounds() {
    if (_mapController == null || _currentOverview.routePolylines.isEmpty) return;

    final points = _currentOverview.routePolylines;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  // ============================================================
  // PHASE 16: REFINE ROUTE MODAL
  // ============================================================

  void _showRefineRouteModal(BuildContext context) {
    final stopsList = List<RouteStopModel>.from(_currentOverview.orderedStops);

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
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D18) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Refine Route Sequence',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Drag items to adjust delivery sequence',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(modalCtx);
                            widget.bloc.add(RefineRouteSequence(stopsList));
                          },
                          child: const Text('Apply', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: stopsList.length,
                      onReorder: (oldIndex, newIndex) {
                        setModalState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = stopsList.removeAt(oldIndex);
                          stopsList.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final stop = stopsList[index];
                        return Container(
                          key: ValueKey(stop.id),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C2A22) : const Color(0xFFF2F5F3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: primaryColor,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(stop.customerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                    Text(stop.address, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              const Icon(Icons.drag_handle, color: Colors.grey),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: widget.bloc,
      child: BlocConsumer<RiderBatchBloc, RiderBatchState>(
        listener: (context, state) {
          if (state is RiderBatchActiveDelivery) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RiderBatchActiveScreen(
                  bloc: widget.bloc,
                ),
              ),
            );
          } else if (state is RiderBatchRouteOverview) {
            setState(() {
              _currentOverview = state;
              _buildMapElements(state);
            });
          }
        },
        builder: (context, state) {
          final overview = state is RiderBatchRouteOverview ? state : _currentOverview;

          return Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  // 1. Google Map
                  Positioned.fill(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: overview.origin,
                        zoom: 13,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        Future.delayed(const Duration(milliseconds: 300), _fitMapBounds);
                      },
                    ),
                  ),

                  // 2. Top Header Bar
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: _buildTopHeader(context, overview, isDark),
                  ),

                  // 3. Floating Recenter Map Button
                  Positioned(
                    right: 16,
                    bottom: 330,
                    child: CircleAvatar(
                      backgroundColor: isDark ? const Color(0xFF131D18) : Colors.white,
                      radius: 22,
                      child: IconButton(
                        icon: const Icon(Icons.crop_free, color: primaryColor),
                        onPressed: _fitMapBounds,
                      ),
                    ),
                  ),

                  // 4. Bottom Stops & Confirm Route Sheet
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildBottomPanel(context, overview, isDark),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    RiderBatchRouteOverview state,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D18) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryColor.withValues(alpha: 0.12),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: primaryColor, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Optimized Delivery Route',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${state.stopCount} stops organized for shortest path',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Refine Route Button (Phase 16)
          OutlinedButton.icon(
            onPressed: () => _showRefineRouteModal(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: const BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            icon: const Icon(Icons.tune, size: 14),
            label: const Text('Refine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(
    BuildContext context,
    RiderBatchRouteOverview state,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D18) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Dynamic Summary Banner (Phase 15: e.g. "26 min · 5 stops · 3.6 miles")
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2922) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: secondaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  state.summaryText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Stops Preview List (Height-constrained)
          SizedBox(
            height: 120,
            child: ListView.separated(
              itemCount: state.orderedStops.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final stop = state.orderedStops[index];
                return _buildStopItem(context, stop, index + 1, isDark);
              },
            ),
          ),

          const SizedBox(height: 14),

          // Confirm & Start Route Action Button (Phase 17)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.bloc.add(const ConfirmOptimizedRoute());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.navigation_rounded),
              label: const Text(
                'Confirm & Start Delivery Route',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopItem(
    BuildContext context,
    RouteStopModel stop,
    int index,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D25) : const Color(0xFFF9FAF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: primaryColor,
            child: Text(
              '$index',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.customerName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  stop.address,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (stop.coldChain)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.ac_unit, size: 14, color: Colors.cyan),
            ),
        ],
      ),
    );
  }
}
