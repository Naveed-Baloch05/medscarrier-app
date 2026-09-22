import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/order_model.dart';

class RouteUtils {
  RouteUtils._();

  /// Decodes an encoded polyline string into a list of [LatLng].
  static List<LatLng> decodePolyline(String encoded) {
    if (encoded.isEmpty) return const [];

    final List<LatLng> poly = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return poly;
  }

  /// Calculates Haversine distance in meters between two coordinates.
  static double distanceMeters(LatLng p1, LatLng p2) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(p2.latitude - p1.latitude);
    final dLng = _toRadians(p2.longitude - p1.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(p1.latitude)) *
            math.cos(_toRadians(p2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Computes the shortest distance in meters from [point] to the polyline [path].
  static double distanceToPolyline(LatLng point, List<LatLng> path) {
    if (path.isEmpty) return double.infinity;
    if (path.length == 1) return distanceMeters(point, path.first);

    double minDistance = double.infinity;

    for (int i = 0; i < path.length - 1; i++) {
      final p1 = path[i];
      final p2 = path[i + 1];

      final dist = _distanceToSegment(point, p1, p2);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    return minDistance;
  }

  /// Calculates the shortest distance from point P to line segment AB.
  static double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final x = p.longitude;
    final y = p.latitude;
    final x1 = a.longitude;
    final y1 = a.latitude;
    final x2 = b.longitude;
    final y2 = b.latitude;

    final dx = x2 - x1;
    final dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      return distanceMeters(p, a);
    }

    // Project point onto line segment
    final t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);

    if (t < 0) {
      return distanceMeters(p, a);
    } else if (t > 1) {
      return distanceMeters(p, b);
    }

    final proj = LatLng(y1 + t * dy, x1 + t * dx);
    return distanceMeters(p, proj);
  }

  /// Determines if [point] is off the polyline by more than [thresholdMeters].
  static bool isOffRoute(LatLng point, List<LatLng> path, {double thresholdMeters = 50.0}) {
    if (path.isEmpty) return false;
    final dist = distanceToPolyline(point, path);
    return dist > thresholdMeters;
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  /// Optimizes a list of delivery orders starting from [origin] using
  /// Nearest Neighbor + 2-Opt TSP heuristic.
  static List<OrderModel> optimizeOrderSequence({
    required LatLng origin,
    required List<OrderModel> orders,
  }) {
    if (orders.length <= 1) return List.from(orders);

    // Filter orders with valid dropoff coordinates
    final withCoords = <OrderModel>[];
    final withoutCoords = <OrderModel>[];

    for (final order in orders) {
      if (order.hasDropoffCoordinates) {
        withCoords.add(order);
      } else {
        withoutCoords.add(order);
      }
    }

    if (withCoords.isEmpty) {
      return List.from(orders);
    }

    // Step 1: Nearest Neighbor Heuristic
    final unvisited = List<OrderModel>.from(withCoords);
    final route = <OrderModel>[];
    LatLng current = origin;

    while (unvisited.isNotEmpty) {
      int nearestIndex = 0;
      double minDistance = double.infinity;

      for (int i = 0; i < unvisited.length; i++) {
        final dest = unvisited[i].dropoffLatLng!;
        final dist = distanceMeters(current, dest);
        if (dist < minDistance) {
          minDistance = dist;
          nearestIndex = i;
        }
      }

      final nearest = unvisited.removeAt(nearestIndex);
      route.add(nearest);
      current = nearest.dropoffLatLng!;
    }

    // Step 2: 2-Opt Optimization for further path reduction
    if (route.length >= 3) {
      bool improved = true;
      int iterations = 0;
      const maxIterations = 50;

      while (improved && iterations < maxIterations) {
        improved = false;
        iterations++;

        for (int i = 0; i < route.length - 1; i++) {
          for (int k = i + 1; k < route.length; k++) {
            final pPrev = i == 0 ? origin : route[i - 1].dropoffLatLng!;
            final pI = route[i].dropoffLatLng!;
            final pK = route[k].dropoffLatLng!;
            final pNext = (k + 1 < route.length) ? route[k + 1].dropoffLatLng : null;

            final currentDist = distanceMeters(pPrev, pI) +
                (pNext != null ? distanceMeters(pK, pNext) : 0);

            final newDist = distanceMeters(pPrev, pK) +
                (pNext != null ? distanceMeters(pI, pNext) : 0);

            if (newDist < currentDist - 1.0) {
              // Reverse sub-array between i and k
              final sub = route.sublist(i, k + 1).reversed.toList();
              route.replaceRange(i, k + 1, sub);
              improved = true;
            }
          }
        }
      }
    }

    // Append any orders without coordinates at the end
    route.addAll(withoutCoords);
    return route;
  }

  /// Calculates total cumulative distance in meters across route stops
  static double totalRouteDistance({
    required LatLng origin,
    required List<OrderModel> orderedStops,
  }) {
    if (orderedStops.isEmpty) return 0.0;

    double total = 0.0;
    LatLng current = origin;

    for (final stop in orderedStops) {
      if (stop.dropoffLatLng != null) {
        total += distanceMeters(current, stop.dropoffLatLng!);
        current = stop.dropoffLatLng!;
      }
    }

    return total;
  }

  /// Maps maneuver strings returned by Google Routes API to an icon.
  static IconData getManeuverIcon(String? maneuver) {
    if (maneuver == null || maneuver.isEmpty) {
      return Icons.navigation_rounded;
    }

    final m = maneuver.toUpperCase();
    if (m.contains('LEFT')) {
      if (m.contains('SLIGHT')) return Icons.turn_slight_left_rounded;
      if (m.contains('SHARP')) return Icons.turn_sharp_left_rounded;
      if (m.contains('U_TURN') || m.contains('UTURN')) return Icons.u_turn_left_rounded;
      return Icons.turn_left_rounded;
    }
    if (m.contains('RIGHT')) {
      if (m.contains('SLIGHT')) return Icons.turn_slight_right_rounded;
      if (m.contains('SHARP')) return Icons.turn_sharp_right_rounded;
      if (m.contains('U_TURN') || m.contains('UTURN')) return Icons.u_turn_right_rounded;
      return Icons.turn_right_rounded;
    }
    if (m.contains('ROUNDABOUT') || m.contains('ROTARY')) {
      return Icons.roundabout_right_rounded;
    }
    if (m.contains('RAMP') || m.contains('FORK') || m.contains('MERGE')) {
      return Icons.merge_type_rounded;
    }
    if (m.contains('STRAIGHT') || m.contains('CONTINUE')) {
      return Icons.straight_rounded;
    }

    return Icons.navigation_rounded;
  }
}
