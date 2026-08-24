import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMonitoringService {
  AdminMonitoringService._();
  static final AdminMonitoringService instance = AdminMonitoringService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _riders =>
      _firestore.collection('riders');

  Stream<List<Map<String, dynamic>>> allRidersLocationStream() {
    return _riders.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
            return _buildRiderLocation(doc.id, doc.data());
          }).toList(),
        );
  }

  Stream<Map<String, dynamic>> riderLocationStream(String riderId) {
    return _riders.doc(riderId).snapshots().map((snapshot) {
      return _buildRiderLocation(snapshot.id, snapshot.data());
    });
  }

  Future<void> updateRiderLocation(
    String riderId,
    double lat,
    double lng,
  ) async {
    try {
      await _riders.doc(riderId).update({
        'location': {'lat': lat, 'lng': lng},
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update rider location: $e');
    }
  }

  Map<String, dynamic> _buildRiderLocation(
    String id,
    Map<String, dynamic>? data,
  ) {
    final safeData = data ?? const <String, dynamic>{};
    return {
      'id': id,
      'fullName': (safeData['fullName'] ?? '').toString(),
      'online': safeData['online'] == true,
      'active': safeData['active'] == true,
      'location': _extractLocation(safeData['location']),
      'currentOrder': safeData['currentOrder']?.toString(),
      'lastSeen': safeData['lastSeen'],
      'deliveryStatus': (safeData['deliveryStatus'] ?? '').toString(),
    };
  }

  Map<String, dynamic> _extractLocation(dynamic location) {
    if (location is GeoPoint) {
      return {'lat': location.latitude, 'lng': location.longitude};
    }
    if (location is Map) {
      final lat = location['lat'] ?? location['latitude'];
      final lng = location['lng'] ?? location['longitude'];
      return {
        'lat': (lat as num?)?.toDouble(),
        'lng': (lng as num?)?.toDouble(),
      };
    }
    return {'lat': null, 'lng': null};
  }
}
