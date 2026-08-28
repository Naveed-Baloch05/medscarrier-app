import 'package:flutter/material.dart';

import '../models/medicine_model.dart';

class PharmacyMedicineCard extends StatelessWidget {
  const PharmacyMedicineCard({
    super.key,
    required this.medicine,
    required this.onOptionsTap,
  });

  final MedicineModel medicine;
  final VoidCallback onOptionsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bool lowStock = medicine.isLowStock;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.medication_outlined,
                  color: cs.onSurfaceVariant,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medicine.genericName,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _tag(context, medicine.category),
                        if (medicine.prescription) ...[
                          const SizedBox(width: 6),
                          _tag(context, 'Rx'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOptionsTap,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 17,
                      color: lowStock ? Colors.red.shade600 : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Stock: ${medicine.stock}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: lowStock ? Colors.red.shade600 : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\u00A3${medicine.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          if (lowStock) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D1B1B) : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 17, color: Colors.red.shade600),
                  const SizedBox(width: 7),
                  Text(
                    'Low stock — threshold: ${medicine.lowStockThreshold}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
