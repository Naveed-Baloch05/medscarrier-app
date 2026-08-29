import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/admin_rider/admin_rider_bloc.dart';
import '../../bloc/admin_rider/admin_rider_event.dart';
import '../../bloc/admin_rider/admin_rider_state.dart';
import '../../models/rider_application_model.dart';
import '../../widgets/document_preview_dialog.dart';

class AdminRiderManagementScreen extends StatefulWidget {
const AdminRiderManagementScreen({
super.key,
this.orderId,
this.orderLabel,
});

final String? orderId;
final String? orderLabel;

@override
State<AdminRiderManagementScreen> createState() =>
_AdminRiderManagementScreenState();
}

class _AdminRiderManagementScreenState
extends State<AdminRiderManagementScreen> {

late final AdminRiderBloc _riderBloc;

String _searchQuery = '';
String _selectedFilter = 'All';

String? _pendingAssignOrderId;
String? _assigningRiderName;

final List<String> _filters = [
'All',
'Online',
'Offline',
'Active',
'Inactive',
];

// ============================================================
// INIT STATE
// ============================================================

@override
void initState() {
super.initState();
_riderBloc = AdminRiderBloc()..add(const AdminRiderLoadRequested());
}

@override
void dispose() {
_riderBloc.close();
super.dispose();
}

// ============================================================
// MAP BACKEND RIDERS FOR UI
// Backend keys -> keys expected by the UI below.
// ============================================================

List<Map<String, dynamic>> _mapRidersForUi(
List<Map<String, dynamic>> backendRiders,
) {
return backendRiders.map((rider) {
final bool online =
    rider['online'] == true;

return <String, dynamic>{
'id': rider['id'] ?? '',
'uid': rider['uid'] ?? rider['id'] ?? '',
'name':
    (rider['fullName'] ?? '').toString(),
'phone':
    (rider['phone'] ?? '').toString(),
'email':
    (rider['email'] ?? '').toString(),
'status': rider['active'] == false
    ? 'Inactive'
    : 'Active',
'online': online,
'deliveries': rider['deliveries'] ?? 0,
'currentOrder': rider['currentOrder'],
'location': rider['location'] ??
    'Location unavailable',
'lastSeen': _formatLastSeen(
rider['lastSeen'],
online,
),
};
}).toList();
}

// ============================================================
// FORMAT LAST SEEN
// ============================================================

String _formatLastSeen(
dynamic lastSeen,
bool online,
) {
if (online) {
return 'Live now';
}

DateTime? time;

if (lastSeen is Timestamp) {
time = lastSeen.toDate();
} else if (lastSeen is DateTime) {
time = lastSeen;
} else if (lastSeen is String &&
lastSeen.trim().isNotEmpty) {
time = DateTime.tryParse(lastSeen);

if (time == null) {
return lastSeen;
}
}

if (time == null) {
return 'Unknown';
}

final difference =
DateTime.now().difference(time);

if (difference.inMinutes < 1) {
return 'Just now';
} else if (difference.inMinutes < 60) {
return '${difference.inMinutes} min ago';
} else if (difference.inHours < 24) {
return '${difference.inHours} hrs ago';
}

return '${difference.inDays} days ago';
}

// ============================================================
// FILTERED RIDERS
// ============================================================

List<Map<String, dynamic>> _filteredRiders(
List<Map<String, dynamic>> riders,
) {
List<Map<String, dynamic>> result = List.from(riders);

switch (_selectedFilter) {
case 'Online':
result = result
    .where((rider) => rider['online'] == true)
    .toList();
break;

case 'Offline':
result = result
    .where((rider) => rider['online'] == false)
    .toList();
break;

case 'Active':
result = result
    .where((rider) => rider['status'] == 'Active')
    .toList();
break;

case 'Inactive':
result = result
    .where((rider) => rider['status'] == 'Inactive')
    .toList();
break;
}

if (_searchQuery.trim().isNotEmpty) {
final query = _searchQuery.toLowerCase().trim();

result = result.where((rider) {
return rider['name']
    .toString()
    .toLowerCase()
    .contains(query) ||
rider['id']
    .toString()
    .toLowerCase()
    .contains(query) ||
rider['phone']
    .toString()
    .toLowerCase()
    .contains(query) ||
rider['email']
    .toString()
    .toLowerCase()
    .contains(query);
}).toList();
}

return result;
}

// ============================================================
// BUILD
// ============================================================

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;

final bgColor = isDark
? const Color(0xFF08100C)
    : const Color(0xFFF2F5F3);

final cardColor = isDark
? const Color(0xFF0E1A14)
    : Colors.white;

final textPrimary = isDark
? Colors.white
    : const Color(0xFF191C1B);

final textSecondary = isDark
? const Color(0xFF8B9B94)
    : const Color(0xFF6E7A75);

final primaryColor = isDark
? const Color(0xFF0F7253)
    : const Color(0xFF0F7253);

final borderColor = isDark
? Colors.white.withValues(alpha: 0.06)
    : Colors.black.withValues(alpha: 0.05);

return BlocProvider<AdminRiderBloc>.value(
value: _riderBloc,
child: BlocListener<AdminRiderBloc, AdminRiderState>(
listenWhen: (previous, current) =>
    current is AdminRiderOperationSuccess ||
    current is AdminRiderError,
listener: (context, state) {
  _handleAssignmentResult(state);
},
child: BlocBuilder<AdminRiderBloc, AdminRiderState>(
builder: (context, state) {
final List<Map<String, dynamic>> allRiders;
final List<RiderApplicationModel> pendingApplications;

if (state is AdminRiderLoadedWithApplications) {
  allRiders = _mapRidersForUi(state.riders);
  pendingApplications = state.pendingApplications;
} else if (state is AdminRiderLoaded) {
  allRiders = _mapRidersForUi(state.riders);
  pendingApplications = [];
} else {
  allRiders = <Map<String, dynamic>>[];
  pendingApplications = [];
}

final activeRiders = allRiders
    .where((rider) => rider['status'] == 'Active')
    .length;

final onlineRiders = allRiders
    .where((rider) => rider['online'] == true)
    .length;

final assignedRiders = allRiders
    .where((rider) => rider['currentOrder'] != null)
    .length;

final riders = _filteredRiders(allRiders);

return Scaffold(
backgroundColor: bgColor,

// ========================================================
// APP BAR
// ========================================================

appBar: AppBar(
backgroundColor: bgColor,
elevation: 0,
surfaceTintColor: Colors.transparent,

title: Text(
'Rider Management',
style: TextStyle(
fontSize: 21,
fontWeight: FontWeight.w700,
color: textPrimary,
),
),

actions: [
IconButton(
icon: Icon(Icons.refresh_rounded, color: textPrimary),
onPressed: () => context
    .read<AdminRiderBloc>()
    .add(const AdminRiderRefreshed()),
),
IconButton(
tooltip: 'Add Rider',
onPressed: () {
_showAddRiderSheet();
},
icon: Icon(
Icons.person_add_alt_1_outlined,
color: primaryColor,
),
),
],
),

// ========================================================
// BODY
// ========================================================

body: SafeArea(
child: ListView(
padding: const EdgeInsets.fromLTRB(
16,
4,
16,
30,
),
children: [
// ====================================================
// ASSIGNMENT CONTEXT BANNER
// ====================================================

if (widget.orderId != null && widget.orderId!.isNotEmpty) ...[
  Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(
  horizontal: 14,
  vertical: 13,
  ),
  decoration: BoxDecoration(
  color: primaryColor.withValues(alpha: 0.08),
  borderRadius: BorderRadius.circular(14),
  border: Border.all(
  color: primaryColor.withValues(alpha: 0.25),
  ),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Row(
  children: [
  Icon(
  Icons.local_shipping_outlined,
  size: 18,
  color: primaryColor,
  ),
  const SizedBox(width: 8),
  Expanded(
  child: Text(
  'Assigning order',
  style: TextStyle(
  fontSize: 9,
  fontWeight: FontWeight.w600,
  color: textSecondary,
  letterSpacing: 0.4,
  ),
  ),
  ),
  ],
  ),
  const SizedBox(height: 6),
  Text(
  widget.orderId!,
  style: TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  color: textPrimary,
  ),
  ),
  if (widget.orderLabel != null &&
      widget.orderLabel!.isNotEmpty) ...[
  const SizedBox(height: 3),
  Text(
  widget.orderLabel!,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
  fontSize: 11,
  color: textSecondary,
  ),
  ),
  ],
  ],
  ),
  ),
  const SizedBox(height: 14),
],

// ====================================================
// SUMMARY
// ====================================================

Row(
children: [
Expanded(
child: _summaryCard(
icon: Icons.people_outline_rounded,
title: 'Total',
value: '${allRiders.length}',
cardColor: cardColor,
borderColor: borderColor,
textPrimary: textPrimary,
textSecondary: textSecondary,
primaryColor: primaryColor,
),
),
const SizedBox(width: 8),
Expanded(
child: _summaryCard(
icon: Icons.check_circle_outline_rounded,
title: 'Active',
value: '$activeRiders',
cardColor: cardColor,
borderColor: borderColor,
textPrimary: textPrimary,
textSecondary: textSecondary,
primaryColor: primaryColor,
),
),
const SizedBox(width: 8),
Expanded(
child: _summaryCard(
icon: Icons.circle,
title: 'Online',
value: '$onlineRiders',
cardColor: cardColor,
borderColor: borderColor,
textPrimary: textPrimary,
textSecondary: textSecondary,
primaryColor: primaryColor,
),
),
const SizedBox(width: 8),
Expanded(
child: _summaryCard(
icon: Icons.local_shipping_outlined,
title: 'Assigned',
value: '$assignedRiders',
cardColor: cardColor,
borderColor: borderColor,
textPrimary: textPrimary,
textSecondary: textSecondary,
primaryColor: primaryColor,
),
),
],
),

const SizedBox(height: 18),

// ====================================================
// ADD RIDER BUTTON
// ====================================================

SizedBox(
height: 46,
child: ElevatedButton.icon(
onPressed: () {
_showAddRiderSheet();
},
style: ElevatedButton.styleFrom(
backgroundColor: primaryColor,
foregroundColor: Colors.white,
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(13),
),
),
icon: const Icon(
Icons.person_add_alt_1,
size: 18,
),
label: const Text(
'Add New Rider',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.bold,
),
),
),
),

const SizedBox(height: 18),

// ====================================================
// SEARCH
// ====================================================

TextField(
onChanged: (value) {
setState(() {
_searchQuery = value;
});
},
decoration: InputDecoration(
hintText:
'Search rider, ID, phone or email...',
hintStyle: TextStyle(
fontSize: 12,
color: textSecondary,
),
prefixIcon: Icon(
Icons.search,
size: 20,
color: textSecondary,
),
suffixIcon: _searchQuery.isNotEmpty
? IconButton(
onPressed: () {
setState(() {
_searchQuery = '';
});
},
icon: Icon(
Icons.close,
size: 18,
color: textSecondary,
),
)
    : null,
filled: true,
fillColor: cardColor,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide(
color: borderColor,
),
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide(
color: borderColor,
),
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide(
color: primaryColor,
),
),
),
),

const SizedBox(height: 12),

// ====================================================
// PENDING RIDER APPLICATIONS
// ====================================================

if (pendingApplications.isNotEmpty) ...[
  Row(
    children: [
      Icon(
        Icons.how_to_reg_rounded,
        size: 18,
        color: const Color(0xFFFF9800),
      ),
      const SizedBox(width: 8),
      Text(
        'Pending Applications',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${pendingApplications.length}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF9800),
          ),
        ),
      ),
    ],
  ),
  const SizedBox(height: 10),
  ...pendingApplications.map(
    (app) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildApplicationCard(
        app,
        cardColor: cardColor,
        borderColor: borderColor,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        primaryColor: primaryColor,
        isDark: isDark,
      ),
    ),
  ),
  const SizedBox(height: 18),
],

