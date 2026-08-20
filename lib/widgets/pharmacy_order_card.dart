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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // ORDER ID + TIME
            // --------------------------------------------------

            Row(
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const Spacer(),

                Text(
                  order.time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // CUSTOMER INFORMATION
            // --------------------------------------------------

            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Colors.grey.shade700,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${order.medicineCount} '
                        '${order.medicineCount == 1 ? 'Medicine' : 'Medicines'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: Colors.grey,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // DIVIDER
            // --------------------------------------------------

            Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),

            const SizedBox(height: 14),

            // --------------------------------------------------
            // STATUS + TOTAL
            // --------------------------------------------------

            Row(
              children: [
                PharmacyOrderStatusBadge(
                  status: order.status,
                ),

                const Spacer(),

                Text(
                  '£${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
