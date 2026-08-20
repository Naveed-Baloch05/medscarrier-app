import 'package:flutter/material.dart';

class PharmacyMedicineCard extends StatelessWidget {
  const PharmacyMedicineCard({
    super.key,
    required this.medicine,
    required this.onOptionsTap,
  });

  final Map<String, dynamic> medicine;
  final VoidCallback onOptionsTap;

  @override
  Widget build(BuildContext context) {
    final int stock = medicine['stock'] as int;
    final int threshold =
        (medicine['lowStockThreshold'] as int?) ?? 10;

    final bool lowStock = stock <= threshold;

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // Medicine Icon
              Container(
                width: 50,
                height: 50,

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                  BorderRadius.circular(14),
                ),

                child: Icon(
                  Icons.medication_outlined,
                  color: Colors.grey.shade700,
                  size: 26,
                ),
              ),

              const SizedBox(width: 13),

              // Medicine Information
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine['name'],
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      medicine['genericName'],
                      style: TextStyle(
                        fontSize: 12,
                        color:
                        Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        _tag(
                          medicine['category'],
                        ),

                        if (medicine['prescription'] ==
                            true) ...[
                          const SizedBox(width: 6),
                          _tag('Rx'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Options
              IconButton(
                onPressed: onOptionsTap,
                icon: const Icon(
                  Icons.more_vert_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),

          const SizedBox(height: 14),

          // Stock + Price
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 17,

                      color: lowStock
                          ? Colors.red.shade600
                          : Colors.grey.shade600,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      'Stock: $stock',

                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w600,

                        color: lowStock
                            ? Colors.red.shade600
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '£${(medicine['price'] as num).toStringAsFixed(2)}',

                style: const TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),

          // Low Stock Warning
          if (lowStock) ...[
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 17,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Low stock — threshold: $threshold',
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

  Widget _tag(String text) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
        BorderRadius.circular(7),
      ),

      child: Text(
        text,

        style: TextStyle(
          fontSize: 10,
          fontWeight:
          FontWeight.w600,
          color:
          Colors.grey.shade700,
        ),
      ),
    );
  }
}