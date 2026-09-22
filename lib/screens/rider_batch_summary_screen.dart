import 'package:flutter/material.dart';
import '../bloc/rider_batch/rider_batch_state.dart';
import '../models/delivery_route_model.dart';
import 'rider_home_screen.dart';

class RiderBatchSummaryScreen extends StatelessWidget {
  const RiderBatchSummaryScreen({
    super.key,
    required this.summaryState,
  });

  final RiderBatchCompletedSummary summaryState;

  static const Color primaryColor = Color(0xFF0F7253);
  static const Color secondaryColor = Color(0xFF32C787);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final int total = summaryState.totalDeliveries;
    final int delivered = summaryState.deliveredCount;
    final int failed = summaryState.failedCount;
    final bool hasFailed = failed > 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Route Summary',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            // 1. Completion Icon & Title (Phase 26)
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: (hasFailed ? Colors.amber : secondaryColor)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasFailed
                      ? Icons.assignment_turned_in_outlined
                      : Icons.check_circle_rounded,
                  color: hasFailed ? Colors.amber.shade800 : primaryColor,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Route Completed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '0 stops remaining',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                summaryState.route?.name ?? 'Delivery Run Saved to Firebase',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Metrics Cards Row
            Row(
              children: [
                _metricCard(
                  context,
                  title: 'Total',
                  count: '$total',
                  icon: Icons.inventory_2_outlined,
                  color: Colors.blue.shade700,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _metricCard(
                  context,
                  title: 'Delivered',
                  count: '$delivered',
                  icon: Icons.check_circle_outline,
                  color: primaryColor,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _metricCard(
                  context,
                  title: 'Failed',
                  count: '$failed',
                  icon: Icons.cancel_outlined,
                  color: Colors.red.shade700,
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // 3. Delivered Stops List
            if (summaryState.deliveredStops.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Delivered Deliveries ($delivered)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...summaryState.deliveredStops.map(
                (stop) => _buildStopSummaryTile(context, stop, isSuccess: true, isDark: isDark),
              ),
              const SizedBox(height: 20),
            ],

            // 4. Failed Stops List
            if (summaryState.failedStops.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Failed Deliveries ($failed)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...summaryState.failedStops.map(
                (stop) => _buildStopSummaryTile(
                  context,
                  stop,
                  isSuccess: false,
                  isDark: isDark,
                  failureReason: stop.failureReason,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 5. Back to Dashboard Action
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => RiderHomeScreen(
                        riderId: summaryState.riderId,
                      ),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.home_rounded),
                label: const Text(
                  'Back to Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D18) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopSummaryTile(
    BuildContext context,
    RouteStopModel stop, {
    required bool isSuccess,
    required bool isDark,
    String? failureReason,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D18) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess
              ? primaryColor.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSuccess
                  ? primaryColor.withValues(alpha: 0.12)
                  : Colors.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.close,
              color: isSuccess ? primaryColor : Colors.red.shade700,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stop.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '#${stop.orderId}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSuccess ? primaryColor : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  stop.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (!isSuccess && failureReason != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Reason: $failureReason',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
