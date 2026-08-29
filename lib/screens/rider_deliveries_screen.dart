
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/rider_deliveries/rider_deliveries_bloc.dart';
import '../bloc/rider_deliveries/rider_deliveries_event.dart';
import '../bloc/rider_deliveries/rider_deliveries_state.dart';
import '../models/order_model.dart';
import 'rider_delivery_details_screen.dart';

class RiderDeliveriesScreen extends StatefulWidget {
const RiderDeliveriesScreen({
super.key,
required this.riderId,
this.bloc,
this.initialOrders,
});

final String riderId;
final RiderDeliveriesBloc? bloc;
final List<OrderModel>? initialOrders;

@override
State<RiderDeliveriesScreen> createState() =>
_RiderDeliveriesScreenState();
}

class _RiderDeliveriesScreenState extends State<RiderDeliveriesScreen> {
late final RiderDeliveriesBloc _bloc;
bool _internalBloc = false;

String _selectedFilter = 'All';
String _historyPeriod = 'Today';

final List<String> _filters = [
'All',
'Assigned',
'Picked Up',
'On the Way',
'Completed',
];

final List<String> _historyPeriods = ['Today', 'This Week', 'All Time'];

@override
void initState() {
super.initState();
if (widget.bloc != null) {
_bloc = widget.bloc!;
} else {
_internalBloc = true;
if (widget.initialOrders != null) {
_bloc = RiderDeliveriesBloc(
  initialOrders: widget.initialOrders!,
)..add(RefreshRiderDeliveries(widget.riderId));
} else {
_bloc = RiderDeliveriesBloc()..add(LoadRiderDeliveries(widget.riderId));
}
}
}

@override
void dispose() {
if (_internalBloc) {
_bloc.close();
}
super.dispose();
}

// ============================================================
// CONVERSION: OrderModel -> delivery map for details screen
// ============================================================

Map<String, dynamic> _orderToDelivery(OrderModel order) {
final status = order.isCompleted
    ? 'Completed'
    : (order.status.isEmpty ? 'Assigned' : order.status);

final eta = order.estimatedTime ??
    (order.deliveryTimeMinutes != null
        ? '${order.deliveryTimeMinutes} min'
        : null) ??
    '—';

return {
  'id': order.id,
  'orderId': order.id,
  'pharmacy': order.pharmacyName,
  'customer': order.customerName,
  'pickup': order.pickupAddress,
  'dropoff': order.dropoffAddress,
  'address': order.dropoffAddress,
  'pharmacyAddress': order.pickupAddress,
  'distance': order.distance ?? '—',
  'eta': order.isCompleted ? 'Completed' : eta,
  'time': order.isCompleted ? 'Completed' : eta,
  'controlled': order.controlledDrug,
  'controlledDrug': order.controlledDrug,
  'coldChain': order.coldChain,
  'status': status,
  'date': order.deliveredAt != null
      ? _formatDate(order.deliveredAt!)
      : (order.assignedAt != null ? _formatDate(order.assignedAt!) : ''),
  'timeLabel': order.deliveredAt != null
      ? _formatTime(order.deliveredAt!)
      : (order.assignedAt != null ? _formatTime(order.assignedAt!) : ''),
};

}

String _formatDate(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

String _formatTime(DateTime dt) {
final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
final period = dt.hour >= 12 ? 'PM' : 'AM';
return '${hour == 0 ? 12 : hour}:${dt.minute.toString().padLeft(2, '0')} $period';
}

// ============================================================
// DATA HELPERS
// ============================================================

List<Map<String, dynamic>> _deliveriesFromOrders(List<OrderModel> orders) =>
    orders.map(_orderToDelivery).toList();

List<Map<String, dynamic>> _filteredFromOrders(List<OrderModel> orders) {
final all = _deliveriesFromOrders(orders);
if (_selectedFilter == 'All') return all;
return all.where((d) => d['status'] == _selectedFilter).toList();
}

List<Map<String, dynamic>> _historyFromOrders(List<OrderModel> orders) {
final all = _deliveriesFromOrders(orders);
final completed = all.where((d) {
return d['status'] == 'Completed' || d['status'] == 'Delivered';
}).toList();

final now = DateTime.now();

if (_historyPeriod == 'Today') {
return completed.where((d) {
final date = DateTime.tryParse(d['date'] ?? '');
return date != null &&
date.year == now.year &&
date.month == now.month &&
date.day == now.day;
}).toList();
} else if (_historyPeriod == 'This Week') {
final weekStart = now.subtract(Duration(days: now.weekday - 1));
return completed.where((d) {
final date = DateTime.tryParse(d['date'] ?? '');
return date != null && !date.isBefore(weekStart);
}).toList();
}

return completed;
}

// ============================================================
// BUILD
// ============================================================

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
final cs = theme.colorScheme;

return Scaffold(
backgroundColor:
isDark ? const Color(0xFF0C1310) : theme.scaffoldBackgroundColor,

appBar: AppBar(
backgroundColor:
isDark ? const Color(0xFF0C1310) : theme.scaffoldBackgroundColor,
elevation: 0,
surfaceTintColor: Colors.transparent,
title: Text(
'Deliveries',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.w700,
color: cs.onSurface,
),
),
actions: [
IconButton(
icon: Icon(Icons.refresh_rounded, color: cs.onSurface),
onPressed: () => _bloc.add(RefreshRiderDeliveries(widget.riderId)),
),
],
),

body: BlocBuilder<RiderDeliveriesBloc, RiderDeliveriesState>(
bloc: _bloc,
builder: (context, state) {
if (state is RiderDeliveriesLoading) {
return _buildLoading(context);
}
if (state is RiderDeliveriesError) {
return _buildError(context, state.message);
}

final orders =
(state is RiderDeliveriesLoaded) ? state.orders : <OrderModel>[];

final filteredDeliveries = _filteredFromOrders(orders);

return SafeArea(
child: ListView(
padding: const EdgeInsets.fromLTRB(
20,
8,
20,
30,
),
children: [
_buildSummary(context, orders),

const SizedBox(height: 20),

// ====================================================
// FILTERS
// ====================================================

_buildFilters(context),

const SizedBox(height: 20),

Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
'Your Deliveries',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w700,
color: cs.onSurface,
),
),
Text(
'${filteredDeliveries.length}',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
color: cs.onSurfaceVariant,
),
),
],
),

const SizedBox(height: 12),

if (filteredDeliveries.isEmpty)
_buildFilteredEmptyState(context)
else
...filteredDeliveries.map(
(delivery) => Padding(
padding: const EdgeInsets.only(bottom: 12),
child: _buildDeliveryCard(context, delivery),
),
),

const SizedBox(height: 28),

// ====================================================
// DELIVERY HISTORY
// ====================================================

_buildDeliveryHistorySection(context, orders),
],
),
);
},
),
);
}

