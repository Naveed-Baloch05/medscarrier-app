import 'package:flutter/material.dart';

class AdminRiderMonitoringScreen extends StatefulWidget {
  const AdminRiderMonitoringScreen({super.key});

  @override
  State<AdminRiderMonitoringScreen> createState() => _AdminRiderMonitoringScreenState();
}

class _AdminRiderMonitoringScreenState extends State<AdminRiderMonitoringScreen> {
  final List<Map<String, dynamic>> _riders = [
    {
      'id': 'RID-1001',
      'name': 'Naveed Baloch',
      'online': true,
      'deliveries': 24,
      'currentOrder': '#MC-4818',
      'location': 'Camden High St',
      'lastSeen': 'Live now',
      'deliveryStatus': 'On the way',
    },
    {
      'id': 'RID-1002',
      'name': 'Ali Ahmed',
      'online': false,
      'deliveries': 18,
      'currentOrder': null,
      'location': 'Islington Road',
      'lastSeen': '8 min ago',
      'deliveryStatus': 'Idle',
    },
    {
      'id': 'RID-1003',
      'name': 'Usman Khan',
      'online': true,
      'deliveries': 9,
      'currentOrder': '#MC-4820',
      'location': 'Hackney',
      'lastSeen': 'Live now',
      'deliveryStatus': 'Picking up',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF08100C) : const Color(0xFFF2F5F3);
    final cardColor = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);

    final onlineCount = _riders.where((r) => r['online'] == true).length;
    final deliveringCount = _riders.where((r) => r['currentOrder'] != null).length;

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
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              _statCard('Total', '${_riders.length}', Icons.people_outline, primaryColor, cardColor, borderColor, textPrimary, textSecondary),
              const SizedBox(width: 8),
              _statCard('Online', '$onlineCount', Icons.wifi, primaryColor, cardColor, borderColor, textPrimary, textSecondary),
              const SizedBox(width: 8),
              _statCard('Delivering', '$deliveringCount', Icons.local_shipping_outlined, primaryColor, cardColor, borderColor, textPrimary, textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          ..._riders.map((rider) => _buildRiderCard(rider, cardColor, borderColor, textPrimary, textSecondary, primaryColor, isDark)),
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
                          color: hasOrder ? const Color(0xFFFFB74D) : const Color(0xFF32C787),
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
                  color: online ? (isDark ? const Color(0xFF15301D) : const Color(0xFFE8F5E9)) : Colors.grey.withValues(alpha: 0.12),
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