// ====================================================
// FILTERS
// ====================================================

SizedBox(
height: 40,
child: ListView.separated(
scrollDirection: Axis.horizontal,
itemCount: _filters.length,
separatorBuilder: (_, __) =>
const SizedBox(width: 8),
itemBuilder: (context, index) {
final filter = _filters[index];

int count;

switch (filter) {
case 'Online':
count = allRiders
    .where(
(rider) =>
rider['online'] == true,
)
    .length;
break;

case 'Offline':
count = allRiders
    .where(
(rider) =>
rider['online'] == false,
)
    .length;
break;

case 'Active':
count = allRiders
    .where(
(rider) =>
rider['status'] == 'Active',
)
    .length;
break;

case 'Inactive':
count = allRiders
    .where(
(rider) =>
rider['status'] == 'Inactive',
)
    .length;
break;

default:
count = allRiders.length;
}

return _filterChip(
title: filter,
count: count,
selected:
_selectedFilter == filter,
primaryColor: primaryColor,
cardColor: cardColor,
textSecondary: textSecondary,
isDark: isDark,
);
},
),
),

const SizedBox(height: 18),

// ====================================================
// SECTION TITLE
// ====================================================

Row(
children: [
Text(
'Riders',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w700,
color: textPrimary,
),
),
const SizedBox(width: 8),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 3,
),
decoration: BoxDecoration(
color: primaryColor.withValues(
alpha: 0.10,
),
borderRadius: BorderRadius.circular(10),
),
child: Text(
'${riders.length}',
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.bold,
color: primaryColor,
),
),
),
],
),

