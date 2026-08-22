
import 'package:flutter/material.dart';
import 'rider_delivery_details_screen.dart';
import 'rider_map_screen.dart';
import 'rider_profile_screen.dart';

void main() {
runApp(const MedsCarrierRiderApp());
}

class MedsCarrierRiderApp extends StatelessWidget {
const MedsCarrierRiderApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'MedsCarrier Rider',

theme: ThemeData(
brightness: Brightness.light,
scaffoldBackgroundColor: const Color(0xFFF2F5F3),
cardColor: Colors.white,
colorScheme: const ColorScheme.light(
primary: Color(0xFF0F7253),
secondary: Color(0xFF32C787),
surface: Colors.white,
onSurface: Color(0xFF191C1B),
),
),

darkTheme: ThemeData(
brightness: Brightness.dark,
scaffoldBackgroundColor: const Color(0xFF0B120E),
cardColor: const Color(0xFF131D18),
colorScheme: const ColorScheme.dark(
primary: Color(0xFF32C787),
secondary: Color(0xFF0F7253),
surface: Color(0xFF131D18),
onSurface: Colors.white,
),
),

themeMode: ThemeMode.system,

home: const RiderHomeScreen(),
);
}
}

// ==========================================================
// RIDER HOME SCREEN
// ==========================================================

class RiderHomeScreen extends StatefulWidget {
const RiderHomeScreen({super.key});

@override
State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
bool isCdConfirmed = true;
bool isColdChainConfirmed = true;

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;

return Scaffold(
backgroundColor: theme.scaffoldBackgroundColor,

body: SafeArea(
child: CustomScrollView(
slivers: [
SliverToBoxAdapter(
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 16.0,
vertical: 12.0,
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// ==================================================
// HEADER
// ==================================================

Row(
children: [
CircleAvatar(
radius: 20,
backgroundColor: isDark
? const Color(0xFF1A382B)
    : const Color(0xFF0F7253),
child: Text(
'TR',
style: TextStyle(
color: isDark
? const Color(0xFF32C787)
    : Colors.white,
fontWeight: FontWeight.bold,
fontSize: 14,
),
),
),

const SizedBox(width: 12),

const Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'Good afternoon',
style: TextStyle(
fontSize: 12,
color: Colors.grey,
),
),
Text(
'Tom Reilly',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
],
),
),

Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 6,
),
decoration: BoxDecoration(
color: isDark
? const Color(0xFF10281E)
    : const Color(0xFFDCEFE6),
borderRadius:
BorderRadius.circular(20),
),
child: Row(
children: [
Container(
width: 7,
height: 7,
decoration: const BoxDecoration(
color: Color(0xFF32C787),
shape: BoxShape.circle,
),
),
const SizedBox(width: 6),
Text(
'Online',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
color: isDark
? const Color(0xFF32C787)
    : const Color(0xFF0F7253),
),
),
],
),
),
],
),

const SizedBox(height: 16),

// ==================================================
// METRICS
// ==================================================

Row(
children: [
_buildMetricCard(
context,
'7',
'Deliveries',
),
const SizedBox(width: 8),
_buildMetricCard(
context,
'18.4',
'Distance',
unit: 'km',
),
const SizedBox(width: 8),
_buildMetricCard(
context,
'3:12',
'On road',
unit: 'h',
),
],
),

const SizedBox(height: 20),

Row(
children: [
Container(
width: 6,
height: 6,
decoration: const BoxDecoration(
color: Color(0xFF7C4DFF),
shape: BoxShape.circle,
),
),
const SizedBox(width: 8),
const Text(
'Active delivery',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
],
),
],
),
),
),

// ==========================================================
// ACTIVE DELIVERY
// ==========================================================

SliverPadding(
padding:
const EdgeInsets.symmetric(horizontal: 16.0),
sliver: SliverToBoxAdapter(
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: isDark
? Colors.white.withValues(alpha: 0.05)
    : Colors.black.withValues(alpha: 0.04),
),
boxShadow: [
if (!isDark)
BoxShadow(
color:
Colors.black.withValues(alpha: 0.02),
blurRadius: 8,
offset: const Offset(0, 2),
),
],
),
child: Column(
children: [
// ORDER HEADER

Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Flexible(
child: Text(
'#MC-4818',
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
color: Color(0xFF32C787),
),
overflow: TextOverflow.ellipsis,
),
),

Container(
padding:
const EdgeInsets.symmetric(
horizontal: 10,
vertical: 4,
),
decoration: BoxDecoration(
color: isDark
? const Color(0xFF202038)
    : const Color(0xFFEDE7F6),
borderRadius:
BorderRadius.circular(12),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 6,
height: 6,
decoration:
const BoxDecoration(
color: Color(0xFF7C4DFF),
shape: BoxShape.circle,
),
),
const SizedBox(width: 6),
const Text(
'On the way',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
color: Color(0xFF7C4DFF),
),
),
],
),
),
],
),

