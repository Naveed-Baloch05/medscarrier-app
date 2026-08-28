import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PharmacyLocationResult {
  const PharmacyLocationResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;
}

class PharmacyLocationPickerScreen extends StatefulWidget {
  const PharmacyLocationPickerScreen({
    super.key,
    this.initialAddress = '',
    this.initialLatitude,
    this.initialLongitude,
  });

  final String initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<PharmacyLocationPickerScreen> createState() =>
      _PharmacyLocationPickerScreenState();
}

class _PharmacyLocationPickerScreenState
    extends State<PharmacyLocationPickerScreen> {
  final MapController _mapController = MapController();

  late LatLng _center;
  bool _isResolving = false;
  bool _hasPicked = false;
  String _resolvedAddress = '';

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLatitude;
    final lng = widget.initialLongitude;
    if (lat != null && lng != null) {
      _center = LatLng(lat, lng);
      _resolvedAddress = widget.initialAddress;
      _hasPicked = true;
    } else {
      // Default to central London (UK-focused app).
      _center = const LatLng(51.5074, -0.1278);
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() {
      _isResolving = true;
      _hasPicked = true;
    });

    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1');
      final res = await http.get(
        uri,
        headers: {
          'User-Agent': 'MedsCarrier/1.0 (contact: pharmacy@medscarrier.app)',
          'Accept': 'application/json',
        },
      );

      String address;
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        address = _formatAddress(json);
      } else {
        address =
            '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
      }

      if (!mounted) return;
      setState(() {
        _resolvedAddress = address;
        _isResolving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resolvedAddress =
            '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
        _isResolving = false;
      });
    }
  }

  String _formatAddress(Map<String, dynamic> json) {
    final addr = json['address'];
    final display = json['display_name']?.toString() ?? '';

    if (addr is Map<String, dynamic>) {
      final parts = <String>[
        addr['road'],
        addr['suburb'],
        addr['quarter'],
        addr['city_district'],
        addr['city'],
        addr['town'],
        addr['village'],
        addr['county'],
        addr['state'],
        addr['postcode'],
        addr['country'],
      ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();

      if (parts.isNotEmpty) return parts.join(', ');
    }

    return display.isNotEmpty ? display : 'Selected location';
  }

  void _moveTo(LatLng point) {
    _mapController.move(point, _mapController.camera.zoom);
    _reverseGeocode(point);
  }

  void _confirm() {
    Navigator.pop(
      context,
      PharmacyLocationResult(
        address: _resolvedAddress,
        latitude: _center.latitude,
        longitude: _center.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onTap: (_, point) => _moveTo(point),
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) _reverseGeocode(event.camera.center);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.medscarrier.app',
                maxZoom: 19,
              ),
            ],
          ),

          // Center pin
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 22),
                  Icon(
                    Icons.location_on,
                    size: 44,
                    color: isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _buildRoundButton(
                  context,
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
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
                          Icons.location_on_outlined,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF32C787)
                              : const Color(0xFF0F7253),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isResolving
                                ? 'Resolving address...'
                                : (_resolvedAddress.isEmpty
                                    ? 'Move the pin to set your location'
                                    : _resolvedAddress),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _hasPicked
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom panel
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        color: isDark
                            ? const Color(0xFF32C787)
                            : const Color(0xFF0F7253),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Set pharmacy location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF151E1A)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _isResolving
                              ? Icons.hourglass_top_rounded
                              : Icons.location_on_outlined,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF6E9585)
                              : const Color(0xFF6E7A75),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isResolving
                                ? 'Finding address...'
                                : (_resolvedAddress.isEmpty
                                    ? 'Tap anywhere on the map or drag to pick a location.'
                                    : _resolvedAddress),
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark
                                  ? const Color(0xFFD1DDD7)
                                  : const Color(0xFF191C1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed:
                          (_hasPicked && !_isResolving) ? _confirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F7253),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Colors.grey.withValues(alpha: 0.3),
                        disabledForegroundColor: Colors.grey,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text(
                        'Confirm Location',
                        style:
                            TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
          child: Icon(icon, size: 21, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}