const SizedBox(height: 10),

// ====================================================
// RIDER LIST
// ====================================================

if (riders.isEmpty)
_emptyState(
cardColor: cardColor,
textPrimary: textPrimary,
textSecondary: textSecondary,
)
else
...riders.map(
(rider) => Padding(
padding: const EdgeInsets.only(
bottom: 12,
),
child: _buildRiderCard(
rider,
cardColor: cardColor,
borderColor: borderColor,
textPrimary: textPrimary,
textSecondary: textSecondary,
primaryColor: primaryColor,
isDark: isDark,
),
),
),
],
),
),
);
},
),
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
required Color cardColor,
required Color borderColor,
required Color textPrimary,
required Color textSecondary,
required Color primaryColor,
}) {
return Container(
padding: const EdgeInsets.all(11),
decoration: BoxDecoration(
color: cardColor,
borderRadius: BorderRadius.circular(15),
border: Border.all(
color: borderColor,
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
icon,
size: 19,
color: primaryColor,
),
const SizedBox(height: 8),
Text(
title,
style: TextStyle(
fontSize: 9,
color: textSecondary,
),
),
const SizedBox(height: 2),
Text(
value,
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: textPrimary,
),
),
],
),
);
}

// ============================================================
// FILTER CHIP
// ============================================================

Widget _filterChip({
required String title,
required int count,
required bool selected,
required Color primaryColor,
required Color cardColor,
required Color textSecondary,
required bool isDark,
}) {
return GestureDetector(
onTap: () {
setState(() {
_selectedFilter = title;
});
},
child: AnimatedContainer(
duration: const Duration(milliseconds: 180),
padding: const EdgeInsets.symmetric(
horizontal: 13,
vertical: 8,
),
decoration: BoxDecoration(
color: selected
? (isDark
? const Color(0xFF133327)
    : const Color(0xFFDCEFE6))
    : cardColor,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: selected
? primaryColor
    : Colors.grey.withValues(alpha: 0.15),
),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Text(
title,
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.bold,
color: selected
? primaryColor
    : textSecondary,
),
),
const SizedBox(width: 5),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 5,
vertical: 2,
),
decoration: BoxDecoration(
color: selected
? primaryColor
    : Colors.grey.withValues(
alpha: 0.12,
),
borderRadius: BorderRadius.circular(8),
),
child: Text(
'$count',
style: TextStyle(
fontSize: 8,
fontWeight: FontWeight.bold,
color: selected
? Colors.white
    : textSecondary,
),
),
),
],
),
),
);
}

// ============================================================
// RIDER CARD
// ============================================================