const SizedBox(height: 16),

// PICKUP

Row(
children: [
Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: isDark
? const Color(0xFF133327)
    : const Color(0xFFE8F5E9),
shape: BoxShape.circle,
),
child: const Icon(
Icons.storefront,
size: 18,
color: Color(0xFF32C787),
),
),
const SizedBox(width: 12),
const Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'PICKUP',
style: TextStyle(
fontSize: 10,
color: Colors.grey,
fontWeight: FontWeight.bold,
),
),
Text(
'Camden Pharmacy',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
),
),
Text(
'Camden High St, NW1',
style: TextStyle(
fontSize: 12,
color: Colors.grey,
),
),
],
),
),
],
),

// CONNECTOR

Padding(
padding: const EdgeInsets.only(
left: 16.0,
top: 2,
bottom: 2,
),
child: Row(
children: [
SizedBox(
width: 17,
child: Column(
children: List.generate(
3,
(index) => Container(
margin:
const EdgeInsets.symmetric(
vertical: 2,
),
width: 2,
height: 4,
color:
Colors.grey.withValues(alpha: 0.4),
),
),
),
),
],
),
),

// DROP OFF

Row(
children: [
Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: isDark
? const Color(0xFF1D2622)
    : const Color(0xFFF0F0F0),
shape: BoxShape.circle,
),
child: const Icon(
Icons.location_on_outlined,
size: 18,
color: Colors.grey,
),
),
const SizedBox(width: 12),
const Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
'DROP-OFF',
style: TextStyle(
fontSize: 10,
color: Colors.grey,
fontWeight: FontWeight.bold,
),
),
Text(
'Alessia Rossi',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
),
),
Text(
'Primrose Hill, NW3',
style: TextStyle(
fontSize: 12,
color: Colors.grey,
),
),
],
),
),
],
),

const SizedBox(height: 16),

// DISTANCE / ETA

Container(
padding:
const EdgeInsets.symmetric(vertical: 12),
decoration: BoxDecoration(
color: isDark
? const Color(0xFF0F1814)
    : const Color(0xFFF7F9F8),
borderRadius:
BorderRadius.circular(12),
),
child: Row(
children: [
Expanded(
child: Column(
children: [
RichText(
text: TextSpan(
text: '3.2 ',
style: TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
color: theme
    .colorScheme.onSurface,
),
children: const [
TextSpan(
text: 'km',
style: TextStyle(
fontSize: 12,
color: Colors.grey,
),
),
],
),
),
const SizedBox(height: 2),
const Text(
'Distance left',
style: TextStyle(
fontSize: 11,
color: Colors.grey,
),
),
],
),
),

Container(
width: 1,
height: 28,
color:
Colors.grey.withValues(alpha: 0.2),
),

Expanded(
child: Column(
children: [
RichText(
text: TextSpan(
text: '12 ',
style: TextStyle(
fontSize: 18,
fontWeight:
FontWeight.bold,
color: theme
    .colorScheme.onSurface,
),
children: const [
TextSpan(
text: 'min',
style: TextStyle(
fontSize: 12,
color: Colors.grey,
),
),
],
),
),
const SizedBox(height: 2),
const Text(
'ETA • 2:38 PM',
style: TextStyle(
fontSize: 11,
color: Colors.grey,
),
),
],
),
),
],
),
),

const SizedBox(height: 12),

// CONTROLLED DRUG

_buildSafetyToggleTile(
context,
title:
'Carrying a Controlled Drug',
subtitle:
'Signature required at handover',
icon: Icons.verified_user_outlined,
value: isCdConfirmed,
accentColor:
const Color(0xFFFFB74D),
bgColor: isDark
? const Color(0xFF282115)
    : const Color(0xFFFAF0E6),
borderColor: isDark
? const Color(0xFF42331C)
    : const Color(0xFFF5DDC2),
onChanged: (val) {
setState(() {
isCdConfirmed = val;
});
},
),

