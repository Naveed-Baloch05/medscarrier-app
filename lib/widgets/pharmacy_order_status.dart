import 'package:flutter/material.dart';

class PharmacyOrderStatus extends StatelessWidget {
  const PharmacyOrderStatus({
    super.key,
    required this.newOrders,
    required this.preparingOrders,
    required this.readyOrders,
    required this.deliveredOrders,
  });

  final int newOrders;
  final int preparingOrders;
  final int readyOrders;
  final int deliveredOrders;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusTile(
          label: 'New',
          count: newOrders,
          color: const Color(0xFF2196F3),
        ),
        const SizedBox(width: 10),
        _StatusTile(
          label: 'Preparing',
          count: preparingOrders,
          color: const Color(0xFFFF9800),
        ),
        const SizedBox(width: 10),
        _StatusTile(
          label: 'Ready',
          count: readyOrders,
          color: const Color(0xFF4CAF50),
        ),
        const SizedBox(width: 10),
        _StatusTile(
          label: 'Delivered',
          count: deliveredOrders,
          color: const Color(0xFF9C27B0),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
