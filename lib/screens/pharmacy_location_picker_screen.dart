import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

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
  GoogleMapController? _mapController;

  late LatLng _center;

  bool _isResolving = false;
  bool _isGettingLocation = false;
  bool _hasPicked = false;
  bool _isSearching = false;

  String _resolvedAddress = '';

  Timer? _searchDebounce;

  final TextEditingController _searchController =
  TextEditingController();

  List<_SearchSuggestion> _searchSuggestions = [];

  // ============================================================
  // GOOGLE MAPS API KEY
  // ============================================================

  /*
   * Recommended:
   *
   * flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
   *
   * Do NOT paste the API key directly into this file.
   */
  static const String _definedApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /*
   * This channel is only for Android package/certificate information.
   *
   * IMPORTANT:
   * It is NOT related to Rider.
   *
   * It is used only because Google Places REST requests from an
   * Android application may require:
   *
   * X-Android-Package
   * X-Android-Cert
   */
  static const MethodChannel _platformChannel =
  MethodChannel(
    'com.medscarrier.medscarrier/maps',
  );

  String _apiKey = _definedApiKey;

  String _androidPackage = '';
  String _androidCertSha1 = '';

  String get _googleMapsApiKey => _apiKey.trim();

  // ============================================================
  // RESOLVE API KEY
  // ============================================================

  Future<void> _resolveApiKey() async {
    if (_apiKey.trim().isNotEmpty) {
      return;
    }

    try {
      final key =
      await _platformChannel.invokeMethod<String>(
        'getApiKey',
      );

      if (key != null && key.trim().isNotEmpty) {
        if (!mounted) return;

        setState(() {
          _apiKey = key.trim();
        });
      }
    } catch (e) {
      debugPrint(
        'Unable to resolve Google Maps API key: $e',
      );
    }
  }

  // ============================================================
  // ANDROID CLIENT INFORMATION
  // ============================================================

  Future<void> _resolveAndroidClientInfo() async {
    try {
      final info =
      await _platformChannel.invokeMethod<
          Map<Object?, Object?>>(
        'getAndroidClientInfo',
      );

      if (info == null || !mounted) {
        return;
      }

      setState(() {
        _androidPackage =
            info['packageName']?.toString() ?? '';

        _androidCertSha1 =
            info['sha1']?.toString() ?? '';
      });

      debugPrint(
        'Android package: $_androidPackage',
      );

      debugPrint(
        'Android SHA-1: $_androidCertSha1',
      );
    } catch (e) {
      debugPrint(
        'Unable to resolve Android client info: $e',
      );
    }
  }

  // ============================================================
  // ANDROID HEADERS
  // ============================================================

  Map<String, String> get _androidClientHeaders {
    final headers = <String, String>{};

    if (_androidPackage.trim().isNotEmpty) {
      headers['X-Android-Package'] =
          _androidPackage.trim();
    }

    if (_androidCertSha1.trim().isNotEmpty) {
      headers['X-Android-Cert'] =
          _androidCertSha1
              .replaceAll(':', '')
              .trim()
              .toUpperCase();
    }

    return headers;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _resolveApiKey();
    _resolveAndroidClientInfo();

    final lat = widget.initialLatitude;
    final lng = widget.initialLongitude;

    if (lat != null && lng != null) {
      _center = LatLng(lat, lng);

      _resolvedAddress =
          widget.initialAddress.trim();

      _hasPicked = true;
    } else {
      /*
       * Default location.
       *
       * This is only the initial camera position.
       * User can press Current Location.
       */
      _center = const LatLng(
        24.8607,
        67.0011,
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();

    super.dispose();
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    try {
      // --------------------------------------------------------
      // LOCATION SERVICE
      // --------------------------------------------------------

      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _isGettingLocation = false;
        });

        await _showLocationServiceDialog();

        return;
      }

      // --------------------------------------------------------
      // PERMISSION
      // --------------------------------------------------------

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        setState(() {
          _isGettingLocation = false;
        });

        _showMessage(
          'Location permission was denied.',
          isError: true,
        );

        return;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _isGettingLocation = false;
        });

        await _showPermissionSettingsDialog();

        return;
      }

      // --------------------------------------------------------
      // GET LOCATION
      // --------------------------------------------------------

      final position =
      await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _center = currentLocation;
        _hasPicked = true;
        _isGettingLocation = false;
      });

      // --------------------------------------------------------
      // MOVE MAP
      // --------------------------------------------------------

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation,
            zoom: 17,
          ),
        ),
      );

      // --------------------------------------------------------
      // REVERSE GEOCODE
      // --------------------------------------------------------

      await _reverseGeocode(
        currentLocation,
      );
    } catch (e) {
      debugPrint(
        'Current location error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isGettingLocation = false;
      });

      _showMessage(
        'Unable to get your current location.',
        isError: true,
      );
    }
  }

  // ============================================================
  // REVERSE GEOCODING
  // ============================================================

  Future<void> _reverseGeocode(
      LatLng point,
      ) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isResolving = true;
      _hasPicked = true;
    });

    try {
      /*
       * We intentionally use Flutter's native geocoding package
       * here instead of calling Google's Geocoding REST API.
       *
       * This avoids requiring the Places/Geocoding REST key for
       * reverse address lookup.
       */

      final placemarks =
      await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final parts = <String>[
          if ((place.name ?? '').trim().isNotEmpty)
            place.name!.trim(),

          if ((place.street ?? '').trim().isNotEmpty &&
              place.street != place.name)
            place.street!.trim(),

          if ((place.subLocality ?? '')
              .trim()
              .isNotEmpty)
            place.subLocality!.trim(),

          if ((place.locality ?? '').trim().isNotEmpty)
            place.locality!.trim(),

          if ((place.administrativeArea ?? '')
              .trim()
              .isNotEmpty)
            place.administrativeArea!.trim(),

          if ((place.country ?? '').trim().isNotEmpty)
            place.country!.trim(),
        ];

        final address = parts
            .where(
              (value) => value.isNotEmpty,
        )
            .toSet()
            .join(', ');

        if (!mounted) return;

        setState(() {
          _resolvedAddress =
          address.isNotEmpty
              ? address
              : _coordinateText(point);

          _isResolving = false;
        });

        return;
      }

      throw Exception(
        'No address found.',
      );
    } catch (e) {
      debugPrint(
        'Reverse geocoding error: $e',
      );

      if (!mounted) return;

      setState(() {
        _resolvedAddress =
            _coordinateText(point);

        _isResolving = false;
      });
    }
  }

  // ============================================================
  // COORDINATE TEXT
  // ============================================================

  String _coordinateText(
      LatLng point,
      ) {
    return '${point.latitude.toStringAsFixed(6)}, '
        '${point.longitude.toStringAsFixed(6)}';
  }

  // ============================================================
  // MAP MOVE
  // ============================================================

  Future<void> _moveTo(
      LatLng point,
      ) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _center = point;
      _hasPicked = true;
    });

    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: point,
          zoom: 17,
        ),
      ),
    );

    await _reverseGeocode(point);
  }

  // ============================================================
  // CAMERA IDLE
  // ============================================================

  Future<void> _onCameraIdle() async {
    await _reverseGeocode(_center);
  }

  // ============================================================
  // SEARCH TEXT CHANGED
  // ============================================================

  void _onSearchChanged(
      String value,
      ) {
    _searchDebounce?.cancel();

    final query = value.trim();

    if (query.isEmpty) {
      if (!mounted) return;

      setState(() {
        _searchSuggestions = [];
        _isSearching = false;
      });

      return;
    }

    _searchDebounce = Timer(
      const Duration(
        milliseconds: 600,
      ),
          () {
        _searchPlaces(query);
      },
    );
  }

  // ============================================================
  // GOOGLE PLACES SEARCH
  // ============================================================

  Future<void> _searchPlaces(
      String query,
      ) async {
    if (_googleMapsApiKey.isEmpty) {
      _showMessage(
        'Google Maps API key is not configured.',
        isError: true,
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final uri = Uri.parse(
        'https://places.googleapis.com/v1/places:searchText',
      );

      /*
       * Places API (New)
       *
       * Required:
       * X-Goog-Api-Key
       * X-Goog-FieldMask
       */
      final headers = <String, String>{
        'Content-Type':
        'application/json',
        'X-Goog-Api-Key':
        _googleMapsApiKey,
        'X-Goog-FieldMask':
        'places.id,'
            'places.displayName,'
            'places.formattedAddress,'
            'places.location',
      };

      /*
       * If the key is Android restricted, these headers
       * identify the Android application.
       */
      headers.addAll(
        _androidClientHeaders,
      );

      final body = <String, dynamic>{
        'textQuery': query,

        /*
         * Keep results close to the current map location.
         *
         * Radius is in meters.
         */
        'locationBias': {
          'circle': {
            'center': {
              'latitude':
              _center.latitude,
              'longitude':
              _center.longitude,
            },
            'radius': 50000.0,
          },
        },

        'pageSize': 5,
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint(
        'Places status: ${response.statusCode}',
      );

      debugPrint(
        'Places response: ${response.body}',
      );

      // --------------------------------------------------------
      // ERROR
      // --------------------------------------------------------

      if (response.statusCode != 200) {
        String errorMessage =
            'Places request failed '
            '(${response.statusCode})';

        try {
          final decoded =
          jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            final error =
            decoded['error'];

            if (error
            is Map<String, dynamic>) {
              final message =
              error['message']
                  ?.toString();

              if (message != null &&
                  message.trim().isNotEmpty) {
                errorMessage =
                    message.trim();
              }
            }
          }
        } catch (_) {
          // Keep default message.
        }

        if (!mounted) return;

        setState(() {
          _searchSuggestions = [];
          _isSearching = false;
        });

        _showMessage(
          'Location search failed: '
              '$errorMessage',
          isError: true,
        );

        return;
      }

      // --------------------------------------------------------
      // RESPONSE
      // --------------------------------------------------------

      final data =
      jsonDecode(response.body);

      if (data
      is! Map<String, dynamic>) {
        if (!mounted) return;

        setState(() {
          _searchSuggestions = [];
          _isSearching = false;
        });

        return;
      }

      final places = data['places'];

      if (places is! List) {
        if (!mounted) return;

        setState(() {
          _searchSuggestions = [];
          _isSearching = false;
        });

        return;
      }

      final suggestions =
      <_SearchSuggestion>[];

      // --------------------------------------------------------
      // PARSE RESULTS
      // --------------------------------------------------------

      for (final item in places) {
        if (item
        is! Map<String, dynamic>) {
          continue;
        }

        // ------------------------------------------------------
        // NAME
        // ------------------------------------------------------

        String name = '';

        final displayName =
        item['displayName'];

        if (displayName
        is Map<String, dynamic>) {
          name =
              displayName['text']
                  ?.toString()
                  .trim() ??
                  '';
        }

        // ------------------------------------------------------
        // ADDRESS
        // ------------------------------------------------------

        final address =
            item['formattedAddress']
                ?.toString()
                .trim() ??
                '';

        // ------------------------------------------------------
        // LOCATION
        // ------------------------------------------------------

        final location =
        item['location'];

        if (location
        is! Map<String, dynamic>) {
          continue;
        }

        final latitude =
        (location['latitude']
        as num?)
            ?.toDouble();

        final longitude =
        (location['longitude']
        as num?)
            ?.toDouble();

        if (latitude == null ||
            longitude == null) {
          continue;
        }

        suggestions.add(
          _SearchSuggestion(
            name: name.isNotEmpty
                ? name
                : address,
            address: address,
            location: LatLng(
              latitude,
              longitude,
            ),
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _searchSuggestions =
            suggestions;

        _isSearching = false;
      });
    } catch (e) {
      debugPrint(
        'Google Places search exception: $e',
      );

      if (!mounted) return;

      setState(() {
        _searchSuggestions = [];
        _isSearching = false;
      });

      _showMessage(
        'Unable to search this location.',
        isError: true,
      );
    }
  }

  // ============================================================
  // SELECT SEARCH RESULT
  // ============================================================

  Future<void> _selectSearchResult(
      _SearchSuggestion suggestion,
      ) async {
    FocusScope.of(context).unfocus();

    _searchController.text =
        suggestion.name;

    if (!mounted) return;

    setState(() {
      _searchSuggestions = [];
      _center = suggestion.location;
      _resolvedAddress =
          suggestion.address;
      _hasPicked = true;
    });

    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: suggestion.location,
          zoom: 17,
        ),
      ),
    );

    /*
     * Resolve the selected coordinates again
     * using native geocoding.
     */
    await _reverseGeocode(
      suggestion.location,
    );
  }

  // ============================================================
  // CONFIRM
  // ============================================================

  void _confirm() {
    if (!_hasPicked ||
        _isResolving) {
      return;
    }

    final address =
    _resolvedAddress.trim().isNotEmpty
        ? _resolvedAddress.trim()
        : _coordinateText(_center);

    Navigator.pop(
      context,
      PharmacyLocationResult(
        address: address,
        latitude: _center.latitude,
        longitude: _center.longitude,
      ),
    );
  }

  // ============================================================
  // LOCATION SERVICE DIALOG
  // ============================================================

  Future<void>
  _showLocationServiceDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Location is disabled',
          ),
          content: const Text(
            'Please enable location services '
                'on your device to use Current Location.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child:
              const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await Geolocator
                    .openLocationSettings();
              },
              child:
              const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PERMISSION DIALOG
  // ============================================================

  Future<void>
  _showPermissionSettingsDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Location permission required',
          ),
          content: const Text(
            'Location permission was permanently denied. '
                'Please enable it from the app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child:
              const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await Geolocator
                    .openAppSettings();
              },
              child:
              const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
          SnackBarBehavior.floating,
          backgroundColor: isError
              ? Colors.red.shade700
              : const Color(0xFF0F7253),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final isDark =
        theme.brightness ==
            Brightness.dark;

    final primaryColor = isDark
        ? const Color(0xFF32C787)
        : const Color(0xFF0F7253);

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ======================================================
          // GOOGLE MAP
          // ======================================================

          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition:
              CameraPosition(
                target: _center,
                zoom: 15,
              ),

              onMapCreated:
                  (controller) {
                _mapController =
                    controller;
              },

              myLocationEnabled: true,
              myLocationButtonEnabled:
              false,

              zoomControlsEnabled: true,
              compassEnabled: true,

              onTap: _moveTo,

              onCameraIdle:
              _onCameraIdle,
            ),
          ),

          // ======================================================
          // CENTER MARKER
          // ======================================================

          IgnorePointer(
            child: Center(
              child: Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 44,
                ),
                child: Icon(
                  Icons.location_on,
                  size: 48,
                  color: primaryColor,
                  shadows: [
                    Shadow(
                      color: Colors.black
                          .withValues(
                        alpha: 0.30,
                      ),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ======================================================
          // TOP SEARCH BAR
          // ======================================================

          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildRoundButton(
                        context,
                        icon: Icons
                            .arrow_back_rounded,
                        onTap: () =>
                            Navigator.pop(
                              context,
                            ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: Container(
                          height: 50,
                          decoration:
                          BoxDecoration(
                            color:
                            theme.cardColor,
                            borderRadius:
                            BorderRadius
                                .circular(
                              14,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors
                                    .black
                                    .withValues(
                                  alpha: 0.10,
                                ),
                                blurRadius: 12,
                                offset:
                                const Offset(
                                  0,
                                  4,
                                ),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller:
                            _searchController,
                            onChanged:
                            _onSearchChanged,
                            textInputAction:
                            TextInputAction
                                .search,
                            decoration:
                            InputDecoration(
                              border:
                              InputBorder
                                  .none,

                              hintText:
                              'Search location',

                              hintStyle:
                              TextStyle(
                                color: theme
                                    .colorScheme
                                    .onSurface
                                    .withValues(
                                  alpha: 0.55,
                                ),
                              ),

                              prefixIcon:
                              _isSearching
                                  ? Padding(
                                padding:
                                const EdgeInsets
                                    .all(
                                  14,
                                ),
                                child:
                                CircularProgressIndicator(
                                  strokeWidth:
                                  2.2,
                                  color:
                                  primaryColor,
                                ),
                              )
                                  : Icon(
                                Icons
                                    .search_rounded,
                                color:
                                primaryColor,
                              ),

                              suffixIcon:
                              _searchController
                                  .text
                                  .isNotEmpty
                                  ? IconButton(
                                icon:
                                const Icon(
                                  Icons
                                      .clear_rounded,
                                ),
                                onPressed:
                                    () {
                                  _searchController
                                      .clear();

                                  setState(
                                        () {
                                      _searchSuggestions =
                                      [];
                                      _isSearching =
                                      false;
                                    },
                                  );
                                },
                              )
                                  : null,

                              contentPadding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ==================================================
                  // SEARCH RESULTS
                  // ==================================================

                  if (_searchSuggestions
                      .isNotEmpty)
                    Container(
                      margin:
                      const EdgeInsets.only(
                        left: 56,
                        top: 8,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        theme.cardColor,
                        borderRadius:
                        BorderRadius
                            .circular(
                          14,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(
                              alpha: 0.12,
                            ),
                            blurRadius: 15,
                            offset:
                            const Offset(
                              0,
                              5,
                            ),
                          ),
                        ],
                      ),
                      child:
                      ListView.separated(
                        shrinkWrap: true,
                        padding:
                        EdgeInsets.zero,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        itemCount:
                        _searchSuggestions
                            .length,
                        separatorBuilder:
                            (_, __) =>
                            Divider(
                              height: 1,
                              color: theme
                                  .dividerColor,
                            ),
                        itemBuilder:
                            (context, index) {
                          final suggestion =
                          _searchSuggestions[
                          index];

                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons
                                  .location_on_outlined,
                              color:
                              primaryColor,
                            ),
                            title: Text(
                              suggestion.name,
                              maxLines: 1,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                            subtitle: Text(
                              suggestion.address,
                              maxLines: 2,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                            ),
                            onTap: () {
                              _selectSearchResult(
                                suggestion,
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ======================================================
          // CURRENT LOCATION
          // ======================================================

          Positioned(
            right: 16,
            bottom: 250,
            child: SafeArea(
              child: Material(
                color:
                Colors.transparent,
                child: InkWell(
                  onTap:
                  _isGettingLocation
                      ? null
                      : _getCurrentLocation,
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration:
                    BoxDecoration(
                      color:
                      theme.cardColor,
                      borderRadius:
                      BorderRadius
                          .circular(
                        15,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 12,
                          offset:
                          const Offset(
                            0,
                            4,
                          ),
                        ),
                      ],
                    ),
                    child:
                    _isGettingLocation
                        ? Padding(
                      padding:
                      const EdgeInsets
                          .all(
                        15,
                      ),
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2.5,
                        color:
                        primaryColor,
                      ),
                    )
                        : Icon(
                      Icons
                          .my_location_rounded,
                      color:
                      primaryColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ======================================================
          // BOTTOM PANEL
          // ======================================================

          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: SafeArea(
              top: false,
              child: Container(
                padding:
                const EdgeInsets.all(
                  16,
                ),
                decoration:
                BoxDecoration(
                  color:
                  theme.cardColor,
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 20,
                      offset:
                      const Offset(
                        0,
                        6,
                      ),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons
                              .storefront_outlined,
                          color:
                          primaryColor,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            'Set pharmacy location',
                            style:
                            TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight
                                  .w800,
                              color: theme
                                  .colorScheme
                                  .onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ------------------------------------------------
                    // ADDRESS
                    // ------------------------------------------------

                    Container(
                      width:
                      double.infinity,
                      padding:
                      const EdgeInsets
                          .all(
                        12,
                      ),
                      decoration:
                      BoxDecoration(
                        color: isDark
                            ? const Color(
                          0xFF151E1A,
                        )
                            : Colors.grey
                            .shade50,
                        borderRadius:
                        BorderRadius
                            .circular(
                          12,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Icon(
                            _isResolving
                                ? Icons
                                .hourglass_top_rounded
                                : Icons
                                .location_on_outlined,
                            size: 18,
                            color: isDark
                                ? const Color(
                              0xFF6E9585,
                            )
                                : const Color(
                              0xFF6E7A75,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              _isResolving
                                  ? 'Finding address...'
                                  : (_resolvedAddress
                                  .isEmpty
                                  ? 'Tap the map, search for a location, or use Current Location.'
                                  : _resolvedAddress),
                              style:
                              TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark
                                    ? const Color(
                                  0xFFD1DDD7,
                                )
                                    : const Color(
                                  0xFF191C1B,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ------------------------------------------------
                    // COORDINATES
                    // ------------------------------------------------

                    if (_hasPicked)
                      Row(
                        children: [
                          Icon(
                            Icons
                                .my_location_outlined,
                            size: 16,
                            color:
                            primaryColor,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Expanded(
                            child: Text(
                              'Lat: ${_center.latitude.toStringAsFixed(6)}   '
                                  'Lng: ${_center.longitude.toStringAsFixed(6)}',
                              style:
                              TextStyle(
                                fontSize: 11,
                                fontWeight:
                                FontWeight
                                    .w600,
                                color: theme
                                    .colorScheme
                                    .onSurface
                                    .withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ------------------------------------------------
                    // CONFIRM
                    // ------------------------------------------------

                    SizedBox(
                      width:
                      double.infinity,
                      height: 50,
                      child:
                      ElevatedButton.icon(
                        onPressed:
                        (_hasPicked &&
                            !_isResolving)
                            ? _confirm
                            : null,
                        style: ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          const Color(
                            0xFF0F7253,
                          ),
                          foregroundColor:
                          Colors.white,
                          disabledBackgroundColor:
                          Colors.grey
                              .withValues(
                            alpha: 0.30,
                          ),
                          disabledForegroundColor:
                          Colors.grey,
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              12,
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons
                              .check_circle_outline,
                          size: 20,
                        ),
                        label: const Text(
                          'Confirm Location',
                          style:
                          TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight
                                .w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROUND BUTTON
  // ============================================================

  Widget _buildRoundButton(
      BuildContext context, {
        required IconData icon,
        required VoidCallback onTap,
      }) {
    final theme =
    Theme.of(context);

    return Material(
      color:
      Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        child: Container(
          width: 46,
          height: 46,
          decoration:
          BoxDecoration(
            color:
            theme.cardColor,
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha: 0.10,
                ),
                blurRadius: 12,
                offset:
                const Offset(
                  0,
                  4,
                ),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 21,
            color: theme
                .colorScheme
                .onSurface,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SEARCH RESULT MODEL
// ============================================================

class _SearchSuggestion {
  const _SearchSuggestion({
    required this.name,
    required this.address,
    required this.location,
  });

  final String name;
  final String address;
  final LatLng location;
}