const SizedBox(height: 8),

// COLD CHAIN

_buildSafetyToggleTile(
context,
title:
'Carrying cold-chain medicine',
subtitle:
'Keep in cool box • 2–8°C',
icon: Icons.ac_unit,
value: isColdChainConfirmed,
accentColor:
const Color(0xFF4DD0E1),
bgColor: isDark
? const Color(0xFF12282C)
    : const Color(0xFFE6F7F9),
borderColor: isDark
? const Color(0xFF193F46)
    : const Color(0xFFC3EEF3),
onChanged: (val) {
setState(() {
isColdChainConfirmed = val;
});
},
),

const SizedBox(height: 16),

// BUTTONS

Row(
children: [
Expanded(
flex: 3,
child: SizedBox(
height: 52,
child: ElevatedButton.icon(
style:
ElevatedButton.styleFrom(
backgroundColor: isDark
? const Color(0xFF32C787)
    : const Color(0xFF0F7253),
foregroundColor: isDark
? const Color(0xFF0B120E)
    : Colors.white,
elevation: 0,
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),
),
onPressed: () {},
icon: const Icon(
Icons.navigation_outlined,
size: 18,
),
label: const Text(
'Navigate',
style: TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 15,
),
),
),
),
),

const SizedBox(width: 8),

Expanded(
flex: 2,
child: SizedBox(
height: 52,
child: OutlinedButton(
style:
OutlinedButton.styleFrom(
backgroundColor: isDark
? const Color(0xFF19241E)
    : const Color(0xFFF5F7F6),
side: BorderSide(
color: isDark
? Colors.white12
    : Colors.black12,
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),
),
onPressed: () {},
child: FittedBox(
fit: BoxFit.scaleDown,
child: Column(
mainAxisSize:
MainAxisSize.min,
children: [
Row(
mainAxisSize:
MainAxisSize.min,
children: [
Icon(
Icons.edit_outlined,
size: 14,
color: theme
    .colorScheme
    .onSurface,
),
const SizedBox(width: 4),
Text(
'Complete',
style: TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 13,
color: theme
    .colorScheme
    .onSurface,
),
),
],
),
const Text(
'Name + signature',
style: TextStyle(
fontSize: 9,
color: Colors.grey,
),
),
],
),
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
),

// ==========================================================
// NEXT UP
// ==========================================================

SliverToBoxAdapter(
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 16.0,
vertical: 16.0,
),
child: Row(
mainAxisAlignment:
MainAxisAlignment.spaceBetween,
children: [
const Text(
'Next up',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
Text(
'2 assigned',
style: TextStyle(
fontSize: 12,
color: isDark
? const Color(0xFF8C9894)
    : Colors.grey,
),
),
],
),
),
),

SliverPadding(
padding:
const EdgeInsets.symmetric(horizontal: 16.0),
sliver: SliverList(
delegate: SliverChildListDelegate([
_buildNextUpItem(
context,
orderId: '#MC-4820',
pharmacyName: 'Camden Pharmacy',
status: 'Ready',
distance: '0.8 km away',
isColdChain: true,
),

const SizedBox(height: 8),

_buildNextUpItem(
context,
orderId: '#MC-4823',
pharmacyName:
'Riverside Pharmacy',
status: 'Ready',
distance: '2.1 km away',
isColdChain: false,
),

const SizedBox(height: 24),
]),
),
),
],
),
),

// ================================================================
// HOME BOTTOM NAVIGATION
// ================================================================

bottomNavigationBar: BottomNavigationBar(
currentIndex: 0,
type: BottomNavigationBarType.fixed,
selectedItemColor: isDark
? const Color(0xFF32C787)
    : const Color(0xFF0F7253),
unselectedItemColor: Colors.grey,
backgroundColor: theme.cardColor,
elevation: 8,

onTap: (index) {
// HOME
if (index == 0) {
return;
}

// MAP
if (index == 1) {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const RiderMapScreen(),
),
);
return;
}

// DELIVERIES
if (index == 2) {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const RiderDeliveriesScreen(),
),
);
return;
}

// ACCOUNT
if (index == 3) {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const RiderProfileScreen(),
),
);
}
},

