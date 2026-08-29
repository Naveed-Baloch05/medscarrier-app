import 'package:flutter/material.dart';

import '../bloc/pharmacy_orders/pharmacy_orders_state.dart';
import 'pharmacy_order_status_badge.dart';

class PharmacyOrderCard extends StatelessWidget {
  const PharmacyOrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  final PharmacyOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ORDER ID + TIME
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F7253),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  order.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // CUSTOMER INFORMATION
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: cs.onSurfaceVariant,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.medicineCount} ${order.medicineCount == 1 ? 'Medicine' : 'Medicines'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),

            Divider(height: 1, color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200),
            const SizedBox(height: 14),

            // RIDER INFO
            if (order.riderName.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.delivery_dining_rounded,
                    size: 16,
                    color: const Color(0xFF0F7253),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rider: ${order.riderName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF0F7253),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // STATUS + TOTAL
            Row(
              children: [
                PharmacyOrderStatusBadge(status: order.status),
                const Spacer(),
                Text(
                  '£${order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