Widget _buildLoading(BuildContext context) {
final cs = Theme.of(context).colorScheme;
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
CircularProgressIndicator(color: const Color(0xFF0F7253)),
const SizedBox(height: 16),
Text(
'Loading deliveries...',
style: TextStyle(color: cs.onSurfaceVariant),
),
],
),
);
}

Widget _buildError(BuildContext context, String message) {
final cs = Theme.of(context).colorScheme;
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.cloud_off_rounded, size: 48, color: cs.onSurfaceVariant),
const SizedBox(height: 12),
Text(
message.isEmpty ? 'Unable to load deliveries' : message,
textAlign: TextAlign.center,
style: TextStyle(color: cs.onSurfaceVariant),
),
const SizedBox(height: 16),
FilledButton.icon(
onPressed: () =>
_bloc.add(LoadRiderDeliveries(widget.riderId)),
icon: const Icon(Icons.refresh_rounded),
label: const Text('Retry'),
),
],
),
),
);
}

// ============================================================
// SUMMARY
// ============================================================

Widget _buildSummary(BuildContext context, List<OrderModel> orders) {
final all = _deliveriesFromOrders(orders);
final activeCount = all.where((delivery) {
return delivery['status'] != 'Completed';
}).length;

final completedCount = all.where((delivery) {
return delivery['status'] == 'Completed';
}).length;

return Row(
children: [
Expanded(
child: _summaryCard(
context,
icon: Icons.local_shipping_outlined,
title: 'Active',
value: '$activeCount',
),
),
const SizedBox(width: 12),
Expanded(
child: _summaryCard(
context,
icon: Icons.check_circle_outline_rounded,
title: 'Completed',
value: '$completedCount',
),
),
],
);
}

// ============================================================
// FILTERS
// ============================================================

