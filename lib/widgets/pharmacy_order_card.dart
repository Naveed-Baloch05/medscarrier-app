import 'package:flutter/material.dart';

import '../bloc/pharmacy_orders/pharmacy_orders_state.dart';
import 'pharmacy_order_status_badge.dart';

class PharmacyOrderCard extends StatelessWidget {
  const PharmacyOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onTrackTap,
  });

  final PharmacyOrder order;
  final VoidCallback? onTap;
  final VoidCallback? onTrackTap;

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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F7253),
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
            const SizedBox(height: 14),

            // CUSTOMER INFORMATION
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: cs.onSurfaceVariant,
                    size: 22,
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
                      const SizedBox(height: 3),
                      if (order.deliveryAddress.isNotEmpty)
                        Text(
                          order.deliveryAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        )
                      else
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
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),

            // BADGES: Controlled Drug / Cold Chain
            if (order.controlledDrug || order.coldChain) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (order.controlledDrug)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Controlled Drug (CD)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  if (order.coldChain)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Cold Chain (2-8°C)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.cyan,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            // FAILURE REASON ALERT
            if (order.isFailed && order.failureReason != null && order.failureReason!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed: ${order.failureReason}${order.failureNote != null && order.failureNote!.isNotEmpty ? " (${order.failureNote})" : ""}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Divider(height: 1, color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200),
            const SizedBox(height: 12),

            // RIDER & STATUS / TRACKING ROW
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order.riderName.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.delivery_dining_rounded,
                              size: 15,
                              color: Color(0xFF0F7253),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Rider: ${order.riderName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF0F7253),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      PharmacyOrderStatusBadge(status: order.status),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // LIVE TRACKING BUTTON OR TOTAL AMOUNT
                if (order.canTrackLive && onTrackTap != null)
                  ElevatedButton.icon(
                    onPressed: onTrackTap,
                    icon: const Icon(Icons.navigation_rounded, size: 14),
                    label: const Text('Track Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7253),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  )
                else
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
