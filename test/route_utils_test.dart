import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:medscarrier/core/utils/route_utils.dart';
import 'package:medscarrier/models/route_model.dart';

void main() {
  group('RouteUtils Tests', () {
    test('Polyline decoding works accurately', () {
      // Standard Google polyline string: points (38.5, -120.2), (40.7, -120.95), (43.252, -126.453)
      const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
      final points = RouteUtils.decodePolyline(encoded);

      expect(points.length, 3);
      expect((points[0].latitude - 38.5).abs() < 0.001, true);
      expect((points[0].longitude - (-120.2)).abs() < 0.001, true);
      expect((points[1].latitude - 40.7).abs() < 0.001, true);
      expect((points[1].longitude - (-120.95)).abs() < 0.001, true);
    });

    test('Haversine distance calculation is accurate', () {
      const p1 = LatLng(33.6844, 73.0479);
      const p2 = LatLng(33.6944, 73.0479);
      final dist = RouteUtils.distanceMeters(p1, p2);

      // 0.01 deg latitude ~ 1111 meters
      expect((dist - 1111).abs() < 50, true);
    });

    test('Off-route detection flags points far from line', () {
      const p1 = LatLng(33.6844, 73.0479);
      const p2 = LatLng(33.6944, 73.0479);
      final path = [p1, p2];

      // Point right on the line
      const onPoint = LatLng(33.6894, 73.0479);
      expect(RouteUtils.isOffRoute(onPoint, path, thresholdMeters: 50.0), false);

      // Point 500m away to the east
      const offPoint = LatLng(33.6894, 73.0550);
      expect(RouteUtils.isOffRoute(offPoint, path, thresholdMeters: 50.0), true);
    });

    test('Maneuver icons return correct icon symbols', () {
      expect(RouteUtils.getManeuverIcon('TURN_LEFT'), Icons.turn_left_rounded);
      expect(RouteUtils.getManeuverIcon('TURN_RIGHT'), Icons.turn_right_rounded);
      expect(RouteUtils.getManeuverIcon('ROUNDABOUT_ENTER'), Icons.roundabout_right_rounded);
      expect(RouteUtils.getManeuverIcon('STRAIGHT'), Icons.straight_rounded);
    });

    test('Distance and duration formatters', () {
      expect(RouteStepModel.formatDistance(450), '450 m');
      expect(RouteStepModel.formatDistance(3200), '3.2 km');
      expect(RouteStepModel.formatDuration(45), '< 1 min');
      expect(RouteStepModel.formatDuration(480), '8 min');
      expect(RouteStepModel.formatDuration(3900), '1 hr 5 min');
    });

    test('RouteStepModel parse duration and distance works', () {
      expect(RouteStepModel.parseDurationSeconds('120s'), 120);
      expect(RouteStepModel.parseDurationSeconds('3600s'), 3600);
      expect(RouteStepModel.parseDurationSeconds('0s'), 0);
    });

    test('RouteModel step properties and maneuvers', () {
      const step1 = RouteStepModel(
        instruction: 'Turn left onto Oxford Rd',
        distanceMeters: 300,
        distanceText: '300 m',
        durationText: '1 min',
        maneuver: 'TURN_LEFT',
        startLocation: LatLng(52.4862, -1.8904),
        endLocation: LatLng(52.4870, -1.8920),
      );
      const step2 = RouteStepModel(
        instruction: 'Turn right onto High St',
        distanceMeters: 500,
        distanceText: '500 m',
        durationText: '2 min',
        maneuver: 'TURN_RIGHT',
        startLocation: LatLng(52.4870, -1.8920),
        endLocation: LatLng(52.4900, -1.8920),
      );

      final route = RouteModel(
        id: 'test_route_1',
        points: const [
          LatLng(52.4862, -1.8904),
          LatLng(52.4870, -1.8920),
          LatLng(52.4900, -1.8920),
        ],
        distanceMeters: 800,
        distanceText: '800 m',
        durationSeconds: 180,
        durationText: '3 min',
        summary: 'Via Oxford Rd',
        steps: const [step1, step2],
      );

      expect(route.steps.length, 2);
      expect(route.firstStep?.maneuver, 'TURN_LEFT');
      expect(route.steps[1].maneuver, 'TURN_RIGHT');
    });
  });
}

