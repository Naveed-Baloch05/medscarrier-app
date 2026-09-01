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
  });
}
