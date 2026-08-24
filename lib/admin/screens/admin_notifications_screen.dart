import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/admin_notification/admin_notification_bloc.dart';
import '../../bloc/admin_notification/admin_notification_event.dart';
import '../../bloc/admin_notification/admin_notification_state.dart';
import '../../models/admin_notification_model.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  late final AdminNotificationBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = AdminNotificationBloc()
      ..add(const AdminNotificationLoadRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF08100C) : const Color(0xFFF2F5F3);
    final cardBg = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);

    return BlocProvider<AdminNotificationBloc>.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          actions: [
            BlocBuilder<AdminNotificationBloc, AdminNotificationState>(
              builder: (context, state) {
                final hasUnread = state is AdminNotificationLoaded &&
                    state.unreadCount > 0;
                return TextButton(
                  onPressed: hasUnread
                      ? () => _bloc
                          .add(const AdminNotificationMarkAllRead())
                      : null,
                  child: Text(
                    'Mark all read',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: hasUnread ? primaryColor : textSecondary,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<AdminNotificationBloc, AdminNotificationState>(
          builder: (context, state) {
            final notifications = state is AdminNotificationLoaded
                ? state.notifications
                : <AdminNotificationModel>[];

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = notifications[index] as AdminNotificationModel;
                return _NotificationTile(
                  notification: n,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () {
                    if (!n.isRead) {
                      _bloc.add(AdminNotificationMarkRead(n.id));
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  final AdminNotificationModel notification;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  IconData _getIcon(String type) {
    switch (type) {
      case 'new_order':
        return Icons.shopping_cart_rounded;
      case 'order_delivered':
        return Icons.check_circle_outline;
      case 'rider_assigned':
        return Icons.person_add_outlined;
      case 'pharmacy_registered':
        return Icons.local_pharmacy_outlined;
      case 'support_ticket':
        return Icons.help_outline;
      case 'rider_joined':
        return Icons.delivery_dining_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'new_order':
        return const Color(0xFF2563EB);
      case 'order_delivered':
        return const Color(0xFF16A34A);
      case 'rider_assigned':
        return const Color(0xFF9333EA);
      case 'pharmacy_registered':
        return const Color(0xFF0D9488);
      case 'support_ticket':
        return const Color(0xFFD97706);
      case 'rider_joined':
        return const Color(0xFF0D9488);
      default:
        return primaryColor;
    }
  }

  Color _getIconBg(String type) {
    switch (type) {
      case 'new_order':
        return const Color(0xFFE8F1FF);
      case 'order_delivered':
        return const Color(0xFFE8F8EF);
      case 'rider_assigned':
        return const Color(0xFFF3E8FF);
      case 'pharmacy_registered':
        return const Color(0xFFE6F7F5);
      case 'support_ticket':
        return const Color(0xFFFFF4E5);
      case 'rider_joined':
        return const Color(0xFFE6F7F5);
      default:
        return const Color(0xFFE8F5E9);
    }
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  Color _darken(Color color) {
    return HSLColor.fromColor(color)
        .withLightness(
            (HSLColor.fromColor(color).lightness - 0.15).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor(notification.type);
    final iconBg = _getIconBg(notification.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: !notification.isRead
              ? (isDark ? const Color(0xFF1A2744) : const Color(0xFFEFF6FF))
              : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !notification.isRead
                ? (isDark ? const Color(0xFF2A4A6B) : const Color(0xFFBFDBFE))
                : borderColor,
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
              child: Icon(_getIcon(notification.type), size: 22, color: iconColor),
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
                          notification.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: !notification.isRead ? textPrimary : textSecondary,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getTimeAgo(notification.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary.withValues(alpha: 0.6),
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
}
