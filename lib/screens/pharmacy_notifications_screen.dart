import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pharmacy_notifications/pharmacy_notifications_bloc.dart';
import '../bloc/pharmacy_notifications/pharmacy_notifications_event.dart';
import '../bloc/pharmacy_notifications/pharmacy_notifications_state.dart';

class PharmacyNotificationsScreen extends StatefulWidget {
  const PharmacyNotificationsScreen({super.key, required this.pharmacyId});

  final String pharmacyId;

  @override
  State<PharmacyNotificationsScreen> createState() =>
      _PharmacyNotificationsScreenState();
}

class _PharmacyNotificationsScreenState
    extends State<PharmacyNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0C1310) : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF0C1310) : theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Notifications',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: cs.onSurface),
            onPressed: () => context
                .read<PharmacyNotificationsBloc>()
                .add(LoadPharmacyNotifications(widget.pharmacyId)),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<PharmacyNotificationsBloc>()
                  .add(const PharmacyNotificationsMarkAllRead());
            },
            child: Text(
              'Mark all read',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F7253)),
            ),
          ),
        ],
      ),
      body: BlocBuilder<PharmacyNotificationsBloc, PharmacyNotificationsState>(
        builder: (context, state) {
          if (state is PharmacyNotificationsLoading ||
              state is PharmacyNotificationsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PharmacyNotificationsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_off_outlined, size: 50),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<PharmacyNotificationsBloc>()
                          .add(LoadPharmacyNotifications(widget.pharmacyId)),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is PharmacyNotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Order updates and alerts will appear here.',
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = state.notifications[index];
                final styling = _typeStyling(n.type, isDark);
                return _NotificationTile(
                  icon: styling.icon,
                  iconColor: styling.iconColor,
                  iconBg: styling.iconBg,
                  title: n.title,
                  body: n.body,
                  time: _formatTime(n.createdAt),
                  isNew: !n.isRead,
                  onTap: () {
                    if (!n.isRead) {
                      context
                          .read<PharmacyNotificationsBloc>()
                          .add(PharmacyNotificationMarkedRead(n.id));
                    }
                  },
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${_monthNames[dt.month - 1]} ${dt.day}';
  }

  static _TypeStyling _typeStyling(String type, bool isDark) {
    switch (type) {
      case 'new_order':
        return _TypeStyling(
          icon: Icons.shopping_cart_rounded,
          iconColor: const Color(0xFF2563EB),
          iconBg: isDark ? const Color(0xFF1A2744) : const Color(0xFFE8F1FF),
        );
      case 'order_ready':
        return _TypeStyling(
          icon: Icons.check_circle_outline,
          iconColor: const Color(0xFF16A34A),
          iconBg: isDark ? const Color(0xFF15301D) : const Color(0xFFE8F8EF),
        );
      case 'order_delivered':
        return _TypeStyling(
          icon: Icons.delivery_dining_rounded,
          iconColor: const Color(0xFF0D9488),
          iconBg: isDark ? const Color(0xFF15332E) : const Color(0xFFE6F7F5),
        );
      case 'order_preparing':
        return _TypeStyling(
          icon: Icons.inventory_rounded,
          iconColor: const Color(0xFFD97706),
          iconBg: isDark ? const Color(0xFF2E2515) : const Color(0xFFFFF4E5),
        );
      case 'low_stock':
        return _TypeStyling(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFDC2626),
          iconBg: isDark ? const Color(0xFF2D1B1B) : const Color(0xFFFEE2E2),
        );
      case 'rider_assigned':
        return _TypeStyling(
          icon: Icons.person_add_outlined,
          iconColor: const Color(0xFF9333EA),
          iconBg: isDark ? const Color(0xFF231840) : const Color(0xFFF3E8FF),
        );
      default:
        return _TypeStyling(
          icon: Icons.notifications_none_outlined,
          iconColor: const Color(0xFF6B7280),
          iconBg: isDark ? const Color(0xFF1D2520) : const Color(0xFFF3F4F6),
        );
    }
  }
}

class _TypeStyling {
  const _TypeStyling({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
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
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;
  final String time;
  final bool isNew;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isNew
              ? (isDark ? const Color(0xFF1A2744) : const Color(0xFFEFF6FF))
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isNew
                ? (isDark ? const Color(0xFF2A4A6B) : const Color(0xFFBFDBFE))
                : (isDark
                    ? const Color(0xFF1D322A)
                    : Colors.grey.shade200),
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
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F7253),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant, height: 1.4),
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
      ),
    );
  }

  Color _darken(Color color) {
    return HSLColor.fromColor(color).withLightness(
      (HSLColor.fromColor(color).lightness - 0.15).clamp(0.0, 1.0),
    ).toColor();
  }
}
