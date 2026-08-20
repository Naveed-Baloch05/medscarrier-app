import 'package:flutter/material.dart';

class PharmacyOrderSummary extends StatelessWidget {
  const PharmacyOrderSummary({
    super.key,
    required this.totalOrders,
    required this.completedOrders,
    required this.activeOrders,
  });

  final int totalOrders;
  final int completedOrders;
  final int activeOrders;

  static const Color primaryTeal = Color(0xFF00897B);
  static const Color darkTeal = Color(0xFF004D40);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkTeal, primaryTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Orders",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(label: 'Total', value: totalOrders),
              const SizedBox(width: 24),
              _StatItem(label: 'Completed', value: completedOrders),
              const SizedBox(width: 24),
              _StatItem(label: 'Active', value: activeOrders),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