Widget _buildFilters(BuildContext context) {
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
final cs = theme.colorScheme;
return SizedBox(
height: 42,
child: ListView.separated(
scrollDirection: Axis.horizontal,
physics: const BouncingScrollPhysics(),
itemCount: _filters.length,
separatorBuilder: (_, __) => const SizedBox(width: 8),
itemBuilder: (context, index) {
final filter = _filters[index];
final selected = _selectedFilter == filter;

return GestureDetector(
onTap: () {
setState(() {
_selectedFilter = filter;
});
},
child: AnimatedContainer(
duration: const Duration(milliseconds: 180),
padding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 10,
),
decoration: BoxDecoration(
color: selected
? const Color(0xFF0F7253)
    : theme.cardColor,
borderRadius: BorderRadius.circular(22),
border: Border.all(
color: selected
? const Color(0xFF0F7253)
    : isDark
        ? const Color(0xFF1D322A)
        : Colors.grey.shade300,
),
),
child: Text(
filter,
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
color: selected
? Colors.white
    : cs.onSurfaceVariant,
),
),
),
);
},
),
);
}

// ============================================================
// SUMMARY CARD
// ============================================================

Widget _summaryCard(
BuildContext context, {
required IconData icon,
required String title,
required String value,
}) {
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
final cs = theme.colorScheme;
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200,
),
),
child: Row(
children: [
Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: isDark ? const Color(0xFF15301D) : Colors.grey.shade100,
borderRadius: BorderRadius.circular(12),
),
child: Icon(
icon,
size: 20,
color: isDark ? const Color(0xFF32C787) : Colors.grey.shade700,
),
),
const SizedBox(width: 11),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: TextStyle(
fontSize: 11,
color: cs.onSurfaceVariant,
),
),
const SizedBox(height: 2),
Text(
value,
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.w700,
color: cs.onSurface,
),
),
],
),
),
],
),
);
}

// ============================================================
// DELIVERY CARD
// ============================================================

Widget _buildDeliveryCard(BuildContext context, Map<String, dynamic> delivery) {
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
final cs = theme.colorScheme;
final bool isControlledDrug =
delivery['controlledDrug'] == true;

final bool isColdChain =
delivery['coldChain'] == true;

final bool isCompleted =
delivery['status'] == 'Completed';

return InkWell(
borderRadius: BorderRadius.circular(18),
onTap: () {
_openDelivery(delivery);
},
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200,
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// ----------------------------------------------------
// ORDER + STATUS
// ----------------------------------------------------

Row(
children: [
Expanded(
child: Text(
delivery['orderId'],
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w700,
color: cs.onSurface,
),
),
),
_statusBadge(context, delivery['status']),
],
),

const SizedBox(height: 14),

// ----------------------------------------------------
// PHARMACY
// ----------------------------------------------------

Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: 38,
height: 38,
decoration: BoxDecoration(
color: isDark ? const Color(0xFF15301D) : Colors.grey.shade100,
borderRadius: BorderRadius.circular(11),
),
child: Icon(
Icons.local_pharmacy_outlined,
size: 19,
color: isDark ? const Color(0xFF32C787) : Colors.grey.shade700,
),
),
const SizedBox(width: 11),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
delivery['pharmacy'],
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w600,
color: cs.onSurface,
),
),
const SizedBox(height: 4),
Text(
delivery['address'],
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 12,
color: cs.onSurfaceVariant,
),
),
],
),
),
],
),

const SizedBox(height: 14),

// ----------------------------------------------------
// DISTANCE + ETA
// ----------------------------------------------------

Row(
children: [
_deliveryInfo(context,
Icons.route_outlined,
delivery['distance'],
),
const SizedBox(width: 18),
_deliveryInfo(context,
Icons.access_time_outlined,
delivery['eta'],
),
],
),

// ----------------------------------------------------
// SPECIAL REQUIREMENTS
// ----------------------------------------------------

if (isControlledDrug || isColdChain) ...[
const SizedBox(height: 13),
Wrap(
spacing: 7,
runSpacing: 7,
children: [
if (isControlledDrug)
_specialBadge(
context,
icon: Icons.warning_amber_rounded,
label: 'Controlled Drug',
),
if (isColdChain)
_specialBadge(
context,
icon: Icons.ac_unit_rounded,
label: 'Cold Chain',
),
],
),
],

const SizedBox(height: 15),

// ----------------------------------------------------
// OPEN DELIVERY
// ----------------------------------------------------

