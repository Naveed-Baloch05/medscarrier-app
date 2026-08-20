import 'package:flutter/material.dart';

class PharmacyActiveOrderCard extends StatelessWidget {
  const PharmacyActiveOrderCard({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.orderTime,
    required this.medicineCount,
    required this.status,
    required this.onTap,
    this.controlledDrug = false,
    this.coldChain = false,
  });

  final String orderId;
  final String customerName;
  final String orderTime;
  final String medicineCount;
  final String status;
  final VoidCallback onTap;
  final bool controlledDrug;
  final bool coldChain;

  static const Color primaryTeal = Color(0xFF00897B);
  static const Color darkTeal = Color(0xFF004D40);

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'new order':
        return const Color(0xFF2196F3);
      case 'preparing':
        return const Color(0xFFFF9800);
      case 'ready for pickup':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  orderId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: darkTeal,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  orderTime,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(width: 16),
                Icon(Icons.medication_outlined,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  medicineCount,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            if (controlledDrug || coldChain) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: [
                  if (controlledDrug)
                    _Tag(
                      label: 'Controlled Drug',
                      color: const Color(0xFFE53935),
                    ),
                  if (coldChain)
                    _Tag(
                      label: 'Cold Chain',
                      color: const Color(0xFF1E88E5),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
