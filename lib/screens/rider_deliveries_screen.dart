
import 'package:flutter/material.dart';

import '../core/services/mock_rider_deliveries_service.dart';
import 'rider_delivery_details_screen.dart';

class RiderDeliveriesScreen extends StatefulWidget {
const RiderDeliveriesScreen({super.key});

@override
State<RiderDeliveriesScreen> createState() =>
_RiderDeliveriesScreenState();
}

class _RiderDeliveriesScreenState extends State<RiderDeliveriesScreen> {
final List<Map<String, dynamic>> _deliveries = [
{
'orderId': 'ORD-1025',
'pharmacy': 'MedCare Pharmacy',
'customer': 'Customer Delivery',
'address': 'Main Market, Lahore',
'status': 'Assigned',
'distance': '3.2 km',
'eta': '12 min',
'controlledDrug': false,
'coldChain': false,
'date': '2026-08-22',
'time': '10:30 AM',
},
{
'orderId': 'ORD-1024',
'pharmacy': 'City Pharmacy',
'customer': 'Customer Delivery',
'address': 'Gulberg, Lahore',
'status': 'Picked Up',
'distance': '5.8 km',
'eta': '18 min',
'controlledDrug': true,
'coldChain': false,
'date': '2026-08-22',
'time': '09:15 AM',
},
{
'orderId': 'ORD-1023',
'pharmacy': 'HealthCare Pharmacy',
'customer': 'Customer Delivery',
'address': 'Model Town, Lahore',
'status': 'On the Way',
'distance': '2.4 km',
'eta': '9 min',
'controlledDrug': false,
'coldChain': true,
'date': '2026-08-21',
'time': '04:45 PM',
},
{
'orderId': 'ORD-1022',
'pharmacy': 'Wellness Pharmacy',
'customer': 'Customer Delivery',
'address': 'DHA Phase 5, Lahore',
'status': 'Completed',
'distance': '4.1 km',
'eta': 'Completed',
'controlledDrug': false,
'coldChain': false,
'date': '2026-08-21',
'time': '02:00 PM',
},
{
'orderId': 'ORD-1020',
'pharmacy': 'Green Life Pharmacy',
'customer': 'Customer Delivery',
'address': 'Johar Town, Lahore',
'status': 'Completed',
'distance': '6.3 km',
'eta': 'Completed',
'controlledDrug': false,
'coldChain': true,
'date': '2026-08-20',
'time': '11:20 AM',
},
{
'orderId': 'ORD-1018',
'pharmacy': 'CarePlus Pharmacy',
'customer': 'Customer Delivery',
'address': 'Liberty Market, Lahore',
'status': 'Completed',
'distance': '3.7 km',
'eta': 'Completed',
'controlledDrug': true,
'coldChain': false,
'date': '2026-08-20',
'time': '09:00 AM',
},
{
'orderId': 'ORD-1015',
'pharmacy': 'MedCare Pharmacy',
'customer': 'Customer Delivery',
'address': 'Gulberg III, Lahore',
'status': 'Completed',
'distance': '2.8 km',
'eta': 'Completed',
'controlledDrug': false,
'coldChain': false,
'date': '2026-08-19',
'time': '03:30 PM',
},
{
'orderId': 'ORD-1012',
'pharmacy': 'City Pharmacy',
'customer': 'Customer Delivery',
'address': 'DHA Phase 1, Lahore',
'status': 'Completed',
'distance': '7.2 km',
'eta': 'Completed',
'controlledDrug': false,
'coldChain': true,
'date': '2026-08-19',
'time': '10:00 AM',
},
{
'orderId': 'ORD-1010',
'pharmacy': 'Wellness Pharmacy',
'customer': 'Customer Delivery',
'address': 'Cavalry Ground, Lahore',
'status': 'Completed',
'distance': '4.5 km',
'eta': 'Completed',
'controlledDrug': false,
'coldChain': false,
'date': '2026-08-18',
'time': '01:15 PM',
},
{
'orderId': 'ORD-1008',
'pharmacy': 'HealthCare Pharmacy',
'customer': 'Customer Delivery',
'address': 'Iqbal Town, Lahore',
'status': 'Completed',
'distance': '5.1 km',
'eta': 'Completed',
'controlledDrug': true,
'coldChain': false,
'date': '2026-08-17',
'time': '11:45 AM',
},
];

List<Map<String, dynamic>> get _allDeliveries {
return [..._deliveries, ...MockRiderDeliveriesService.instance.completedDeliveries];
}

// ============================================================
// FILTER
// ============================================================

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

List<Map<String, dynamic>> get _filteredDeliveries {
if (_selectedFilter == 'All') {
return _allDeliveries;
}

return _allDeliveries.where((delivery) {
return delivery['status'] == _selectedFilter;
}).toList();
}

// ============================================================
// HISTORY
// ============================================================

List<Map<String, dynamic>> get _historyDeliveries {
final completed = _allDeliveries.where((d) {
return d['status'] == 'Completed' || d['status'] == 'Delivered';
}).toList();

final now = DateTime(2026, 8, 22);

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
final filteredDeliveries = _filteredDeliveries;

return Scaffold(
backgroundColor: Colors.grey.shade50,

appBar: AppBar(
backgroundColor: Colors.grey.shade50,
elevation: 0,
surfaceTintColor: Colors.transparent,
title: const Text(
'Deliveries',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.w700,
color: Colors.black,
),
),
actions: [
IconButton(
icon: const Icon(Icons.refresh_rounded, color: Colors.black),
onPressed: () => setState(() {}),
),
],
),

body: SafeArea(
child: ListView(
padding: const EdgeInsets.fromLTRB(
20,
8,
20,
30,
),
children: [
_buildSummary(),

const SizedBox(height: 20),

// ====================================================
// FILTERS
// ====================================================

_buildFilters(),

const SizedBox(height: 20),

Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text(
'Your Deliveries',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w700,
),
),
Text(
'${filteredDeliveries.length}',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
color: Colors.grey.shade500,
),
),
],
),

const SizedBox(height: 12),

if (filteredDeliveries.isEmpty)
_buildFilteredEmptyState()
else
...filteredDeliveries.map(
(delivery) => Padding(
padding: const EdgeInsets.only(bottom: 12),
child: _buildDeliveryCard(delivery),
),
),

const SizedBox(height: 28),

// ====================================================
// DELIVERY HISTORY
// ====================================================

_buildDeliveryHistorySection(),
],
),
),
);
}

