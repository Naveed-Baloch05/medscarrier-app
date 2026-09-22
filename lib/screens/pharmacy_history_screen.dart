import 'package:flutter/material.dart';

import '../bloc/pharmacy_orders/pharmacy_orders_state.dart';
import '../core/services/pharmacy_orders_service.dart';
import '../widgets/pharmacy_order_status_badge.dart';

/// Pharmacy Order History tab.
///
/// Streams this pharmacy's orders from Firestore in real time and shows the
/// history of deliveries: orders delivered successfully and orders that failed
/// to be delivered. Failed orders display the failure reason recorded by the
/// rider in Firestore (failureReason / failureNote).
class PharmacyHistoryScreen extends StatelessWidget {
  const PharmacyHistoryScreen({
    super.key,
    required this.pharmacyId,
  });

  final String pharmacyId;

  static const Color primaryColor = Color(0xFF0F7253);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0C1310) : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Order History',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<PharmacyOrder>>(
        stream: PharmacyOrdersService.instance
            .pharmacyOrdersStream(pharmacyId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Unable to load history',
              message: 'Please try again later.',
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allOrders = snapshot.data ?? const <PharmacyOrder>[];
          final delivered = allOrders
              .where((o) => o.isDelivered)
              .toList();
          final failed = allOrders
              .where((o) => o.isFailed)
              .toList();

          if (delivered.isEmpty && failed.isEmpty) {
            return _EmptyState(
              icon: Icons.history_rounded,
              title: 'No order history yet',
              message:
                  'Delivered and failed orders will appear here after riders '
                  'complete their deliveries.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await PharmacyOrdersService.instance
                  .getOrders(pharmacyId);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
              children: [
                // ==================================================
                // DELIVERED (SUCCESS) SECTION
                // ==================================================
                _sectionHeader(
                  context,
                  icon: Icons.check_circle_rounded,
                  title: 'Delivered Successfully',
                  count: delivered.length,
                  color: const Color(0xFF15803D),
                ),
                const SizedBox(height: 10),
                if (delivered.isEmpty)
                  _subsectionEmpty(
                    context,
                    'No successful deliveries yet.',
                  )
                else
                  ...delivered.map(
                    (order) => _DeliveredHistoryCard(order: order),
                  ),

                const SizedBox(height: 20),

                // ==================================================
                // FAILED (UNSUCCESSFUL) SECTION
                // ==================================================
                _sectionHeader(
                  context,
                  icon: Icons.cancel_rounded,
                  title: 'Failed to Deliver',
                  count: failed.length,
                  color: const Color(0xFFC62828),
                ),
                const SizedBox(height: 10),
                if (failed.isEmpty)
                  _subsectionEmpty(
                    context,
                    'No failed deliveries.',
                  )
                else
                  ...failed.map(
                    (order) => _FailedHistoryCard(order: order),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _subsectionEmpty(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1D322A)
              : Colors.grey.shade200,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Card for a successfully delivered order.
class _DeliveredHistoryCard extends StatelessWidget {
  const _DeliveredHistoryCard({required this.order});

  final PharmacyOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: PharmacyHistoryScreen.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PharmacyOrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (order.deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.place_outlined,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.access_time_outlined,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                order.time,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (order.riderName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.delivery_dining_rounded,
                    size: 14, color: PharmacyHistoryScreen.primaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Rider: ${order.riderName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PharmacyHistoryScreen.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.medicineCount} '
                '${order.medicineCount == 1 ? 'Medicine' : 'Medicines'}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '£${order.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card for a failed delivery — shows the failure reason recorded in Firestore.
class _FailedHistoryCard extends StatelessWidget {
  const _FailedHistoryCard({required this.order});

  final PharmacyOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final reason = order.failureReason != null && order.failureReason!.isNotEmpty
        ? order.failureReason!
        : 'Delivery failed';

    final note = order.failureNote;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC62828),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PharmacyOrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (order.deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.place_outlined,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.deliveryAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ====================================================
          // FAILURE REASON (FROM FIRESTORE)
          // ====================================================
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: Color(0xFFC62828), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Failure Reason',
                      style: TextStyle(
                        color: Color(0xFFC62828),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: TextStyle(
                    color: isDark ? Colors.red.shade200 : Colors.red.shade900,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (order.riderName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.delivery_dining_rounded,
                    size: 14, color: Color(0xFFC62828)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Rider: ${order.riderName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFC62828),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            order.time,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}