Widget _buildRiderCard(
Map<String, dynamic> rider, {
required Color cardColor,
required Color borderColor,
required Color textPrimary,
required Color textSecondary,
required Color primaryColor,
required bool isDark,
}) {
final bool isActive =
rider['status'] == 'Active';

final bool isOnline =
rider['online'] == true;

final bool hasOrder =
rider['currentOrder'] != null;

return Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: cardColor,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: borderColor,
),
boxShadow: [
if (!isDark)
BoxShadow(
color: Colors.black.withValues(
alpha: 0.025,
),
blurRadius: 8,
offset: const Offset(0, 2),
),
],
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
// ======================================================
// HEADER
// ======================================================

Row(
children: [
Stack(
children: [
Container(
width: 50,
height: 50,
decoration: BoxDecoration(
color: isDark
? const Color(0xFF18251F)
    : const Color(0xFFE8F5E9),
shape: BoxShape.circle,
),
child: Icon(
Icons.person_outline_rounded,
size: 26,
color: primaryColor,
),
),

if (isOnline)
Positioned(
right: 1,
bottom: 1,
child: Container(
width: 13,
height: 13,
decoration: BoxDecoration(
color: const Color(
0xFF0F7253,
),
shape: BoxShape.circle,
border: Border.all(
color: cardColor,
width: 2,
),
),
),
),
],
),

const SizedBox(width: 11),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
rider['name'].toString(),
maxLines: 1,
overflow:
TextOverflow.ellipsis,
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.w700,
color: textPrimary,
),
),
const SizedBox(height: 3),
Text(
rider['id'].toString(),
style: TextStyle(
fontSize: 10,
color: textSecondary,
),
),
],
),
),

_statusBadge(
label: rider['status'].toString(),
active: isActive,
),
],
),

const SizedBox(height: 15),

// ======================================================
// CONTACT
// ======================================================

_detailRow(
icon: Icons.phone_outlined,
value: rider['phone'].toString(),
textSecondary: textSecondary,
),

const SizedBox(height: 8),

_detailRow(
icon: Icons.email_outlined,
value: rider['email'].toString(),
textSecondary: textSecondary,
),

const SizedBox(height: 12),

// ======================================================
// LIVE LOCATION
// ======================================================

Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: isDark
? const Color(0xFF111D17)
    : const Color(0xFFF5F8F6),
borderRadius: BorderRadius.circular(11),
),
child: Row(
children: [
Icon(
Icons.location_on_outlined,
size: 17,
color: isOnline
? const Color(0xFF0F7253)
    : textSecondary,
),
const SizedBox(width: 7),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'Current location',
style: TextStyle(
fontSize: 8,
color: textSecondary,
),
),
const SizedBox(height: 2),
Text(
rider['location'].toString(),
style: TextStyle(
fontSize: 11,
fontWeight: FontWeight.w600,
color: textPrimary,
),
),
],
),
),
Text(
rider['lastSeen'].toString(),
style: TextStyle(
fontSize: 9,
color: isOnline
? const Color(0xFF0F7253)
    : textSecondary,
fontWeight: FontWeight.w600,
),
),
],
),
),

const SizedBox(height: 11),

// ======================================================
// ONLINE + CURRENT ORDER
// ======================================================

Row(
children: [
_onlineBadge(
isOnline,
textSecondary: textSecondary,
),

const Spacer(),

if (hasOrder)
Container(
padding: const EdgeInsets.symmetric(
horizontal: 9,
vertical: 6,
),
decoration: BoxDecoration(
color: const Color(
0xFF7C4DFF,
).withValues(alpha: 0.10),
borderRadius:
BorderRadius.circular(20),
),
child: Row(
children: [
const Icon(
Icons.local_shipping_outlined,
size: 13,
color: Color(0xFF7C4DFF),
),
const SizedBox(width: 5),
Text(
rider['currentOrder']
    .toString(),
style: const TextStyle(
fontSize: 9,
fontWeight: FontWeight.bold,
color: Color(
0xFF7C4DFF,
),
),
),
],
),
)
else
Text(
'No active delivery',
style: TextStyle(
fontSize: 10,
color: textSecondary,
),
),
],
),

const SizedBox(height: 11),

// ======================================================
// DELIVERY COUNT
// ======================================================

Row(
children: [
Icon(
Icons.local_shipping_outlined,
size: 16,
color: textSecondary,
),
const SizedBox(width: 5),
Text(
'${rider['deliveries']} completed deliveries',
style: TextStyle(
fontSize: 10,
color: textSecondary,
fontWeight: FontWeight.w500,
),
),
],
),

const SizedBox(height: 12),

Divider(
height: 1,
color: borderColor,
),

const SizedBox(height: 7),

// ======================================================
// ACTIONS
// ======================================================

