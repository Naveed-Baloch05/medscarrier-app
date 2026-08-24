import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/admin_monitoring/admin_monitoring_bloc.dart';
import '../../bloc/admin_monitoring/admin_monitoring_event.dart';
import '../../bloc/admin_monitoring/admin_monitoring_state.dart';

class AdminRiderMonitoringScreen extends StatefulWidget {
  const AdminRiderMonitoringScreen({super.key});

  @override
  State<AdminRiderMonitoringScreen> createState() => _AdminRiderMonitoringScreenState();
}

class _AdminRiderMonitoringScreenState extends State<AdminRiderMonitoringScreen> {
  late final AdminMonitoringBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = AdminMonitoringBloc();
    _bloc.add(const AdminMonitoringStartRequested());
  }

  @override
  void dispose() {
    _bloc.add(const AdminMonitoringStopRequested());
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<AdminMonitoringBloc, AdminMonitoringState>(
        builder: (context, state) {
          final rawRiders = state is AdminMonitoringActive ? state.riders : const <Map<String, dynamic>>[];
          final riders = _mapRiders(rawRiders);

          return _buildScaffold(riders);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _mapRiders(List<Map<String, dynamic>> riders) {
    return riders.map((rider) {
      final online = rider['online'] == true;

      return <String, dynamic>{
        'id': rider['id'] ?? '',
        'name': (rider['fullName'] ?? '').toString(),
        'online': online,
        'currentOrder': rider['currentOrder'],
        'location': _formatLocation(rider['location']),
        'lastSeen': _formatLastSeen(rider['lastSeen'], online),
        'deliveryStatus':
            (rider['deliveryStatus'] ?? '').toString().isNotEmpty
                ? rider['deliveryStatus'].toString()
                : 'Idle',
      };
    }).toList();
  }

  String _formatLocation(dynamic location) {
    if (location is Map) {
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }
    }
    return 'Location unavailable';
  }

  String _formatLastSeen(dynamic lastSeen, bool online) {
    if (online) {
      return 'Live now';
    }

    DateTime? time;

    if (lastSeen is Timestamp) {
      time = lastSeen.toDate();
    } else if (lastSeen is DateTime) {
      time = lastSeen;
    } else if (lastSeen is String && lastSeen.trim().isNotEmpty) {
      time = DateTime.tryParse(lastSeen);
      if (time == null) {
        return lastSeen;
      }
    }

    if (time == null) {
      return 'Unknown';
    }

    final difference = DateTime.now().difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hrs ago';
    }

    return '${difference.inDays} days ago';
  }

  Widget _buildScaffold(List<Map<String, dynamic>> riders) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF08100C) : const Color(0xFFF2F5F3);
    final cardColor = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);

    final onlineCount = riders.where((r) => r['online'] == true).length;
    final deliveringCount = riders.where((r) => r['currentOrder'] != null).length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Rider Monitoring', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textPrimary),
            onPressed: () {
              _bloc.add(const AdminMonitoringStopRequested());
              _bloc.add(const AdminMonitoringStartRequested());
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              _statCard('Total', '${riders.length}', Icons.people_outline, primaryColor, cardColor, borderColor, textPrimary, textSecondary),
              const SizedBox(width: 8),
              _statCard('Online', '$onlineCount', Icons.wifi, primaryColor, cardColor, borderColor, textPrimary, textSecondary),
              const SizedBox(width: 8),
              _statCard('Delivering', '$deliveringCount', Icons.local_shipping_outlined, primaryColor, cardColor, borderColor, textPrimary, textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          ...riders.map((rider) => _buildRiderCard(rider, cardColor, borderColor, textPrimary, textSecondary, primaryColor, isDark)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color primaryColor, Color cardColor, Color borderColor, Color textPrimary, Color textSecondary) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: primaryColor),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 10, color: textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderCard(Map<String, dynamic> rider, Color cardColor, Color borderColor, Color textPrimary, Color textSecondary, Color primaryColor, bool isDark) {
    final online = rider['online'] == true;
    final hasOrder = rider['currentOrder'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18251F) : const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person_outline_rounded, size: 24, color: primaryColor),
                  ),
                  if (online)
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: hasOrder ? const Color(0xFFFFB74D) : const Color(0xFF0F7253),
                          shape: BoxShape.circle,
                          border: Border.all(color: cardColor, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rider['name'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
                    Text(rider['id'], style: TextStyle(fontSize: 10, color: textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: online ? (isDark ? const Color(0xFF1D322A) : const Color(0xFFE8F5E9)) : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  online ? 'Online' : 'Offline',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: online ? primaryColor : textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111D17) : const Color(0xFFF5F8F6),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              children: [
                _detailRow(Icons.location_on_outlined, 'Location', rider['location'], textPrimary, textSecondary),
                const SizedBox(height: 8),
                _detailRow(Icons.receipt_outlined, 'Current Order', rider['currentOrder'] ?? 'No active order', textPrimary, textSecondary),
                const SizedBox(height: 8),
                _detailRow(Icons.delivery_dining_outlined, 'Status', rider['deliveryStatus'], textPrimary, textSecondary),
                const SizedBox(height: 8),
                _detailRow(Icons.access_time, 'Last Seen', rider['lastSeen'], textPrimary, textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Icon(icon, size: 15, color: textSecondary),
        const SizedBox(width: 8),
        Text(label + ': ', style: TextStyle(fontSize: 11, color: textSecondary)),
        Expanded(child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary))),
      ],
    );
  }
}