SizedBox(
width: double.infinity,
height: 44,
child: OutlinedButton(
onPressed: () {
_openDelivery(delivery);
},
style: OutlinedButton.styleFrom(
foregroundColor: isDark ? const Color(0xFF32C787) : Colors.black,
side: BorderSide(
color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
child: Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Text(
'View Delivery Details',
style: TextStyle(
fontWeight: FontWeight.w600,
color: isDark ? const Color(0xFF32C787) : Colors.black,
),
),
SizedBox(width: 6),
Icon(
Icons.arrow_forward_rounded,
size: 17,
color: isDark ? const Color(0xFF32C787) : Colors.black,
),
],
),
),
),

// Small completed indicator.
if (isCompleted) ...[
const SizedBox(height: 10),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.check_circle,
size: 15,
color: Colors.green.shade600,
),
const SizedBox(width: 5),
Text(
'Delivery completed',
style: TextStyle(
fontSize: 11,
fontWeight: FontWeight.w600,
color: Colors.green.shade600,
),
),
],
),
],
],
),
),
);
}

// ============================================================
// OPEN DELIVERY DETAILS
// ============================================================

  void _openDelivery(Map<String, dynamic> delivery) {
    final String orderId =
        delivery['id']?.toString() ??
            delivery['orderId']?.toString() ??
            '';
    if (orderId.isEmpty) return;

    final deliveryStatus =
        delivery['status']?.toString() ?? 'Assigned';

    final etaValue = delivery['eta']?.toString() ?? '';

    final initialOrder = OrderModel(
      id: orderId,
      pharmacyId: '',
      pharmacyName: delivery['pharmacy']?.toString() ?? '',
      customerName: delivery['customer']?.toString() ?? '',
      customerPhone: '',
      pickupAddress:
          delivery['pickup']?.toString() ??
              delivery['pharmacyAddress']?.toString() ??
              '',
      dropoffAddress:
          delivery['dropoff']?.toString() ??
              delivery['address']?.toString() ??
              '',
      status: deliveryStatus == 'Completed' ? 'Completed' : deliveryStatus,
      distance: delivery['distance']?.toString(),
      estimatedTime: (etaValue.isNotEmpty &&
              etaValue != '—' &&
              etaValue != 'Completed')
          ? etaValue
          : null,
      controlledDrug:
          delivery['controlled'] == true || delivery['controlledDrug'] == true,
      coldChain: delivery['coldChain'] == true,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return RiderDeliveryDetailsScreen(
            orderId: orderId,
            initialOrder: initialOrder,
          );
        },
      ),
    );
  }

// ============================================================
// STATUS BADGE
// ============================================================

Widget _statusBadge(BuildContext context, String status) {
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
Color backgroundColor;
Color textColor;

switch (status) {
case 'Assigned':
backgroundColor = isDark ? const Color(0xFF1D2A3A) : const Color(0xFFE8F0FF);
textColor = const Color(0xFF7C9BEF);
break;

case 'Picked Up':
backgroundColor = isDark ? const Color(0xFF3A2E1D) : const Color(0xFFFFF3D6);
textColor = const Color(0xFFE0A94A);
break;

case 'On the Way':
backgroundColor = isDark ? const Color(0xFF2A1F3A) : const Color(0xFFEDE7F6);
textColor = const Color(0xFF9A7CE0);
break;

case 'Completed':
backgroundColor = isDark ? const Color(0xFF15301D) : const Color(0xFFE4F5EA);
textColor = const Color(0xFF32C787);
break;

default:
backgroundColor = isDark ? const Color(0xFF1D322A) : Colors.grey.shade100;
textColor = isDark ? const Color(0xFF8B9B94) : Colors.grey.shade700;
}

return Container(
padding: const EdgeInsets.symmetric(
horizontal: 9,
vertical: 5,
),
decoration: BoxDecoration(
color: backgroundColor,
borderRadius: BorderRadius.circular(20),
),
child: Text(
status,
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w600,
color: textColor,
),
),
);
}

// ============================================================
// DELIVERY INFORMATION
// ============================================================

Widget _deliveryInfo(
BuildContext context,
IconData icon,
String value,
) {
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
final cs = theme.colorScheme;
return Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
size: 16,
color: cs.onSurfaceVariant,
),
const SizedBox(width: 5),
Text(
value,
style: TextStyle(
fontSize: 11,
color: isDark ? const Color(0xFF8B9B94) : Colors.grey.shade600,
fontWeight: FontWeight.w500,
),
),
],
);
}

// ============================================================
// SPECIAL BADGE
// ============================================================