Row(
children: [
if (widget.orderId != null)
  Expanded(
  child: TextButton.icon(
  onPressed: _pendingAssignOrderId == null
      ? () => _assignOrderToRider(rider)
      : null,
  icon: _pendingAssignOrderId != null &&
          _assigningRiderName == rider['name']
      ? const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Icon(
          Icons.person_add_alt_1,
          size: 16,
          color: primaryColor,
        ),
  label: Text(
  'Assign',
  style: TextStyle(
  color: primaryColor,
  fontWeight: FontWeight.w600,
  fontSize: 11,
  ),
  ),
  ),
  ),
if (widget.orderId != null)
  Container(
  width: 1,
  height: 22,
  color: borderColor,
  ),
Expanded(
child: TextButton.icon(
onPressed: () {
_showRiderDetails(rider);
},
icon: Icon(
Icons.visibility_outlined,
size: 16,
color: primaryColor,
),
label: Text(
'View Details',
style: TextStyle(
color: primaryColor,
fontWeight: FontWeight.w600,
fontSize: 11,
),
),
),
),

Container(
width: 1,
height: 22,
color: borderColor,
),

Expanded(
child: TextButton.icon(
onPressed: () {
_toggleRiderStatus(rider);
},
icon: Icon(
isActive
? Icons.block_outlined
    : Icons.check_circle_outline,
size: 16,
color: isActive
? Colors.red.shade600
    : primaryColor,
),
label: Text(
isActive
? 'Deactivate'
    : 'Activate',
style: TextStyle(
color: isActive
? Colors.red.shade600
    : primaryColor,
fontWeight: FontWeight.w600,
fontSize: 11,
),
),
),
),
],
),
],
),
);
}

// ============================================================
// DETAIL ROW
// ============================================================

Widget _detailRow({
required IconData icon,
required String value,
required Color textSecondary,
}) {
return Row(
children: [
Icon(
icon,
size: 16,
color: textSecondary,
),
const SizedBox(width: 8),
Expanded(
child: Text(
value,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 11,
color: textSecondary,
),
),
),
],
);
}

// ============================================================
// STATUS BADGE
// ============================================================

Widget _statusBadge({
required String label,
required bool active,
}) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 9,
vertical: 6,
),
decoration: BoxDecoration(
color: active
? Colors.green.shade50
    : Colors.red.shade50,
borderRadius: BorderRadius.circular(20),
),
child: Text(
label,
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w700,
color: active
? Colors.green.shade700
    : Colors.red.shade700,
),
),
);
}

// ============================================================
// ONLINE BADGE
// ============================================================

Widget _onlineBadge(
bool online, {
required Color textSecondary,
}) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 9,
vertical: 6,
),
decoration: BoxDecoration(
color: online
? Colors.green.shade50
    : Colors.grey.shade100,
borderRadius: BorderRadius.circular(20),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 7,
height: 7,
decoration: BoxDecoration(
color: online
? Colors.green.shade600
    : Colors.grey.shade500,
shape: BoxShape.circle,
),
),
const SizedBox(width: 6),
Text(
online ? 'Online' : 'Offline',
style: TextStyle(
fontSize: 9,
fontWeight: FontWeight.w600,
color: online
? Colors.green.shade700
    : textSecondary,
),
),
],
),
);
}

// ============================================================
// APPLICATION CARD (pending rider applications)
// ============================================================

