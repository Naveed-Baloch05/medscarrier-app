import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../bloc/rider_map/rider_map_bloc.dart';
import '../bloc/rider_map/rider_map_event.dart';
import '../bloc/rider_map/rider_map_state.dart';
import '../core/services/rider_map_service.dart';
import '../core/utils/route_utils.dart';
import '../models/order_model.dart';

class RiderMapScreen extends StatefulWidget {
  const RiderMapScreen({super.key, this.riderId, this.initialOrderId});

  final String? riderId;
  final String? initialOrderId;

  @override
  State<RiderMapScreen> createState() => _RiderMapScreenState();
}

class _RiderMapScreenState extends State<RiderMapScreen> {
  late final RiderMapBloc _bloc;
  final List<Offset?> _signaturePoints = [];

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _currentRiderLocation;
  double? _currentHeading;
  bool _locationPermissionGranted = false;
  bool _isLoadingLocation = true;
  String? _locationError;
  bool _hasInitiallyFitMap = false;

  // Default fallback center
  static const LatLng _defaultLocation = LatLng(33.6844, 73.0479);

  @override
  void initState() {
    super.initState();
    _bloc = RiderMapBloc();
    final orderId = widget.initialOrderId?.trim();
    if (orderId != null && orderId.isNotEmpty) {
      _bloc.add(SubscribeToOrder(orderId));
    } else {
      final riderId = widget.riderId?.trim();
      if (riderId != null && riderId.isNotEmpty) {
        _bloc.add(SubscribeToMap(riderId));
      }
    }

    _initLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    _bloc.close();
    super.dispose();
  }

  // ============================================================
  // LOCATION & CONTINUOUS TRACKING
  // ============================================================

