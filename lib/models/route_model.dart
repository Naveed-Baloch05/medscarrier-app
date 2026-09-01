import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteStepModel {
  const RouteStepModel({
    required this.instruction,
    required this.distanceMeters,
    required this.distanceText,
    required this.durationText,
    this.maneuver,
    this.startLocation,
    this.endLocation,
  });

  final String instruction;
  final int distanceMeters;
  final String distanceText;
  final String durationText;
  final String? maneuver;
  final LatLng? startLocation;
  final LatLng? endLocation;

  factory RouteStepModel.fromJson(Map<String, dynamic> json) {
    final navInstruction =
        json['navigationInstruction'] as Map<String, dynamic>?;
    final instruction = navInstruction?['instructions'] as String? ??
        json['description'] as String? ??
        'Continue on current road';
    final maneuver = navInstruction?['maneuver'] as String?;

    final distanceMeters = json['distanceMeters'] as int? ?? 0;
    final staticDurationStr = json['staticDuration'] as String? ?? '0s';
    final durationSeconds = parseDurationSeconds(staticDurationStr);

    final startCoord = json['startLocation']?['latLng'];
    final endCoord = json['endLocation']?['latLng'];

    return RouteStepModel(
      instruction: instruction,
      distanceMeters: distanceMeters,
      distanceText: formatDistance(distanceMeters),
      durationText: formatDuration(durationSeconds),
      maneuver: maneuver,
      startLocation: startCoord != null
          ? LatLng(
              (startCoord['latitude'] as num).toDouble(),
              (startCoord['longitude'] as num).toDouble(),
            )
          : null,
      endLocation: endCoord != null
          ? LatLng(
              (endCoord['latitude'] as num).toDouble(),
              (endCoord['longitude'] as num).toDouble(),
            )
          : null,
    );
  }

  static int parseDurationSeconds(String str) {
    final clean = str.replaceAll('s', '').trim();
    return int.tryParse(clean) ?? 0;
  }

  static String formatDistance(int meters) {
    if (meters < 1000) {
      return '$meters m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String formatDuration(int seconds) {
    if (seconds < 60) {
      return '< 1 min';
    }
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remMinutes = minutes % 60;
    if (remMinutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $remMinutes min';
  }
}

class RouteModel {
  const RouteModel({
    required this.id,
    required this.points,
    required this.distanceMeters,
    required this.distanceText,
    required this.durationSeconds,
    required this.durationText,
    required this.summary,
    required this.steps,
    this.isRecommended = false,
  });

  final String id;
  final List<LatLng> points;
  final int distanceMeters;
  final String distanceText;
  final int durationSeconds;
  final String durationText;
  final String summary;
  final List<RouteStepModel> steps;
  final bool isRecommended;

  RouteStepModel? get firstStep => steps.isNotEmpty ? steps.first : null;
}