Widget _buildApplicationCard(
  RiderApplicationModel app, {
  required Color cardColor,
  required Color borderColor,
  required Color textPrimary,
  required Color textSecondary,
  required Color primaryColor,
  required bool isDark,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xFFFF9800).withValues(alpha: 0.3),
      ),
      boxShadow: [
        if (!isDark)
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 26,
                color: Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Applied ${_formatAppliedDate(app.submittedAt)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Pending',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF9800),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // DETAILS
        _detailRow(
          icon: Icons.email_outlined,
          value: app.email,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 8),
        _detailRow(
          icon: Icons.phone_outlined,
          value: app.phone,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 8),
        _detailRow(
          icon: Icons.directions_car_outlined,
          value: '${app.vehicleType} — ${app.vehicleRegistrationNumber}',
          textSecondary: textSecondary,
        ),

        const SizedBox(height: 12),

        Divider(height: 1, color: borderColor),

        const SizedBox(height: 7),

        // ACTIONS
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () =>
                    _showApplicationDetails(app),
                icon: Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: textSecondary,
                ),
                label: Text(
                  'View Details',
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 22,
              color: borderColor,
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () =>
                    _showRejectApplicationDialog(app),
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.red.shade600,
                ),
                label: Text(
                  'Reject',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 22,
              color: borderColor,
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () =>
                    _approveApplication(app),
                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Color(0xFF0F7253),
                ),
                label: const Text(
                  'Approve',
                  style: TextStyle(
                    color: Color(0xFF0F7253),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

String _formatAppliedDate(DateTime? date) {
  if (date == null) return 'recently';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${date.day}/${date.month}/${date.year}';
}

void _approveApplication(RiderApplicationModel app) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text(
          'Approve Application',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Approve ${app.fullName}\'s rider application? '
          'This will enable their login account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              _riderBloc.add(
                AdminRiderApplicationApprove(
                  app.applicationId,
                ),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application approved.'),
                  backgroundColor: Color(0xFF0F7253),
                ),
              );
            },
            child: const Text(
              'Approve',
              style: TextStyle(
                color: Color(0xFF0F7253),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}

void _showRejectApplicationDialog(RiderApplicationModel app) {
  final reasonController = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text(
          'Reject Application',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject ${app.fullName}\'s rider application?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Rejection reason (optional)',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              _riderBloc.add(
                AdminRiderApplicationReject(
                  app.applicationId,
                  reasonController.text.trim(),
                ),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application rejected.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text(
              'Reject',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
}

void _showApplicationDetails(RiderApplicationModel app) {
  final theme = Theme.of(context);

  showModalBottomSheet(
    context: context,
    backgroundColor: theme.cardColor,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(25),
      ),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20, 15, 20, 30,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: const Color(0xFFFF9800)
                          .withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.person_outline,
                        color: Color(0xFFFF9800),
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.fullName,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            app.email,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Application Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _detailItem('Full Name', app.fullName),
                _detailItem('Email', app.email),
                _detailItem('Phone', app.phone),
                _detailItem('Vehicle Type', app.vehicleType),
                _detailItem(
                  'Registration',
                  app.vehicleRegistrationNumber,
                ),
                _detailItem(
                  'Submitted',
                  app.submittedAt != null
                      ? '${app.submittedAt!.day}/${app.submittedAt!.month}/${app.submittedAt!.year}'
                      : 'Unknown',
                ),
                _detailItem(
                  'Terms Accepted',
                  app.termsAccepted ? 'Yes' : 'No',
                ),
                _detailItem(
                  'Right to Work Consent',
                  app.rightToWorkConsent ? 'Yes' : 'No',
                ),
                _detailItem(
                  'Background Check Consent',
                  app.backgroundCheckConsent ? 'Yes' : 'No',
                ),
                const SizedBox(height: 14),
                const Text(
                  'Driving Licence Documents',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DocumentImageThumbnail(
                        title: 'Licence Front',
                        imageUrl: app.drivingLicenceFrontUrl,
                        height: 120,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DocumentImageThumbnail(
                        title: 'Licence Back',
                        imageUrl: app.drivingLicenceBackUrl,
                        height: 120,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRejectApplicationDialog(app);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(
                            color: Colors.red.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.red.shade600,
                        ),
                        label: Text(
                          'Reject',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approveApplication(app);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F7253),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                        ),
                        label: const Text(
                          'Approve',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ============================================================
// EMPTY STATE
// ============================================================

Widget _emptyState({
required Color cardColor,
required Color textPrimary,
required Color textSecondary,
}) {
return Container(
padding: const EdgeInsets.symmetric(
vertical: 45,
horizontal: 25,
),
decoration: BoxDecoration(
color: cardColor,
borderRadius: BorderRadius.circular(18),
),
child: Column(
children: [
Icon(
Icons.people_outline,
size: 45,
color: textSecondary,
),
const SizedBox(height: 12),
Text(
'No Riders Found',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: textPrimary,
),
),
const SizedBox(height: 5),
Text(
'Try another search or filter.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 11,
color: textSecondary,
),
),
],
),
);
}

// ============================================================
// ASSIGN ORDER TO RIDER
// ============================================================
void _assignOrderToRider(Map<String, dynamic> rider) {
final orderId = widget.orderId;
if (orderId == null || orderId.isEmpty) return;

final uidStr = rider['uid']?.toString().trim() ?? '';
final idStr = rider['id']?.toString().trim() ?? '';
final riderId = uidStr.isNotEmpty ? uidStr : idStr;

if (riderId.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Rider ID is missing. Cannot assign order.'),
      backgroundColor: Colors.red.shade700,
    ),
  );
  return;
}

setState(() {
_pendingAssignOrderId = orderId;
_assigningRiderName = rider['name']?.toString() ?? 'Rider';
});

_riderBloc.add(
AdminRiderOrderAssigned(
riderId,
orderId,
),
);
}

// ============================================================
// HANDLE ASSIGNMENT RESULT (from BLoC listener)
// ============================================================

void _handleAssignmentResult(AdminRiderState state) {
if (_pendingAssignOrderId == null) return;

if (state is AdminRiderOperationSuccess) {
final riderName = _assigningRiderName ?? '';
_pendingAssignOrderId = null;
_assigningRiderName = null;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Order assigned to $riderName'),
backgroundColor: const Color(0xFF0F7253),
),
);
Navigator.of(context).pop();
} else if (state is AdminRiderError) {
_pendingAssignOrderId = null;
_assigningRiderName = null;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Assignment failed: ${state.message}'),
backgroundColor: Colors.red.shade700,
),
);
}
}

// ============================================================
// TOGGLE RIDER STATUS
// ============================================================

void _toggleRiderStatus(
Map<String, dynamic> rider,
) {
final bool currentlyActive =
rider['status'] == 'Active';

if (currentlyActive) {
_showDeactivateConfirmation(rider);
} else {
_riderBloc.add(
AdminRiderActivated(
rider['id'].toString(),
),
);

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'Rider activated successfully.',
),
),
);
}
}

// ============================================================
// DEACTIVATE CONFIRMATION
// ============================================================

void _showDeactivateConfirmation(
Map<String, dynamic> rider,
) {
showDialog(
context: context,
builder: (ctx) {
return AlertDialog(
title: const Text(
'Deactivate Rider',
style: TextStyle(
fontWeight: FontWeight.w700,
),
),
content: Text(
'Are you sure you want to deactivate ${rider['name']}?',
),
actions: [
TextButton(
onPressed: () {
Navigator.pop(ctx);
},
child: const Text(
'Cancel',
style: TextStyle(
color: Colors.grey,
),
),
),
TextButton(
onPressed: () {
_riderBloc.add(
AdminRiderDeactivated(
rider['id'].toString(),
),
);

Navigator.pop(ctx);

ScaffoldMessenger.of(context)
    .showSnackBar(
const SnackBar(
content: Text(
'Rider deactivated successfully.',
),
),
);
},
child: Text(
'Deactivate',
style: TextStyle(
color: Colors.red.shade600,
fontWeight: FontWeight.w600,
),
),
),
],
);
},
);
}

// ============================================================
// ADD RIDER
// ============================================================