  Future<void> _initLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled on this device.';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission was denied.';
            _locationPermissionGranted = false;
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permissions are permanently denied. Please enable them in system settings.';
          _locationPermissionGranted = false;
          _isLoadingLocation = false;
        });
        return;
      }

      _locationPermissionGranted = true;

      // Initial fast location fetch
      try {
        final initialPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );

        if (mounted) {
          final pos =
              LatLng(initialPosition.latitude, initialPosition.longitude);
          setState(() {
            _currentRiderLocation = pos;
            _currentHeading =
                initialPosition.heading >= 0 ? initialPosition.heading : null;
            _isLoadingLocation = false;
          });
          _bloc.add(RiderLocationUpdated(initialPosition));
          _fitMapToPoints();
        }
      } catch (_) {
        // Location stream below will deliver position
      }

      // Continuous position stream
      await _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (position) {
          final pos = LatLng(position.latitude, position.longitude);
          if (mounted) {
            setState(() {
              _currentRiderLocation = pos;
              _currentHeading =
                  position.heading >= 0 ? position.heading : null;
              _isLoadingLocation = false;
            });
          }
          _bloc.add(RiderLocationUpdated(position));

          if (!_hasInitiallyFitMap) {
            _hasInitiallyFitMap = true;
            _fitMapToPoints();
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _locationError = 'GPS stream error: $e';
              _isLoadingLocation = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Could not acquire current location: $e';
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _recenterOnRider() async {
    if (_currentRiderLocation != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentRiderLocation!,
            zoom: 16.5,
            bearing: _currentHeading ?? 0.0,
            tilt: 30.0,
          ),
        ),
      );
      if (mounted) {
        _showMessage(context, 'Centered on your current location',
            isError: false);
      }
    } else {
      await _initLocation();
      if (_currentRiderLocation != null && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentRiderLocation!, zoom: 16.5),
          ),
        );
      } else if (mounted && _locationError != null) {
        _showMessage(context, _locationError!, isError: true);
      }
    }
  }

  void _fitMapToPoints() {
    if (_mapController == null) return;
    final session = _sessionOf(_bloc.state);
    final loadedState = _bloc.state is RiderMapLoaded
        ? (_bloc.state as RiderMapLoaded)
        : null;

    final points = <LatLng>[];

    // Include route points if available for tight bounds
    if (loadedState != null && loadedState.selectedRoute != null) {
      final routePts = loadedState.selectedRoute!.points;
      if (routePts.isNotEmpty) {
        points.add(routePts.first);
        points.add(routePts.last);
      }
    }

    if (points.isEmpty) {
      if (_currentRiderLocation != null) {
        points.add(_currentRiderLocation!);
      } else if (session?.riderLat != null && session?.riderLng != null) {
        points.add(LatLng(session!.riderLat!, session.riderLng!));
      }

      if (session?.pickupLat != null && session?.pickupLng != null) {
        points.add(LatLng(session!.pickupLat!, session.pickupLng!));
      }

      if (session?.dropoffLat != null && session?.dropoffLng != null) {
        points.add(LatLng(session!.dropoffLat!, session.dropoffLng!));
      }
    }

    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 15.5),
        ),
      );
      return;
    }

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

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 75),
    );
  }

  // 0 = navigating to pickup, 1 = navigating to customer, 2 = arrived, 3 = completed
  int _stepFor(RiderMapSession session) {
    if (session.order.isCompleted) return 3;
    if (session.isArrived) return 2;
    if (session.isPickedUp) return 1;
    return 0;
  }

  bool _isNavigating() {
    final session = _sessionOf(_bloc.state);
    if (session == null) return false;
    return !session.isArrived && !session.order.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider<RiderMapBloc>.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: BlocListener<RiderMapBloc, RiderMapState>(
          bloc: _bloc,
          listener: (context, state) {
            if (state is RiderMapOperationSuccess) {
              _showMessage(context, state.message, isError: false);
            } else if (state is RiderMapError && state.message.isNotEmpty) {
              _showMessage(context, state.message, isError: true);
            } else if (state is RiderMapLoaded && state.routeError != null) {
              _showMessage(context, state.routeError!, isError: true);
            }
          },
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: _buildMapArea(context, isDark)),

                // Top Navigation & Stage Header
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _buildMapButton(
                            context,
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: BlocBuilder<RiderMapBloc, RiderMapState>(
                              bloc: _bloc,
                              buildWhen: (p, c) =>
                                  c is RiderMapLoaded ||
                                  c is RiderMapUpdating ||
                                  c is RiderMapOperationSuccess,
                              builder: (context, state) {
                                final step = _stepFor(
                                    _sessionOf(state) ?? _emptySession());
                                return _buildTopBar(
                                    context, isDark, step, state);
                              },
                            ),
                          ),
                        ],
                      ),

                      // Turn-by-Turn Maneuver Banner & Route Refresh status
                      BlocBuilder<RiderMapBloc, RiderMapState>(
                        bloc: _bloc,
                        builder: (context, state) {
                          if (state is RiderMapLoaded &&
                              _isNavigating() &&
                              state.session.hasOrder) {
                            return _buildTurnByTurnBanner(
                                context, isDark, state);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),

                // Re-center button
                if (_isNavigating()) _buildLocateButton(context),

                // Alternate routes selector chips
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 300,
                  child: BlocBuilder<RiderMapBloc, RiderMapState>(
                    bloc: _bloc,
                    builder: (context, state) {
                      if (state is RiderMapLoaded &&
                          state.routes.length > 1 &&
                          _isNavigating()) {
                        return _buildRouteSelectionChips(
                            context, isDark, state);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                // Bottom card (Delivery stages / Arrived / Signature / Completed)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 18,
                  child: BlocBuilder<RiderMapBloc, RiderMapState>(
                    bloc: _bloc,
                    builder: (context, state) {
                      return _buildBottom(state, isDark, context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  RiderMapSession? _sessionOf(RiderMapState state) {
    if (state is RiderMapLoaded) return state.session;
    if (state is RiderMapUpdating) return state.session;
    if (state is RiderMapOperationSuccess) return state.session;
    if (state is RiderMapError) return state.session;
    return null;
  }

  RiderMapSession _emptySession() => RiderMapSession(order: OrderModel.noOp());

  // ============================================================
  // GOOGLE MAP AREA & POLYLINES
  // ============================================================

  Widget _buildMapArea(BuildContext context, bool isDark) {
    return BlocBuilder<RiderMapBloc, RiderMapState>(
      buildWhen: (p, c) =>
          c is RiderMapLoaded ||
          c is RiderMapUpdating ||
          c is RiderMapOperationSuccess ||
          c is RiderMapLoading,
      builder: (context, state) {
        final session = _sessionOf(state);
        final loadedState = state is RiderMapLoaded ? state : null;

        final markers = _buildMarkers(session, loadedState);
        final polylines = _buildPolylines(session, loadedState);

        final initialTarget = _currentRiderLocation ??
            (session?.pickupLat != null && session?.pickupLng != null
                ? LatLng(session!.pickupLat!, session.pickupLng!)
                : (session?.riderLat != null && session?.riderLng != null
                    ? LatLng(session!.riderLat!, session.riderLng!)
                    : _defaultLocation));

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialTarget,
                zoom: 15.0,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _fitMapToPoints();
              },
              style: isDark ? _darkMapStyle : null,
              myLocationEnabled: _locationPermissionGranted,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              markers: markers,
              polylines: polylines,
              padding: const EdgeInsets.only(top: 140, bottom: 280),
            ),

            // Off-route / Recalculating Route Floating Badge
            if (loadedState != null &&
                (loadedState.isLoadingRoute || loadedState.isOffRoute))
              Positioned(
                top: 120,
                left: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark
                              ? const Color(0xFF32C787)
                              : const Color(0xFF0F7253),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loadedState.isOffRoute
                            ? 'Off route • Recalculating…'
                            : 'Optimizing road route…',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Destination Proximity Notice
            if (loadedState != null &&
                loadedState.isNearDestination &&
                _isNavigating())
              Positioned(
                top: 120,
                right: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F7253),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Near destination',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_isLoadingLocation && _currentRiderLocation == null)
              Positioned(
                top: 80,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark
                              ? const Color(0xFF32C787)
                              : const Color(0xFF0F7253),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('Locating…',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),

            if (_locationError != null && !_locationPermissionGranted)
              Positioned(
                top: 80,
                right: 16,
                child: GestureDetector(
                  onTap: _initLocation,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade800,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_disabled,
                            size: 13, color: Colors.white),
                        SizedBox(width: 5),
                        Text('Enable GPS',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Set<Marker> _buildMarkers(
      RiderMapSession? session, RiderMapLoaded? loadedState) {
    final markers = <Marker>{};

    // 1. Current Rider Position Marker with live heading
    final riderPos = _currentRiderLocation ??
        (session?.riderLat != null && session?.riderLng != null
            ? LatLng(session!.riderLat!, session.riderLng!)
            : null);

    if (riderPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('rider_position'),
          position: riderPos,
          rotation: _currentHeading ?? 0.0,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: InfoWindow(
            title: session?.riderName != null && session!.riderName!.isNotEmpty
                ? session.riderName
                : 'Your Location',
            snippet: 'Rider Live Position',
          ),
        ),
      );
    }

    // 2. Pharmacy Pickup Marker (Highlighted before pickup)
    if (session?.pickupLat != null && session?.pickupLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup_location'),
          position: LatLng(session!.pickupLat!, session.pickupLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            session.isPickedUp
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: 'Pickup: ${session.pharmacy}',
            snippet: session.pharmacyAddressText,
          ),
        ),
      );
    }

    // 3. Customer Dropoff Marker
    if (session?.dropoffLat != null && session?.dropoffLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff_location'),
          position: LatLng(session!.dropoffLat!, session.dropoffLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: 'Drop-off: ${session.customer}',
            snippet: session.customerAddressText,
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(
      RiderMapSession? session, RiderMapLoaded? loadedState) {
    final polylines = <Polyline>{};

    if (loadedState != null && loadedState.routes.isNotEmpty) {
      // Draw Alternative Routes first (underneath primary)
      for (int i = 0; i < loadedState.routes.length; i++) {
        if (i == loadedState.selectedRouteIndex) continue;
        final route = loadedState.routes[i];

        polylines.add(
          Polyline(
            polylineId: PolylineId('alt_route_$i'),
            points: route.points,
            color: const Color(0xFF9E9E9E).withValues(alpha: 0.8),
            width: 4,
            consumeTapEvents: true,
            onTap: () {
              _bloc.add(SelectRoute(i));
            },
            patterns: [PatternItem.dash(18), PatternItem.gap(8)],
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }

      // Draw Selected Primary Route on top
      final selected = loadedState.selectedRoute;
      if (selected != null) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('primary_road_route'),
            points: selected.points,
            color: session?.isPickedUp == true
                ? const Color(0xFF7C4DFF)
                : const Color(0xFF0F7253),
            width: 6,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }
      return polylines;
    }

    // Fallback straight-line polyline if routes not yet loaded
    final points = <LatLng>[];
    final riderPos = _currentRiderLocation ??
        (session?.riderLat != null && session?.riderLng != null
            ? LatLng(session!.riderLat!, session.riderLng!)
            : null);

    if (riderPos != null) points.add(riderPos);

    if (session != null && !session.isPickedUp) {
      if (session.pickupLat != null && session.pickupLng != null) {
        points.add(LatLng(session.pickupLat!, session.pickupLng!));
      }
    } else if (session != null) {
      if (session.dropoffLat != null && session.dropoffLng != null) {
        points.add(LatLng(session.dropoffLat!, session.dropoffLng!));
      }
    }

    if (points.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('delivery_path_fallback'),
          points: points,
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.7),
          width: 4,
          jointType: JointType.round,
        ),
      );
    }

    return polylines;
  }

  // ============================================================
  // TURN-BY-TURN INSTRUCTION BANNER
  // ============================================================

  Widget _buildTurnByTurnBanner(
      BuildContext context, bool isDark, RiderMapLoaded state) {
    final theme = Theme.of(context);
    final maneuver = state.currentManeuver;
    final maneuverIcon = RouteUtils.getManeuverIcon(maneuver?.maneuver);

    final isPickupStage = !state.session.isPickedUp;
    final stageColor =
        isPickupStage ? const Color(0xFF0F7253) : const Color(0xFF7C4DFF);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: stageColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(maneuverIcon, color: stageColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  maneuver?.instruction ??
                      (isPickupStage
                          ? 'Head towards ${state.session.pharmacy}'
                          : 'Head towards ${state.session.customer}'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  maneuver != null
                      ? 'In ${maneuver.distanceText} • Route: ${state.selectedRoute?.summary ?? "Fastest"}'
                      : (isPickupStage
                          ? 'Pickup: ${state.session.pharmacyAddressText}'
                          : 'Drop-off: ${state.session.customerAddressText}'),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.activeEta,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: stageColor,
                ),
              ),
              Text(
                state.activeDistance,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ALTERNATE ROUTE SELECTOR CHIPS
  // ============================================================

  Widget _buildRouteSelectionChips(
      BuildContext context, bool isDark, RiderMapLoaded state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(state.routes.length, (index) {
          final route = state.routes[index];
          final isSelected = index == state.selectedRouteIndex;

          return GestureDetector(
            onTap: () => _bloc.add(SelectRoute(index)),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF1D322A) : const Color(0xFF0F7253))
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF32C787)
                      : (isDark ? Colors.white12 : Colors.black12),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.alt_route_rounded,
                    size: 15,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey : Colors.grey.shade700),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${route.summary} • ${route.durationText}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMapButton(BuildContext context,
      {required IconData icon, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 21),
        ),
      ),
    );
  }

  Widget _buildLocateButton(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 350,
      child: _buildMapButton(
        context,
        icon: Icons.my_location_rounded,
        onTap: _recenterOnRider,
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(
      BuildContext context, bool isDark, int step, RiderMapState state) {
    final theme = Theme.of(context);

    final statusColor = step == 3
        ? const Color(0xFF32C787)
        : (step == 2
            ? const Color(0xFFE8A920)
            : (step == 1 ? const Color(0xFF7C4DFF) : const Color(0xFF0F7253)));

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.map_outlined,
            size: 19,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _topBarTitle(step, state),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _topBarBadge(step),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  String _topBarTitle(int step, RiderMapState state) {
    if (state is RiderMapLoading) return 'Loading delivery…';
    if (_sessionOf(state)?.order.id.isEmpty == true) return 'No active delivery';
    switch (step) {
      case 0:
        return 'Pickup from Pharmacy';
      case 1:
        return 'Navigating to Customer';
      case 2:
        return 'Arrived at Customer';
      case 3:
        return 'Delivery Completed';
      default:
        return 'Active Route';
    }
  }

  String _topBarBadge(int step) {
    switch (step) {
      case 0:
        return 'To Pickup';
      case 1:
        return 'On the way';
      case 2:
        return 'Arrived';
      case 3:
        return 'Done';
      default:
        return 'Active';
    }
  }

  // ============================================================
  // BOTTOM CARD (STAGE AWARE)
  // ============================================================

  Widget _buildBottom(RiderMapState state, bool isDark, BuildContext context) {
    if (state is RiderMapLoading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Text('Loading delivery…',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
    }

    final session = _sessionOf(state);
    if (session == null || session.order.id.isEmpty) {
      return _buildEmptyCard(context, isDark);
    }

    final step = _stepFor(session);
    if (step == 3) return _buildCompletedCard(context, isDark, session);
    if (step == 2) return _buildArrivedCard(context, isDark, session);
    return _buildDeliveryBottomCard(context, isDark, session, state);
  }

  Widget _buildEmptyCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF32C787).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delivery_dining_outlined,
                size: 32, color: Color(0xFF0F7253)),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Active Delivery',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            "You don't have an assigned delivery right now. New orders assigned to you will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 1 & 2: ACTIVE DELIVERY BOTTOM CARD
  // ============================================================

  Widget _buildDeliveryBottomCard(BuildContext context, bool isDark,
      RiderMapSession session, RiderMapState state) {
    final theme = Theme.of(context);
    final isPickupStage = !session.isPickedUp;

    final distanceDisplay =
        state is RiderMapLoaded ? state.activeDistance : session.distance;
    final etaDisplay =
        state is RiderMapLoaded ? state.activeEta : session.eta;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_orderLabel(session.order.id),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isPickupStage
                      ? const Color(0xFF0F7253).withValues(alpha: 0.10)
                      : const Color(0xFF7C4DFF).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle,
                        size: 7,
                        color: isPickupStage
                            ? const Color(0xFF0F7253)
                            : const Color(0xFF7C4DFF)),
                    const SizedBox(width: 5),
                    Text(
                      _statusLabel(session.order.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isPickupStage
                            ? const Color(0xFF0F7253)
                            : const Color(0xFF7C4DFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildLocationRow(
            icon: Icons.storefront,
            iconColor: isPickupStage
                ? const Color(0xFF0F7253)
                : Colors.grey.shade500,
            title: 'PICKUP ${isPickupStage ? "(CURRENT STAGE)" : ""}',
            name: session.pharmacy,
            address: session.pharmacyAddressText,
          ),

          Padding(
            padding: const EdgeInsets.only(left: 16, top: 3, bottom: 3),
            child: Column(
              children: List.generate(
                3,
                (_) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  width: 2,
                  height: 4,
                  color: Colors.grey.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),

          _buildLocationRow(
            icon: Icons.location_on_outlined,
            iconColor: !isPickupStage
                ? const Color(0xFF7C4DFF)
                : Colors.grey.shade500,
            title: 'DROP-OFF ${!isPickupStage ? "(CURRENT STAGE)" : ""}',
            name: session.customer,
            address: session.customerAddressText,
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF0F1814) : const Color(0xFFF6F8F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(distanceDisplay,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      const Text('Road Distance',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                    width: 1,
                    height: 28,
                    color: Colors.grey.withValues(alpha: 0.20)),
                Expanded(
                  child: Column(
                    children: [
                      Text(etaDisplay,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      const Text('Traffic ETA',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<RiderMapBloc>().add(MarkArrived(session.order.id));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F7253),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.location_on_outlined, size: 19),
              label: Text(
                isPickupStage ? 'Arrived at Pharmacy' : 'Arrived at Customer',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: () => _showDeliveryInformation(context, session),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11)),
              ),
              child: Text(
                'View Delivery Details',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 3: ARRIVED – CUSTOMER NAME + SIGNATURE
  // ============================================================

  Widget _buildArrivedCard(
      BuildContext context, bool isDark, RiderMapSession session) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_orderLabel(session.order.id),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8A920).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: Color(0xFFE8A920)),
                    SizedBox(width: 5),
                    Text('Arrived',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE8A920))),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF15301D) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1D322A) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 22, color: Color(0xFF0F7253)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Customer',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(session.customer,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(session.customerAddressText,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF32C787).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Delivering',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF32C787))),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Text('Customer Signature',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
              const Spacer(),
              if (_signaturePoints.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _signaturePoints.clear()),
                  child: Text('Clear',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400)),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1814) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _signaturePoints.isNotEmpty
                    ? cs.primary.withValues(alpha: 0.4)
                    : isDark
                        ? const Color(0xFF2A3A33)
                        : Colors.grey.shade300,
                width: _signaturePoints.isNotEmpty ? 1.5 : 1,
              ),
            ),
            child: _signaturePoints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.draw_outlined,
                            size: 28,
                            color:
                                cs.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 4),
                        Text('Tap and draw to sign',
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.5))),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _signaturePoints.add(details.localPosition);
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _signaturePoints.add(details.localPosition);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _signaturePoints.add(null);
                        });
                      },
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _SignaturePainter(points: _signaturePoints),
                      ),
                    ),
                  ),
          ),

          if (_signaturePoints.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Customer must sign before completing delivery',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500),
              ),
            ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _signaturePoints.isEmpty
                  ? null
                  : () {
                      _completeDelivery(context, session);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F7253),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                disabledForegroundColor: Colors.grey,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 19),
              label: const Text('Complete Delivery',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  void _completeDelivery(BuildContext context, RiderMapSession session) {
    final points = _signaturePoints
        .whereType<Offset>()
        .map((p) => <String, double>{'x': p.dx, 'y': p.dy})
        .toList();
    context.read<RiderMapBloc>().add(CompleteDelivery(
          orderId: session.order.id,
          recipientName: session.customer,
          signaturePoints: points,
          medicineHandoverConfirmed: true,
        ));
  }

  void _showMessage(BuildContext context, String message,
      {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : const Color(0xFF0F7253),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // STEP 4: DELIVERY COMPLETED
  // ============================================================

  Widget _buildCompletedCard(
      BuildContext context, bool isDark, RiderMapSession session) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF32C787).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 40, color: Color(0xFF32C787)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Delivery Completed!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Order ${_orderLabel(session.order.id)} has been delivered to ${session.customer}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF0F1814) : const Color(0xFFF6F8F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _completedDetailRow(Icons.receipt_long_outlined, 'Order',
                    _orderLabel(session.order.id)),
                const SizedBox(height: 10),
                _completedDetailRow(
                    Icons.person_outline, 'Customer', session.customer),
                const SizedBox(height: 10),
                _completedDetailRow(Icons.location_on_outlined, 'Address',
                    session.customerAddressText),
                const SizedBox(height: 10),
                _completedDetailRow(Icons.timer_outlined, 'Delivery Time',
                    _deliveryTime(session)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F7253),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.home_outlined, size: 19),
              label: const Text('Back to Home',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  String _deliveryTime(RiderMapSession session) {
    final t = session.order.deliveredAt;
    if (t == null) return session.eta == '—' ? '—' : session.eta;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _orderLabel(String id) => id.isEmpty ? '—' : '#${id.toUpperCase()}';

  String _statusLabel(String status) {
    if (status == 'Ready') return 'Assigned';
    if (status == 'Delivered' || status == 'Completed') return 'Completed';
    return status.isEmpty ? 'Assigned' : status;
  }

  Widget _completedDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const Spacer(),
        Flexible(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _buildLocationRow(
      {required IconData icon,
      required Color iconColor,
      required String title,
      required String name,
      required String address}) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey)),
              const SizedBox(height: 2),
              Text(name,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 1),
              Text(address,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeliveryInformation(
      BuildContext context, RiderMapSession session) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Delivery Details',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                _buildBottomDetailRow(Icons.receipt_long_outlined, 'Order',
                    _orderLabel(session.order.id)),
                _buildBottomDetailRow(
                    Icons.storefront, 'Pharmacy', session.pharmacy),
                _buildBottomDetailRow(
                    Icons.person_outline, 'Customer', session.customer),
                _buildBottomDetailRow(Icons.location_on_outlined, 'Drop-off',
                    session.customerAddressText),
                _buildBottomDetailRow(
                    Icons.route_outlined, 'Distance', session.distance),
                _buildBottomDetailRow(
                    Icons.access_time_outlined, 'ETA', session.eta),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7253),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 17, color: const Color(0xFF0F7253)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SIGNATURE PAINTER
// ============================================================

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F7253)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) =>
      oldDelegate.points != points;
}

// ============================================================
// DARK MAP STYLE JSON FOR GOOGLE MAPS
// ============================================================

const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#1d2c25"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8ec3b9"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#1a362a"}]
  },
  {
    "featureType": "administrative.country",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#4b6858"}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#18241e"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#283d34"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6f9ba5"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#304339"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#212a24"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9ca5b3"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#3c574a"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#2f3948"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#17263c"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#515c6d"}]
  }
]
''';