// ============================================================
// SUMMARY
// ============================================================

Widget _buildSummary() {
final activeCount = _allDeliveries.where((delivery) {
return delivery['status'] != 'Completed';
}).length;

final completedCount = _allDeliveries.where((delivery) {
return delivery['status'] == 'Completed';
}).length;

return Row(
children: [
Expanded(
child: _summaryCard(
icon: Icons.local_shipping_outlined,
title: 'Active',
value: '$activeCount',
),
),
const SizedBox(width: 12),
Expanded(
child: _summaryCard(
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

Widget _buildFilters() {
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
    : Colors.white,
borderRadius: BorderRadius.circular(22),
border: Border.all(
color: selected
? const Color(0xFF0F7253)
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
    : Colors.grey.shade700,
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

Widget _summaryCard({
required IconData icon,
required String title,
required String value,
}) {
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: Colors.grey.shade200,
),
),
child: Row(
children: [
Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: Colors.grey.shade100,
borderRadius: BorderRadius.circular(12),
),
child: Icon(
icon,
size: 20,
color: Colors.grey.shade700,
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
color: Colors.grey.shade500,
),
),
const SizedBox(height: 2),
Text(
value,
style: const TextStyle(
fontSize: 19,
fontWeight: FontWeight.w700,
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

Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
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
color: Colors.white,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: Colors.grey.shade200,
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
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.w700,
),
),
),
_statusBadge(delivery['status']),
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
color: Colors.grey.shade100,
borderRadius: BorderRadius.circular(11),
),
child: Icon(
Icons.local_pharmacy_outlined,
size: 19,
color: Colors.grey.shade700,
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
style: const TextStyle(
fontSize: 13,
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 4),
Text(
delivery['address'],
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 12,
color: Colors.grey.shade500,
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
_deliveryInfo(
Icons.route_outlined,
delivery['distance'],
),
const SizedBox(width: 18),
_deliveryInfo(
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
icon: Icons.warning_amber_rounded,
label: 'Controlled Drug',
),
if (isColdChain)
_specialBadge(
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
foregroundColor: Colors.black,
side: BorderSide(
color: Colors.grey.shade300,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
child: const Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Text(
'View Delivery Details',
style: TextStyle(
fontWeight: FontWeight.w600,
),
),
SizedBox(width: 6),
Icon(
Icons.arrow_forward_rounded,
size: 17,
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return RiderDeliveryDetailsScreen(
            delivery: Map<String, dynamic>.from(delivery),
          );
        },
      ),
    );
  }

// ============================================================
// STATUS BADGE
// ============================================================

Widget _statusBadge(String status) {
Color backgroundColor;
Color textColor;

switch (status) {
case 'Assigned':
backgroundColor = const Color(0xFFE8F0FF);
textColor = const Color(0xFF3867D6);
break;

case 'Picked Up':
backgroundColor = const Color(0xFFFFF3D6);
textColor = const Color(0xFFB77900);
break;

case 'On the Way':
backgroundColor = const Color(0xFFEDE7F6);
textColor = const Color(0xFF6A43C7);
break;

case 'Completed':
backgroundColor = const Color(0xFFE4F5EA);
textColor = const Color(0xFF208548);
break;

default:
backgroundColor = Colors.grey.shade100;
textColor = Colors.grey.shade700;
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
IconData icon,
String value,
) {
return Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
size: 16,
color: Colors.grey.shade500,
),
const SizedBox(width: 5),
Text(
value,
style: TextStyle(
fontSize: 11,
color: Colors.grey.shade600,
fontWeight: FontWeight.w500,
),
),
],
);
}

// ============================================================
// SPECIAL BADGE
// ============================================================

Widget _specialBadge({
required IconData icon,
required String label,
}) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 9,
vertical: 6,
),
decoration: BoxDecoration(
color: Colors.grey.shade100,
borderRadius: BorderRadius.circular(10),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
size: 14,
color: Colors.grey.shade700,
),
const SizedBox(width: 5),
Text(
label,
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w600,
color: Colors.grey.shade700,
),
),
],
),
);
}