Widget _specialBadge(
BuildContext context, {
required IconData icon,
required String label,
}) {
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
final cs = theme.colorScheme;
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 9,
vertical: 6,
),
decoration: BoxDecoration(
color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade100,
borderRadius: BorderRadius.circular(10),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
size: 14,
color: isDark ? const Color(0xFF32C787) : Colors.grey.shade700,
),
const SizedBox(width: 5),
Text(
label,
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w600,
color: cs.onSurfaceVariant,
),
),
],
),
);
}

// ============================================================
// DELIVERY HISTORY SECTION
// ============================================================

Widget _buildDeliveryHistorySection(
  BuildContext context,
  List<OrderModel> orders,
) {
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
final cs = theme.colorScheme;
final historyDeliveries = _historyFromOrders(orders);

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
'Delivery History',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w700,
color: cs.onSurface,
),
),
Text(
'${historyDeliveries.length} deliveries',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
color: cs.onSurfaceVariant,
),
),
],
),

const SizedBox(height: 12),

SizedBox(
height: 42,
child: ListView.separated(
scrollDirection: Axis.horizontal,
physics: const BouncingScrollPhysics(),
itemCount: _historyPeriods.length,
separatorBuilder: (_, __) => const SizedBox(width: 8),
itemBuilder: (context, index) {
final period = _historyPeriods[index];
final selected = _historyPeriod == period;
return GestureDetector(
onTap: () => setState(() => _historyPeriod = period),
child: AnimatedContainer(
duration: const Duration(milliseconds: 180),
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
decoration: BoxDecoration(
color: selected ? const Color(0xFF0F7253) : theme.cardColor,
borderRadius: BorderRadius.circular(22),
border: Border.all(
color: selected ? const Color(0xFF0F7253) : isDark ? const Color(0xFF1D322A) : Colors.grey.shade300,
),
),
child: Text(
period,
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
color: selected ? Colors.white : cs.onSurfaceVariant,
),
),
),
);
},
),
),

const SizedBox(height: 14),

if (historyDeliveries.isEmpty)
Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(vertical: 32),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(18),
border: Border.all(color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200),
),
child: Column(
children: [
Icon(Icons.history_rounded, size: 36, color: cs.onSurfaceVariant),
const SizedBox(height: 10),
Text(
'No deliveries $_historyPeriod',
style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
),
const SizedBox(height: 4),
Text(
'Completed deliveries will appear here.',
style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
),
],
),
)
else
...historyDeliveries.map(
(delivery) => Padding(
padding: const EdgeInsets.only(bottom: 12),
child: _buildHistoryCard(context, delivery),
),
),
],
);
}

// ============================================================
// HISTORY CARD
// ============================================================

Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> delivery) {
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
final cs = theme.colorScheme;
return Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200),
),
child: Row(
children: [
Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: isDark ? const Color(0xFF15301D) : const Color(0xFFE4F5EA),
borderRadius: BorderRadius.circular(12),
),
child: const Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF32C787)),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Text(
delivery['orderId'] ?? '',
style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
),
const Spacer(),
Text(
'${delivery['date'] ?? ''} \u2022 ${delivery['time'] ?? ''}',
style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
),
],
),
const SizedBox(height: 4),
Text(
delivery['pharmacy'] ?? '',
style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
),
const SizedBox(height: 2),
Row(
children: [
Icon(Icons.route_outlined, size: 12, color: cs.onSurfaceVariant),
const SizedBox(width: 4),
Text(
delivery['distance'] ?? '',
style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
),
],
),
],
),
),
],
),
);
}

// ============================================================
// FILTERED EMPTY STATE
// ============================================================

Widget _buildFilteredEmptyState(BuildContext context) {
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
final cs = theme.colorScheme;
return Container(
margin: const EdgeInsets.only(top: 10),
padding: const EdgeInsets.symmetric(
horizontal: 20,
vertical: 40,
),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200,
),
),
child: Column(
children: [
Container(
width: 60,
height: 60,
decoration: BoxDecoration(
color: isDark ? const Color(0xFF15301D) : Colors.grey.shade100,
shape: BoxShape.circle,
),
child: Icon(
Icons.local_shipping_outlined,
size: 29,
color: cs.onSurfaceVariant,
),
),
const SizedBox(height: 14),
Text(
'No Deliveries Found',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w700,
color: cs.onSurface,
),
),
const SizedBox(height: 6),
Text(
'There are no ${_selectedFilter.toLowerCase()} deliveries.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 12,
color: cs.onSurfaceVariant,
),
),
],
),
);
}
}

