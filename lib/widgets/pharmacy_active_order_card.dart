import 'package:flutter/material.dart';

enum PharmacyOrderStatusType {
  isNew,
  preparing,
  ready,
  riderEnRoute,
  onTheWay,
  delivered,
}

class PharmacyActiveOrderCard extends StatelessWidget {
  const PharmacyActiveOrderCard({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.orderTime,
    required this.medicineCount,
    required this.status,
    required this.onTap,
    this.statusType = PharmacyOrderStatusType.isNew,
    this.location = '',
    this.tags = const [],
    this.actionButtonText,
    this.onActionPressed,
    this.riderName = '',
    this.driverStatus = '',
    this.driverInitials = '',
  });

  final String orderId;
  final String customerName;
  final String orderTime;
  final String medicineCount;
  final String status;
  final VoidCallback onTap;
  final PharmacyOrderStatusType statusType;
  final String location;
  final List<String> tags;
  final String? actionButtonText;
  final VoidCallback? onActionPressed;
  final String riderName;
  final String driverStatus;
  final String driverInitials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final badgeBg = _badgeBg(isDark);
    final badgeText = _badgeText(isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      orderId,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      orderTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: badgeText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: badgeText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer Info
            Text(
              customerName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    location.isNotEmpty
                        ? '$location  •  $medicineCount'
                        : medicineCount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tags (CD, 2-8°C)
            if (tags.isNotEmpty)
              Row(
                children: tags.map((tag) {
                  final isCD = tag == 'CD';
                  final bg = isCD
                      ? (isDark
                          ? const Color(0xFF382E19)
                          : const Color(0xFFFFF3E0))
                      : (isDark
                          ? const Color(0xFF183338)
                          : const Color(0xFFE0F7FA));
                  final border = isCD
                      ? (isDark
                          ? const Color(0xFF8D6E63)
                          : const Color(0xFFFFB74D))
                      : const Color(0xFF4DD0E1);
                  final textColor = isCD
                      ? (isDark
                          ? const Color(0xFFFFB74D)
                          : const Color(0xFFE65100))
                      : (isDark
                          ? const Color(0xFF4DD0E1)
                          : const Color(0xFF00838F));

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      border: Border.all(
                        color: border,
                        width: 0.8,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCD
                              ? Icons.verified_user_outlined
                              : Icons.ac_unit,
                          size: 12,
                          color: textColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tag,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            // Action Button
            if (actionButtonText != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: isDark
                        ? const Color(0xFF0C1310)
                        : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onActionPressed,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        statusType == PharmacyOrderStatusType.isNew
                            ? Icons.check_circle_outline
                            : Icons.arrow_forward,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        actionButtonText!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Driver Info
            if (riderName.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B2421)
                      : const Color(0xFFF7F9F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isDark
                          ? const Color(0xFF2A3A33)
                          : const Color(0xFFE0E0E0),
                      child: Text(
                        driverInitials.isNotEmpty
                            ? driverInitials
                            : riderName[0],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            riderName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (driverStatus.isNotEmpty)
                            Text(
                              driverStatus,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _badgeBg(bool isDark) {
    switch (statusType) {
      case PharmacyOrderStatusType.isNew:
        return isDark
            ? const Color(0xFF223830)
            : const Color(0xFFE8F5E9);
      case PharmacyOrderStatusType.preparing:
        return isDark
            ? const Color(0xFF173931)
            : const Color(0xFFD0EBE1);
      case PharmacyOrderStatusType.ready:
        return isDark
            ? const Color(0xFF1B3321)
            : const Color(0xFFE8F5E9);
      case PharmacyOrderStatusType.riderEnRoute:
      case PharmacyOrderStatusType.onTheWay:
        return isDark
            ? const Color(0xFF23253B)
            : const Color(0xFFE8EAF6);
      case PharmacyOrderStatusType.delivered:
        return isDark
            ? const Color(0xFF1A1A2E)
            : const Color(0xFFF3E5F5);
    }
  }

  Color _badgeText(bool isDark) {
    switch (statusType) {
      case PharmacyOrderStatusType.isNew:
      case PharmacyOrderStatusType.preparing:
      case PharmacyOrderStatusType.ready:
        return isDark
            ? const Color(0xFF32C787)
            : const Color(0xFF0F7253);
      case PharmacyOrderStatusType.riderEnRoute:
      case PharmacyOrderStatusType.onTheWay:
        return isDark
            ? const Color(0xFF9FA8DA)
            : const Color(0xFF3F51B5);
      case PharmacyOrderStatusType.delivered:
        return isDark
            ? const Color(0xFFCE93D8)
            : const Color(0xFF7B1FA2);
    }
  }
}