// ============================================================
// DELIVERY HISTORY SECTION
// ============================================================

Widget _buildDeliveryHistorySection() {
final historyDeliveries = _historyDeliveries;

return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
const Text(
'Delivery History',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w700,
),
),
Text(
'${historyDeliveries.length} deliveries',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
color: Colors.grey.shade500,
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
color: selected ? const Color(0xFF7C4DFF) : Colors.white,
borderRadius: BorderRadius.circular(22),
border: Border.all(
color: selected ? const Color(0xFF7C4DFF) : Colors.grey.shade300,
),
),
child: Text(
period,
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
color: selected ? Colors.white : Colors.grey.shade700,
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
color: Colors.white,
borderRadius: BorderRadius.circular(18),
border: Border.all(color: Colors.grey.shade200),
),
child: Column(
children: [
Icon(Icons.history_rounded, size: 36, color: Colors.grey.shade400),
const SizedBox(height: 10),
Text(
'No deliveries $_historyPeriod',
style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
),
const SizedBox(height: 4),
Text(
'Completed deliveries will appear here.',
style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
),
],
),
)
else
...historyDeliveries.map(
(delivery) => Padding(
padding: const EdgeInsets.only(bottom: 12),
child: _buildHistoryCard(delivery),
),
),
],
);
}

// ============================================================
// HISTORY CARD
// ============================================================

Widget _buildHistoryCard(Map<String, dynamic> delivery) {
return Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: Colors.grey.shade200),
),
child: Row(
children: [
Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: const Color(0xFFE4F5EA),
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
style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
),
const Spacer(),
Text(
'${delivery['date'] ?? ''} \u2022 ${delivery['time'] ?? ''}',
style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
),
],
),
const SizedBox(height: 4),
Text(
delivery['pharmacy'] ?? '',
style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
),
const SizedBox(height: 2),
Row(
children: [
Icon(Icons.route_outlined, size: 12, color: Colors.grey.shade400),
const SizedBox(width: 4),
Text(
delivery['distance'] ?? '',
style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
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

Widget _buildFilteredEmptyState() {
return Container(
margin: const EdgeInsets.only(top: 10),
padding: const EdgeInsets.symmetric(
horizontal: 20,
vertical: 40,
),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: Colors.grey.shade200,
),
),
child: Column(
children: [
Container(
width: 60,
height: 60,
decoration: BoxDecoration(
color: Colors.grey.shade100,
shape: BoxShape.circle,
),
child: Icon(
Icons.local_shipping_outlined,
size: 29,
color: Colors.grey.shade500,
),
),
const SizedBox(height: 14),
const Text(
'No Deliveries Found',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w700,
),
),
const SizedBox(height: 6),
Text(
'There are no ${_selectedFilter.toLowerCase()} deliveries.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 12,
color: Colors.grey.shade500,
),
),
],
),
);
}
}

