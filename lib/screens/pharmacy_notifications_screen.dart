import 'package:flutter/material.dart';

class PharmacyNotificationsScreen extends StatefulWidget {
  const PharmacyNotificationsScreen({super.key});

  @override
  State<PharmacyNotificationsScreen> createState() => _PharmacyNotificationsScreenState();
}

class _PharmacyNotificationsScreenState extends State<PharmacyNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C1310) : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0C1310) : theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Notifications',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: cs.onSurface),
            onPressed: () => setState(() {}),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read.')),
              );
            },
            child: Text(
              'Mark all read',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F7253)),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        itemCount: _mockNotifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final n = _mockNotifications[index];
          return _NotificationTile(
            icon: n['icon'] as IconData,
            iconColor: n['iconColor'] as Color,
            iconBg: n['iconBg'] as Color,
            title: n['title'] as String,
            body: n['body'] as String,
            time: n['time'] as String,
            isNew: n['isNew'] as bool,
          );
        },
      ),
    );
  }

  static final List<Map<String, dynamic>> _mockNotifications = [
    {
      'icon': Icons.shopping_cart_rounded,
      'iconColor': const Color(0xFF2563EB),
      'iconBg': const Color(0xFFE8F1FF),
      'title': 'New Order Received',
      'body': 'Order #ORD-2057 from Tom Richards — 2 Medicines, £19.98',
      'time': '2 min ago',
      'isNew': true,
    },
    {
      'icon': Icons.shopping_cart_rounded,
      'iconColor': const Color(0xFF2563EB),
      'iconBg': const Color(0xFFE8F1FF),
      'title': 'New Order Received',
      'body': 'Order #ORD-2056 from Emma Watson — 1 Medicine, £14.99',
      'time': '15 min ago',
      'isNew': true,
    },
    {
      'icon': Icons.check_circle_outline,
      'iconColor': const Color(0xFF16A34A),
      'iconBg': const Color(0xFFE8F8EF),
      'title': 'Order Ready for Pickup',
      'body': 'Order #ORD-2050 (Michael Brown) has been handed to rider Ahmed Khan.',
      'time': '28 min ago',
      'isNew': true,
    },
    {
      'icon': Icons.delivery_dining_rounded,
      'iconColor': const Color(0xFF0D9488),
      'iconBg': const Color(0xFFE6F7F5),
      'title': 'Order Delivered',
      'body': 'Order #ORD-2051 (Emily Davis) was delivered by David Lee.',
      'time': '1 hour ago',
      'isNew': false,
    },
    {
      'icon': Icons.inventory_rounded,
      'iconColor': const Color(0xFFD97706),
      'iconBg': const Color(0xFFFFF4E5),
      'title': 'Order Being Prepared',
      'body': 'Order #ORD-2053 (Olivia Taylor) is now being prepared.',
      'time': '1.5 hours ago',
      'isNew': false,
    },
    {
      'icon': Icons.warning_amber_rounded,
      'iconColor': const Color(0xFFDC2626),
      'iconBg': const Color(0xFFFEE2E2),
      'title': 'Low Stock Alert',
      'body': 'Salbutamol Inhaler is running low — only 8 units remaining.',
      'time': '2 hours ago',
      'isNew': false,
    },
    {
      'icon': Icons.delivery_dining_rounded,
      'iconColor': const Color(0xFF0D9488),
      'iconBg': const Color(0xFFE6F7F5),
      'title': 'Order Delivered',
      'body': 'Order #ORD-2054 (William Anderson) was delivered by Ahmed Khan.',
      'time': '3 hours ago',
      'isNew': false,
    },
    {
      'icon': Icons.person_add_outlined,
      'iconColor': const Color(0xFF9333EA),
      'iconBg': const Color(0xFFF3E8FF),
      'title': 'Rider Assigned',
      'body': 'David Lee has been assigned to order #ORD-2055 (Priya Patel).',
      'time': '3.5 hours ago',
      'isNew': false,
    },
  ];
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.time,
    required this.isNew,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;
  final String time;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNew
            ? (isDark ? const Color(0xFF1A2744) : const Color(0xFFEFF6FF))
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew
              ? (isDark ? const Color(0xFF2A4A6B) : const Color(0xFFBFDBFE))
              : (isDark ? const Color(0xFF1D322A) : Colors.grey.shade200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? _darken(iconBg) : iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isNew ? cs.onSurface : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (isNew)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: const Color(0xFF0F7253), shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.4),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _darken(Color color) {
    return HSLColor.fromColor(color).withLightness(
      (HSLColor.fromColor(color).lightness - 0.15).clamp(0.0, 1.0),
    ).toColor();
  }
}
