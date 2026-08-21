import 'package:flutter/material.dart';

class PharmacyOrderStatus extends StatelessWidget {
  const PharmacyOrderStatus({
    super.key,
    required this.newOrders,
    required this.preparingOrders,
    required this.readyOrders,
    required this.deliveredOrders,
    this.onNewTap,
    this.onPreparingTap,
    this.onReadyTap,
    this.onDeliveredTap,
  });

  final int newOrders;
  final int preparingOrders;
  final int readyOrders;
  final int deliveredOrders;
  final VoidCallback? onNewTap;
  final VoidCallback? onPreparingTap;
  final VoidCallback? onReadyTap;
  final VoidCallback? onDeliveredTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Order Status',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${newOrders + preparingOrders + readyOrders + deliveredOrders} total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _StatusTile(
              label: 'New',
              count: newOrders,
              icon: Icons.fiber_new_rounded,
              color: const Color(0xFF2196F3),
              onTap: onNewTap,
            ),
            _StatusTile(
              label: 'Preparing',
              count: preparingOrders,
              icon: Icons.inventory_rounded,
              color: const Color(0xFFFF9800),
              onTap: onPreparingTap,
            ),
            _StatusTile(
              label: 'Ready',
              count: readyOrders,
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF4CAF50),
              onTap: onReadyTap,
            ),
            _StatusTile(
              label: 'Delivered',
              count: deliveredOrders,
              icon: Icons.delivery_dining_rounded,
              color: const Color(0xFF9C27B0),
              onTap: onDeliveredTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