void _showAddRiderSheet() {
final nameController = TextEditingController();
final phoneController = TextEditingController();
final emailController = TextEditingController();

showModalBottomSheet(
context: context,
backgroundColor:
Theme.of(context).cardColor,
isScrollControlled: true,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(
top: Radius.circular(25),
),
),
builder: (sheetContext) {
return SafeArea(
child: Padding(
padding: EdgeInsets.fromLTRB(
20,
15,
20,
MediaQuery.of(sheetContext)
    .viewInsets
    .bottom +
25,
),
child: SingleChildScrollView(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Center(
child: Container(
width: 40,
height: 4,
decoration: BoxDecoration(
color: Colors.grey.withValues(
alpha: 0.3,
),
borderRadius:
BorderRadius.circular(10),
),
),
),

const SizedBox(height: 18),

const Text(
'Add New Rider',
style: TextStyle(
fontSize: 21,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 5),

const Text(
'Create a rider account for the delivery platform.',
style: TextStyle(
fontSize: 11,
color: Colors.grey,
),
),

const SizedBox(height: 18),

_inputField(
controller: nameController,
label: 'Full Name',
hint: 'Enter rider name',
icon: Icons.person_outline,
),

const SizedBox(height: 11),

_inputField(
controller: phoneController,
label: 'Phone Number',
hint: 'Enter phone number',
icon: Icons.phone_outlined,
keyboardType:
TextInputType.phone,
),

const SizedBox(height: 11),

_inputField(
controller: emailController,
label: 'Email Address',
hint: 'Enter email address',
icon: Icons.email_outlined,
keyboardType:
TextInputType.emailAddress,
),

const SizedBox(height: 18),

SizedBox(
width: double.infinity,
height: 48,
child: ElevatedButton.icon(
onPressed: () {
final name =
nameController.text.trim();
final phone =
phoneController.text.trim();
final email =
emailController.text.trim();

if (name.isEmpty ||
phone.isEmpty ||
email.isEmpty) {
ScaffoldMessenger.of(
context,
).showSnackBar(
const SnackBar(
content: Text(
'Please complete all rider fields.',
),
),
);
return;
}

_riderBloc.add(
AdminRiderAdded({
'fullName': name,
'phone': phone,
'email': email,
'active': true,
'online': false,
'deliveries': 0,
'currentOrder': null,
'location':
'Location unavailable',
}),
);

Navigator.pop(sheetContext);

ScaffoldMessenger.of(
context,
).showSnackBar(
SnackBar(
content: Text(
'$name added successfully.',
),
backgroundColor:
const Color(0xFF0F7253),
),
);
},
style:
ElevatedButton.styleFrom(
backgroundColor:
const Color(0xFF0F7253),
foregroundColor: Colors.white,
elevation: 0,
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),
),
icon: const Icon(
Icons.person_add_alt_1,
size: 18,
),
label: const Text(
'Create Rider Account',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
),
),
],
),
),
),
);
},
);
}

// ============================================================
// INPUT FIELD
// ============================================================

Widget _inputField({
required TextEditingController controller,
required String label,
required String hint,
required IconData icon,
TextInputType? keyboardType,
}) {
final theme = Theme.of(context);
final isDark =
theme.brightness == Brightness.dark;

return TextField(
controller: controller,
keyboardType: keyboardType,
decoration: InputDecoration(
labelText: label,
hintText: hint,
prefixIcon: Icon(
icon,
size: 19,
),
filled: true,
fillColor: isDark
? const Color(0xFF111D17)
    : const Color(0xFFF5F7F6),
border: OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
borderSide: BorderSide.none,
),
enabledBorder: OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
borderSide: BorderSide.none,
),
focusedBorder: OutlineInputBorder(
borderRadius:
BorderRadius.circular(12),
borderSide: const BorderSide(
color: Color(0xFF0F7253),
),
),
),
);
}

// ============================================================
// RIDER DETAILS
// ============================================================