items: const [
BottomNavigationBarItem(
icon: Icon(Icons.home_outlined),
activeIcon: Icon(Icons.home),
label: 'Home',
),
BottomNavigationBarItem(
icon: Icon(Icons.map_outlined),
activeIcon: Icon(Icons.map),
label: 'Map',
),
BottomNavigationBarItem(
icon: Icon(
Icons.local_shipping_outlined,
),
activeIcon: Icon(
Icons.local_shipping,
),
label: 'Deliveries',
),
BottomNavigationBarItem(
icon: Icon(Icons.person_outline),
activeIcon: Icon(Icons.person),
label: 'Account',
),
],
),
);
}

// ================================================================
// METRIC CARD
// ================================================================

Widget _buildMetricCard(
BuildContext context,
String value,
String label, {
String? unit,
}) {
final isDark =
Theme.of(context).brightness ==
Brightness.dark;

return Expanded(
child: Container(
padding: const EdgeInsets.symmetric(
vertical: 14,
horizontal: 12,
),
decoration: BoxDecoration(
color: isDark
? const Color(0xFF131D18)
    : Colors.white,
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: isDark
? Colors.white.withValues(alpha: 0.05)
    : Colors.black.withValues(alpha: 0.04),
),
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
RichText(
text: TextSpan(
text: value,
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: isDark
? Colors.white
    : const Color(0xFF191C1B),
),
children: [
if (unit != null)
TextSpan(
text: ' $unit',
style: const TextStyle(
fontSize: 11,
fontWeight: FontWeight.normal,
color: Colors.grey,
),
),
],
),
),
const SizedBox(height: 4),
Text(
label,
style: const TextStyle(
fontSize: 11,
color: Colors.grey,
),
),
],
),
),
);
}

// ================================================================
// SAFETY TOGGLE
// ================================================================

Widget _buildSafetyToggleTile(
BuildContext context, {
required String title,
required String subtitle,
required IconData icon,
required bool value,
required Color accentColor,
required Color bgColor,
required Color borderColor,
required ValueChanged<bool> onChanged,
}) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 8,
),
decoration: BoxDecoration(
color: bgColor,
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: borderColor,
),
),
child: Row(
children: [
Icon(
icon,
size: 16,
color: accentColor,
),
const SizedBox(width: 10),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
title,
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
color: accentColor,
),
),
Text(
subtitle,
style: TextStyle(
fontSize: 10,
color:
accentColor.withValues(alpha: 0.8),
),
),
],
),
),

Switch(
value: value,
activeThumbColor: Colors.white,
activeTrackColor: accentColor,
onChanged: onChanged,
),
],
),
);
}

// ================================================================
// NEXT UP ITEM
// ================================================================

Widget _buildNextUpItem(
BuildContext context, {
required String orderId,
required String pharmacyName,
required String status,
required String distance,
required bool isColdChain,
}) {
final theme = Theme.of(context);
final isDark =
theme.brightness == Brightness.dark;

return Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(14),
border: Border.all(
color: isDark
? Colors.white.withValues(alpha: 0.05)
    : Colors.black.withValues(alpha: 0.04),
),
),
child: Row(
children: [
Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: isDark
? const Color(0xFF12241C)
    : const Color(0xFFE8F5E9),
borderRadius:
BorderRadius.circular(8),
),
child: const Icon(
Icons.storefront,
size: 18,
color: Color(0xFF32C787),
),
),

const SizedBox(width: 12),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
Flexible(
child: Text(
orderId,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 13,
),
overflow:
TextOverflow.ellipsis,
),
),

if (isColdChain) ...[
const SizedBox(width: 6),

Container(
padding:
const EdgeInsets.symmetric(
horizontal: 6,
vertical: 2,
),
decoration: BoxDecoration(
color: isDark
? const Color(0xFF12282C)
    : const Color(0xFFE0F7FA),
borderRadius:
BorderRadius.circular(6),
border: Border.all(
color:
const Color(0xFF4DD0E1),
width: 0.6,
),
),
child: const Row(
children: [
Icon(
Icons.ac_unit,
size: 10,
color:
Color(0xFF4DD0E1),
),
SizedBox(width: 2),
Text(
'2–8°C',
style: TextStyle(
fontSize: 9,
color:
Color(0xFF4DD0E1),
fontWeight:
FontWeight.bold,
),
),
],
),
),
],
],
),

const SizedBox(height: 2),

Text(
'$pharmacyName • $status',
style: const TextStyle(
fontSize: 11,
color: Colors.grey,
),
),
],
),
),

