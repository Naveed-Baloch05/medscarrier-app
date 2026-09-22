import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Admin Order Details screen.
///
/// Receives the ACTUAL selected order document (a raw Firestore order map
/// including `id`) and displays every field that genuinely exists in the
/// data. Missing fields are shown as "Not available" — no values are invented.
class AdminOrderDetailsScreen extends StatelessWidget {
  const AdminOrderDetailsScreen({super.key, required this.order});

  final Map<String, dynamic> order;

  static const String _na = 'Not available';

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _date(dynamic value) {
    final dt = _parseDate(value);
    if (dt == null) return _na;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _str(dynamic value) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? _na : s;
  }

  String _yesNo(dynamic value) => (value == true) ? 'Yes' : 'No';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF08100C) : const Color(0xFFF2F5F3);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);

    final itemsRaw = order['items'];
    final List<String> items = itemsRaw is List
        ? itemsRaw.map((e) => e.toString()).toList()
        : const [];

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Order Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
        children: [
          _section(context, 'Status', [
            _row(isDark, 'Status', _str(order['status']), primaryColor),
            _row(isDark, 'Order ID', _str(order['id'])),
            _row(isDark, 'Placed at', _date(order['createdAt'])),
          ]),
          _section(context, 'Customer', [
            _row(isDark, 'Name', _str(order['customerName'])),
            _row(isDark, 'Phone', _str(order['customerPhone'])),
            _row(isDark, 'Drop-off address', _str(order['dropoffAddress'] ?? order['deliveryAddress'])),
          ]),
          _section(context, 'Pharmacy', [
            _row(isDark, 'Pharmacy name', _str(order['pharmacyName'])),
            _row(isDark, 'Pharmacy ID', _str(order['pharmacyId'])),
            _row(isDark, 'Pickup address', _str(order['pickupAddress'])),
          ]),
          _section(context, 'Rider', [
            _row(isDark, 'Rider name', _str(order['riderName'])),
            _row(isDark, 'Rider phone', _str(order['riderPhone'])),
            _row(isDark, 'Rider ID', _str(order['riderId'])),
          ]),
          _section(context, 'Items', [
            if (items.isEmpty)
              _row(isDark, 'Items', _na)
            else
              for (var i = 0; i < items.length; i++)
                _row(isDark, 'Item ${i + 1}', items[i]),
            _row(isDark, 'Controlled medicine', _yesNo(order['controlledDrug'])),
            _row(isDark, 'Cold chain', _yesNo(order['coldChain'])),
          ]),
          _section(context, 'Delivery', [
            _row(isDark, 'Distance', _str(order['distance'])),
            _row(isDark, 'Estimated time', _str(order['estimatedTime'])),
            if (order['deliveryTimeMinutes'] != null)
              _row(isDark, 'Delivery time (min)', order['deliveryTimeMinutes'].toString()),
            _row(isDark, 'Assigned at', _date(order['assignedAt'])),
            _row(isDark, 'Delivered at', _date(order['deliveredAt'])),
          ]),
          _section(context, 'Amount', [
            // The OrderModel does not store per-item quantity/price or a total,
            // so these are truthfully reported as not available.
            _row(isDark, 'Price',
                order.containsKey('price') ? _str(order['price']) : _na),
            _row(isDark, 'Subtotal', order.containsKey('subtotal') ? _str(order['subtotal']) : _na),
            _row(isDark, 'Delivery fee', order.containsKey('deliveryFee') ? _str(order['deliveryFee']) : _na),
            _row(isDark, 'Total amount', order.containsKey('total') ? _str(order['total']) : _na),
          ]),
          _section(context, 'Additional info', [
            _row(isDark, 'Notes', _str(order['notes'] ?? order['note'])),
            _row(isDark, 'Return status', _str(order['returnStatus'])),
            _row(isDark, 'Failure reason', _str(order['failureReason'])),
            _row(isDark, 'Failure note', _str(order['failureNote'])),
            _row(isDark, 'Pickup QR value', _str(order['pickupQrValue'])),
          ]),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> rows) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(bool isDark, String label, String value, [Color? valueColor]) {
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