void _showRiderDetails(
Map<String, dynamic> rider,
) {
final theme = Theme.of(context);
final isDark =
theme.brightness == Brightness.dark;

final primaryColor = isDark
? const Color(0xFF0F7253)
    : const Color(0xFF0F7253);

showModalBottomSheet(
context: context,
backgroundColor: theme.cardColor,
isScrollControlled: true,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(
top: Radius.circular(25),
),
),
builder: (ctx) {
return SafeArea(
child: Padding(
padding: const EdgeInsets.fromLTRB(
20,
15,
20,
30,
),
child: SingleChildScrollView(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Center(
child: Container(
width: 40,
height: 4,
decoration: BoxDecoration(
color: Colors.grey.withValues(
alpha: 0.3,
),
borderRadius:
BorderRadius.circular(10),
),
),
),

const SizedBox(height: 18),

// HEADER
Row(
children: [
CircleAvatar(
radius: 27,
backgroundColor:
primaryColor.withValues(
alpha: 0.12,
),
child: Icon(
Icons.person_outline,
color: primaryColor,
size: 27,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
rider['name'].toString(),
style: const TextStyle(
fontSize: 19,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 3),
Text(
rider['id'].toString(),
style: const TextStyle(
fontSize: 10,
color: Colors.grey,
),
),
],
),
),
_statusBadge(
label:
rider['status'].toString(),
active:
rider['status'] ==
'Active',
),
],
),

const SizedBox(height: 20),

const Text(
'Account Information',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 12),

_detailItem(
'Rider ID',
rider['id'].toString(),
),

_detailItem(
'Name',
rider['name'].toString(),
),

_detailItem(
'Phone',
rider['phone'].toString(),
),

_detailItem(
'Email',
rider['email'].toString(),
),

_detailItem(
'Account Status',
rider['status'].toString(),
),

_detailItem(
'Current Status',
rider['online'] == true
? 'Online'
    : 'Offline',
),

const SizedBox(height: 6),

const Text(
'Live Monitoring',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 12),

_monitoringCard(
icon:
Icons.location_on_outlined,
title: 'Current Location',
value:
rider['location'].toString(),
color: primaryColor,
),

const SizedBox(height: 8),

_monitoringCard(
icon:
Icons.access_time_outlined,
title: 'Last Seen',
value:
rider['lastSeen'].toString(),
color: primaryColor,
),

const SizedBox(height: 8),

_monitoringCard(
icon:
Icons.local_shipping_outlined,
title: 'Current Delivery',
value: rider['currentOrder'] ??
'No active delivery',
color: const Color(
0xFF7C4DFF,
),
),

const SizedBox(height: 8),

_monitoringCard(
icon:
Icons.check_circle_outline,
title: 'Completed Deliveries',
value:
'${rider['deliveries']}',
color: primaryColor,
),

const SizedBox(height: 18),

SizedBox(
width: double.infinity,
height: 46,
child: OutlinedButton.icon(
onPressed: () {
Navigator.pop(ctx);
_showRiderLocation(
rider,
);
},
style: OutlinedButton.styleFrom(
foregroundColor:
primaryColor,
side: BorderSide(
color: primaryColor
    .withValues(
alpha: 0.35,
),
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(
12,
),
),
),
icon: const Icon(
Icons.map_outlined,
size: 18,
),
label: const Text(
'View Rider Location',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 11,
),
),
),
),
],
),
),
),
);
},
);
}

// ============================================================
// MONITORING CARD
// ============================================================

Widget _monitoringCard({
required IconData icon,
required String title,
required String value,
required Color color,
}) {
return Container(
padding: const EdgeInsets.all(11),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.07),
borderRadius: BorderRadius.circular(12),
),
child: Row(
children: [
Icon(
icon,
size: 18,
color: color,
),
const SizedBox(width: 9),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
fontSize: 8,
color: Colors.grey,
),
),
const SizedBox(height: 2),
Text(
value,
style: const TextStyle(
fontSize: 11,
fontWeight: FontWeight.w600,
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
// VIEW RIDER LOCATION
// ============================================================

void _showRiderLocation(
Map<String, dynamic> rider,
) {
final theme = Theme.of(context);
final isDark =
theme.brightness == Brightness.dark;

final primaryColor = isDark
? const Color(0xFF0F7253)
    : const Color(0xFF0F7253);

showModalBottomSheet(
context: context,
backgroundColor: theme.cardColor,
isScrollControlled: true,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(
top: Radius.circular(25),
),
),
builder: (ctx) {
return SafeArea(
child: Padding(
padding: const EdgeInsets.fromLTRB(
20,
15,
20,
25,
),
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Center(
child: Container(
width: 40,
height: 4,
decoration: BoxDecoration(
color: Colors.grey.withValues(
alpha: 0.3,
),
borderRadius:
BorderRadius.circular(10),
),
),
),

const SizedBox(height: 18),

Text(
'${rider['name']} — Live Location',
style: const TextStyle(
fontSize: 19,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 12),

// Temporary map placeholder.
// Google Maps will be connected later.
Container(
height: 220,
width: double.infinity,
decoration: BoxDecoration(
color: isDark
? const Color(0xFF101914)
    : const Color(0xFFE2ECE7),
borderRadius:
BorderRadius.circular(16),
),
child: Stack(
children: [
Center(
child: Container(
width: 52,
height: 52,
decoration: BoxDecoration(
color: primaryColor,
shape: BoxShape.circle,
boxShadow: [
BoxShadow(
color: primaryColor
    .withValues(
alpha: 0.25,
),
blurRadius: 20,
),
],
),
child: const Icon(
Icons.two_wheeler,
color: Colors.white,
size: 27,
),
),
),

Positioned(
top: 15,
left: 15,
child: Container(
padding:
const EdgeInsets.symmetric(
horizontal: 9,
vertical: 6,
),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius:
BorderRadius.circular(
10,
),
),
child: Row(
children: [
Container(
width: 7,
height: 7,
decoration:
const BoxDecoration(
color:
Color(0xFF0F7253),
shape: BoxShape.circle,
),
),
const SizedBox(width: 5),
const Text(
'Live',
style: TextStyle(
fontSize: 10,
fontWeight:
FontWeight.bold,
),
),
],
),
),
),
],
),
),

const SizedBox(height: 12),

Text(
'Current area: ${rider['location']}',
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
),
),

const SizedBox(height: 4),

Text(
'Last update: ${rider['lastSeen']}',
style: const TextStyle(
fontSize: 10,
color: Colors.grey,
),
),
],
),
),
);
},
);
}

// ============================================================
// DETAIL ITEM
// ============================================================

Widget _detailItem(
String title,
String value,
) {
return Padding(
padding: const EdgeInsets.only(
bottom: 13,
),
child: Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
SizedBox(
width: 125,
child: Text(
title,
style: const TextStyle(
fontSize: 10,
color: Colors.grey,
),
),
),
Expanded(
child: Text(
value,
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
),
),
),
],
),
);
}
}