Text(
distance,
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
),
),

const SizedBox(width: 4),

const Icon(
Icons.chevron_right,
size: 18,
color: Colors.grey,
),
],
),
);
}
}

// ==========================================================
// DELIVERIES SCREEN
// ==========================================================

class RiderDeliveriesScreen extends StatefulWidget {
const RiderDeliveriesScreen({super.key});

@override
State<RiderDeliveriesScreen> createState() =>
_RiderDeliveriesScreenState();
}

class _RiderDeliveriesScreenState
extends State<RiderDeliveriesScreen> {
int selectedTab = 0;

final List<Map<String, dynamic>> deliveries = [
{
'id': '#MC-4818',
'pharmacy': 'Camden Pharmacy',
'customer': 'Alessia Rossi',
'pickup': 'Camden High St, NW1',
'dropoff': 'Primrose Hill, NW3',
'status': 'On the way',
'distance': '3.2 km',
'time': '12 min',
'coldChain': true,
'controlled': true,
},
{
'id': '#MC-4820',
'pharmacy': 'Camden Pharmacy',
'customer': 'James Wilson',
'pickup': 'Camden High St, NW1',
'dropoff': 'Kentish Town, NW5',
'status': 'Ready',
'distance': '0.8 km',
'time': '5 min',
'coldChain': true,
'controlled': false,
},
{
'id': '#MC-4823',
'pharmacy': 'Riverside Pharmacy',
'customer': 'Sophia Brown',
'pickup': 'Riverside Road, NW1',
'dropoff': 'Hampstead, NW3',
'status': 'Ready',
'distance': '2.1 km',
'time': '9 min',
'coldChain': false,
'controlled': false,
},
{
'id': '#MC-4815',
'pharmacy': 'Central Pharmacy',
'customer': 'Oliver Smith',
'pickup': 'High Street, NW1',
'dropoff': 'Belsize Park, NW3',
'status': 'Delivered',
'distance': '4.6 km',
'time': 'Completed',
'coldChain': false,
'controlled': true,
},
];

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);
final isDark =
theme.brightness == Brightness.dark;

final filteredDeliveries = selectedTab == 0
? deliveries
    : selectedTab == 1
? deliveries
    .where(
(item) =>
item['status'] == 'Ready' ||
item['status'] == 'On the way',
)
    .toList()
    : deliveries
    .where(
(item) =>
item['status'] == 'Delivered',
)
    .toList();

return Scaffold(
backgroundColor:
theme.scaffoldBackgroundColor,

appBar: AppBar(
backgroundColor:
theme.scaffoldBackgroundColor,
elevation: 0,
centerTitle: false,
title: const Text(
'Deliveries',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.bold,
),
),
),

body: Column(
children: [
Padding(
padding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 8,
),
child: Row(
children: [
_buildFilterTab(
context,
'All',
0,
deliveries.length,
),
const SizedBox(width: 8),
_buildFilterTab(
context,
'Active',
1,
deliveries
    .where(
(item) =>
item['status'] == 'Ready' ||
item['status'] ==
'On the way',
)
    .length,
),
const SizedBox(width: 8),
_buildFilterTab(
context,
'Completed',
2,
deliveries
    .where(
(item) =>
item['status'] ==
'Delivered',
)
    .length,
),
],
),
),

Expanded(
child: filteredDeliveries.isEmpty
? Center(
child: Column(
mainAxisSize:
MainAxisSize.min,
children: [
Icon(
Icons
    .local_shipping_outlined,
size: 54,
color: Colors.grey
    .withValues(alpha: 0.5),
),
const SizedBox(
height: 12,
),
const Text(
'No deliveries here',
style: TextStyle(
fontSize: 16,
fontWeight:
FontWeight.bold,
),
),
],
),
)
    : ListView.separated(
padding:
const EdgeInsets.fromLTRB(
16,
12,
16,
24,
),
itemCount:
filteredDeliveries.length,
separatorBuilder: (_, __) =>
const SizedBox(height: 10),
itemBuilder:
(context, index) {
return _buildDeliveryCard(
context,
filteredDeliveries[index],
);
},
),
),
],
),

// ============================================================
// DELIVERIES BOTTOM NAVIGATION
// ============================================================

bottomNavigationBar:
BottomNavigationBar(
currentIndex: 2,
type:
BottomNavigationBarType.fixed,
selectedItemColor: isDark
? const Color(0xFF32C787)
    : const Color(0xFF0F7253),
unselectedItemColor:
Colors.grey,
backgroundColor:
theme.cardColor,
elevation: 8,

onTap: (index) {
// HOME
if (index == 0) {
Navigator.pop(context);
return;
}

// MAP
if (index == 1) {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const RiderMapScreen(),
),
);
return;
}

// DELIVERIES
if (index == 2) {
return;
}

// ACCOUNT
if (index == 3) {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const RiderProfileScreen(),
),
);
}
},

items: const [
BottomNavigationBarItem(
icon:
Icon(Icons.home_outlined),
activeIcon:
Icon(Icons.home),
label: 'Home',
),
BottomNavigationBarItem(
icon:
Icon(Icons.map_outlined),
activeIcon:
Icon(Icons.map),
label: 'Map',
),
BottomNavigationBarItem(
icon: Icon(
Icons
    .local_shipping_outlined,
),
activeIcon: Icon(
Icons.local_shipping,
),
label: 'Deliveries',
),
BottomNavigationBarItem(
icon: Icon(
Icons.person_outline,
),
activeIcon:
Icon(Icons.person),
label: 'Account',
),
],
),
);
}

// ================================================================
// FILTER TAB
// ================================================================

Widget _buildFilterTab(
BuildContext context,
String title,
int index,
int count,
) {
final theme = Theme.of(context);
final isDark =
theme.brightness ==
Brightness.dark;
final selected =
selectedTab == index;

return Expanded(
child: GestureDetector(
onTap: () {
setState(() {
selectedTab = index;
});
},
child: Container(
padding:
const EdgeInsets.symmetric(
vertical: 10,
horizontal: 8,
),
decoration:
BoxDecoration(
color: selected
? (isDark
? const Color(
0xFF133327,
)
    : const Color(
0xFFDCEFE6,
))
    : theme.cardColor,
borderRadius:
BorderRadius.circular(12),
border: Border.all(
color: selected
? const Color(
0xFF32C787,
)
    : (isDark
? Colors.white
    .withValues(
alpha: 0.05,
)
    : Colors.black
    .withValues(
alpha: 0.05,
)),
),
),
child: Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Text(
title,
style: TextStyle(
fontSize: 12,
fontWeight:
FontWeight.bold,
color: selected
? (isDark
? const Color(
0xFF32C787,
)
    : const Color(
0xFF0F7253,
))
    : Colors.grey,
),
),
const SizedBox(width: 5),
Container(
padding:
const EdgeInsets.symmetric(
horizontal: 5,
vertical: 2,
),
decoration:
BoxDecoration(
color: selected
? const Color(
0xFF32C787,
)
    : Colors.grey
    .withValues(
alpha: 0.15,
),
borderRadius:
BorderRadius.circular(8),
),
child: Text(
'$count',
style: TextStyle(
fontSize: 9,
fontWeight:
FontWeight.bold,
color: selected
? Colors.white
    : Colors.grey,
),
),
),
],
),
),
),
);
}

// ================================================================
// DELIVERY CARD
// ================================================================

Widget _buildDeliveryCard(
BuildContext context,
Map<String, dynamic> delivery,
) {
final theme = Theme.of(context);
final isDark =
theme.brightness ==
Brightness.dark;

final String status =
delivery['status'];

final bool isCompleted =
status == 'Delivered';

final bool isActive =
status == 'On the way';

final Color statusColor =
isCompleted
? const Color(0xFF32C787)
    : isActive
? const Color(0xFF7C4DFF)
    : const Color(0xFFFFA726);

return GestureDetector(
onTap: () {
_showDeliveryDetails(
context,
delivery,
);
},
child: Container(
padding:
const EdgeInsets.all(14),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius:
BorderRadius.circular(18),
border: Border.all(
color: isDark
? Colors.white
    .withValues(
alpha: 0.05,
)
    : Colors.black
    .withValues(
alpha: 0.04,
),
),
boxShadow: [
if (!isDark)
BoxShadow(
color: Colors.black
    .withValues(
alpha: 0.02,
),
blurRadius: 8,
offset:
const Offset(0, 2),
),
],
),
child: Column(
children: [
Row(
children: [
Container(
padding:
const EdgeInsets.all(
9,
),
decoration:
BoxDecoration(
color: isDark
? const Color(
0xFF12241C,
)
    : const Color(
0xFFE8F5E9,
),
borderRadius:
BorderRadius.circular(
10,
),
),
child: Icon(
isCompleted
? Icons
    .check_circle_outline
    : Icons.storefront,
size: 19,
color:
const Color(
0xFF32C787,
),
),
),

const SizedBox(width: 10),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,
children: [
Text(
delivery['id'],
style:
const TextStyle(
fontSize: 14,
fontWeight:
FontWeight.bold,
),
),
const SizedBox(
height: 3,
),
Text(
delivery[
'pharmacy'],
style:
const TextStyle(
fontSize: 11,
color:
Colors.grey,
),
),
],
),
),

Container(
padding:
const EdgeInsets
    .symmetric(
horizontal: 9,
vertical: 5,
),
decoration:
BoxDecoration(
color: statusColor
    .withValues(
alpha: 0.10,
),
borderRadius:
BorderRadius.circular(
10,
),
),
child: Row(
children: [
Container(
width: 6,
height: 6,
decoration:
BoxDecoration(
color:
statusColor,
shape:
BoxShape.circle,
),
),
const SizedBox(
width: 5,
),
Text(
status,
style: TextStyle(
fontSize: 10,
fontWeight:
FontWeight.bold,
color:
statusColor,
),
),
],
),
),
],
),

const SizedBox(height: 14),

// PICKUP

Row(
children: [
Container(
width: 28,
height: 28,
decoration:
BoxDecoration(
color: isDark
? const Color(
0xFF133327,
)
    : const Color(
0xFFE8F5E9,
),
shape:
BoxShape.circle,
),
child: const Icon(
Icons.storefront,
size: 15,
color:
Color(0xFF32C787),
),
),

const SizedBox(width: 9),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,
children: [
const Text(
'PICKUP',
style:
TextStyle(
fontSize: 9,
fontWeight:
FontWeight.bold,
color:
Colors.grey,
),
),
Text(
delivery['pickup'],
style:
const TextStyle(
fontSize: 11,
fontWeight:
FontWeight.w600,
),
),
],
),
),
],
),

Padding(
padding:
const EdgeInsets.only(
left: 13,
top: 3,
bottom: 3,
),
child: Align(
alignment:
Alignment.centerLeft,
child: Container(
width: 2,
height: 9,
color: Colors.grey
    .withValues(
alpha: 0.35,
),
),
),
),

// DROP OFF

Row(
children: [
Container(
width: 28,
height: 28,
decoration:
BoxDecoration(
color: isDark
? const Color(
0xFF1D2622,
)
    : const Color(
0xFFF0F0F0,
),
shape:
BoxShape.circle,
),
child: const Icon(
Icons
    .location_on_outlined,
size: 15,
color:
Colors.grey,
),
),

const SizedBox(width: 9),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,
children: [
const Text(
'DROP-OFF',
style:
TextStyle(
fontSize: 9,
fontWeight:
FontWeight.bold,
color:
Colors.grey,
),
),
Text(
'${delivery['customer']} • ${delivery['dropoff']}',
style:
const TextStyle(
fontSize: 11,
fontWeight:
FontWeight.w600,
),
overflow:
TextOverflow
    .ellipsis,
),
],
),
),
],
),

const SizedBox(height: 12),

// INFO CHIPS

Row(
children: [
_buildInfoChip(
context,
Icons.route_outlined,
delivery['distance'],
),

const SizedBox(width: 6),

_buildInfoChip(
context,
Icons.access_time,
delivery['time'],
),

if (delivery['coldChain']) ...[
const SizedBox(width: 6),
_buildInfoChip(
context,
Icons.ac_unit,
'2–8°C',
color:
const Color(
0xFF4DD0E1,
),
),
],

if (delivery['controlled']) ...[
const SizedBox(width: 6),
_buildInfoChip(
context,
Icons
    .verified_user_outlined,
'CD',
color:
const Color(
0xFFFFB74D,
),
),
],

const Spacer(),

const Icon(
Icons.chevron_right,
size: 20,
color: Colors.grey,
),
],
),
],
),
),
);
}

// ================================================================
// INFO CHIP
// ================================================================

Widget _buildInfoChip(
BuildContext context,
IconData icon,
String text, {
Color color = Colors.grey,
}) {
final theme = Theme.of(context);
final isDark =
theme.brightness ==
Brightness.dark;

return Container(
padding:
const EdgeInsets.symmetric(
horizontal: 7,
vertical: 5,
),
decoration:
BoxDecoration(
color: color == Colors.grey
? (isDark
? const Color(
0xFF1D2622,
)
    : const Color(
0xFFF2F4F3,
))
    : color.withValues(
alpha: 0.10,
),
borderRadius:
BorderRadius.circular(7),
),
child: Row(
mainAxisSize:
MainAxisSize.min,
children: [
Icon(
icon,
size: 11,
color: color,
),
const SizedBox(width: 3),
Text(
text,
style: TextStyle(
fontSize: 9,
fontWeight:
FontWeight.bold,
color: color,
),
),
],
),
);
}

// ================================================================
// DELIVERY DETAILS
// ================================================================

void _showDeliveryDetails(
BuildContext context,
Map<String, dynamic> delivery,
) {
final theme = Theme.of(context);

showModalBottomSheet(
context: context,
backgroundColor:
theme.cardColor,
isScrollControlled: true,
shape:
const RoundedRectangleBorder(
borderRadius:
BorderRadius.vertical(
top: Radius.circular(24),
),
),
builder: (context) {
return SafeArea(
child: Padding(
padding:
const EdgeInsets.fromLTRB(
20,
12,
20,
24,
),
child: Column(
mainAxisSize:
MainAxisSize.min,
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Center(
child: Container(
width: 40,
height: 4,
decoration:
BoxDecoration(
color: Colors.grey
    .withValues(
alpha: 0.3,
),
borderRadius:
BorderRadius.circular(
4,
),
),
),
),

const SizedBox(height: 20),

Row(
children: [
Expanded(
child: Text(
delivery['id'],
style:
const TextStyle(
fontSize: 20,
fontWeight:
FontWeight.bold,
),
),
),
Text(
delivery['status'],
style:
const TextStyle(
fontSize: 12,
fontWeight:
FontWeight.bold,
color:
Color(0xFF32C787),
),
),
],
),

const SizedBox(height: 18),

_buildDetailRow(
Icons.storefront,
'Pharmacy',
delivery['pharmacy'],
),

_buildDetailRow(
Icons.person_outline,
'Customer',
delivery['customer'],
),

_buildDetailRow(
Icons
    .location_on_outlined,
'Drop-off',
delivery['dropoff'],
),

_buildDetailRow(
Icons.route_outlined,
'Distance',
delivery['distance'],
),

if (delivery['coldChain'])
_buildDetailRow(
Icons.ac_unit,
'Cold-chain',
'Keep between 2–8°C',
),

if (delivery['controlled'])
_buildDetailRow(
Icons
    .verified_user_outlined,
'Controlled drug',
'Signature required',
),

const SizedBox(height: 12),

SizedBox(
width: double.infinity,
height: 50,
child:
ElevatedButton.icon(
onPressed: () {
Navigator.pop(
context,
);

Navigator.of(
context,
).push(
MaterialPageRoute(
builder: (_) =>
RiderDeliveryDetailsScreen(
delivery:
Map<String,
dynamic>.from(
delivery,
),
),
),
);
},
style:
ElevatedButton.styleFrom(
backgroundColor:
const Color(
0xFF0F7253,
),
foregroundColor:
Colors.white,
elevation: 0,
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(
12,
),
),
),
icon: const Icon(
Icons
    .visibility_outlined,
),
label: const Text(
'View Delivery',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
),
),
],
),
),
);
},
);
}

// ================================================================
// DETAIL ROW
// ================================================================

Widget _buildDetailRow(
IconData icon,
String title,
String value,
) {
return Padding(
padding:
const EdgeInsets.only(
bottom: 14,
),
child: Row(
children: [
Container(
padding:
const EdgeInsets.all(8),
decoration:
BoxDecoration(
color:
const Color(0xFFE8F5E9),
borderRadius:
BorderRadius.circular(9),
),
child: Icon(
icon,
size: 17,
color:
const Color(0xFF0F7253),
),
),

const SizedBox(width: 10),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
title,
style:
const TextStyle(
fontSize: 10,
color:
Colors.grey,
),
),
const SizedBox(
height: 2,
),
Text(
value,
style:
const TextStyle(
fontSize: 13,
fontWeight:
FontWeight.w600,
),
),
],
),
),
],
),
);
}
}

