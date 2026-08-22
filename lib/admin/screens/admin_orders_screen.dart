import 'package:flutter/material.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final List<Map<String, dynamic>> _orders = [
    {
      'id': '#MC-4822',
      'pharmacy': 'Camden Pharmacy',
      'customer': 'James Wilson',
      'pickup': 'Camden High St, NW1',
      'dropoff': 'Kentish Town, NW5',
      'status': 'Awaiting Assignment',
      'rider': null,
      'distance': '2.8 km',
      'eta': '10 min',
      'controlled': true,
      'coldChain': false,
      'time': '8 min ago',
    },
    {
      'id': '#MC-4818',
      'pharmacy': 'Camden Pharmacy',
      'customer': 'Alessia Rossi',
      'pickup': 'Camden High St, NW1',
      'dropoff': 'Primrose Hill, NW3',
      'status': 'On the Way',
      'rider': 'Tom Reilly',
      'distance': '3.2 km',
      'eta': '12 min',
      'controlled': true,
      'coldChain': true,
      'time': '18 min ago',
    },
    {
      'id': '#MC-4816',
      'pharmacy': 'Riverside Pharmacy',
      'customer': 'Maya Aslam',
      'pickup': 'Riverside Road, NW1',
      'dropoff': 'Angel, N1',
      'status': 'Collecting',
      'rider': 'Maya Aslam',
      'distance': '4.1 km',
      'eta': '15 min',
      'controlled': false,
      'coldChain': true,
      'time': '32 min ago',
    },
    {
      'id': '#MC-4820',
      'pharmacy': 'Camden Pharmacy',
      'customer': 'James Wilson',
      'pickup': 'Camden High St, NW1',
      'dropoff': 'Kentish Town, NW5',
      'status': 'Ready',
      'rider': null,
      'distance': '0.8 km',
      'eta': '5 min',
      'controlled': false,
      'coldChain': true,
      'time': '42 min ago',
    },
    {
      'id': '#MC-4815',
      'pharmacy': 'Central Pharmacy',
      'customer': 'Oliver Smith',
      'pickup': 'High Street, NW1',
      'dropoff': 'Belsize Park, NW3',
      'status': 'Delivered',
      'rider': 'Tom Reilly',
      'distance': '4.6 km',
      'eta': 'Completed',
      'controlled': true,
      'coldChain': false,
      'time': '1 hr ago',
    },
    {
      'id': '#MC-4812',
      'pharmacy': 'Wellgate Pharmacy',
      'customer': 'Sophie Taylor',
      'pickup': 'Islington Road, N1',
      'dropoff': 'Hackney, E8',
      'status': 'Delivered',
      'rider': 'Maya Aslam',
      'distance': '5.2 km',
      'eta': 'Completed',
      'controlled': false,
      'coldChain': false,
      'time': '2 hrs ago',
    },
  ];

  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _availableRiders = [
    {'id': 'RID-1001', 'name': 'Tom Reilly', 'online': true, 'deliveries': 24, 'location': 'Camden High St'},
    {'id': 'RID-1002', 'name': 'Maya Aslam', 'online': true, 'deliveries': 18, 'location': 'Islington Road'},
    {'id': 'RID-1003', 'name': 'Ali Khan', 'online': false, 'deliveries': 9, 'location': 'Hackney'},
  ];

  final List<String> _filters = [
    'All',
    'Awaiting',
    'Active',
    'Completed',
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    List<Map<String, dynamic>> result = List.from(_orders);

    if (_selectedFilter == 'Awaiting') {
      result = result.where((order) {
        final status = order['status']?.toString() ?? '';
        return status == 'Awaiting Assignment' || status == 'Ready';
      }).toList();
    }

    if (_selectedFilter == 'Active') {
      result = result.where((order) {
        final status = order['status']?.toString() ?? '';
        return status == 'Assigned' ||
            status == 'Collecting' ||
            status == 'Picked Up' ||
            status == 'On the Way';
      }).toList();
    }

    if (_selectedFilter == 'Completed') {
      result = result.where((order) {
        return order['status']?.toString() == 'Delivered';
      }).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      result = result.where((order) {
        final id = order['id']?.toString().toLowerCase() ?? '';
        final pharmacy = order['pharmacy']?.toString().toLowerCase() ?? '';
        final customer = order['customer']?.toString().toLowerCase() ?? '';
        final rider = order['rider']?.toString().toLowerCase() ?? '';

        return id.contains(query) ||
            pharmacy.contains(query) ||
            customer.contains(query) ||
            rider.contains(query);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Surface and scaffold colors explicitly defined for maximum clarity
    final scaffoldBg = isDark ? const Color(0xFF08100C) : const Color(0xFFF2F5F3);
    final cardBg = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);

    final orders = _filteredOrders;

    final awaitingCount = _orders.where((order) {
      final status = order['status']?.toString() ?? '';
      return status == 'Awaiting Assignment' || status == 'Ready';
    }).length;

    final activeCount = _orders.where((order) {
      final status = order['status']?.toString() ?? '';
      return status == 'Assigned' ||
          status == 'Collecting' ||
          status == 'Picked Up' ||
          status == 'On the Way';
    }).length;

    final completedCount = _orders.where((order) {
      return order['status']?.toString() == 'Delivered';
    }).length;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Orders',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textPrimary),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // SUMMARY
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                _summaryItem(context, '${_orders.length}', 'Total', cardBg, isDark),
                const SizedBox(width: 8),
                _summaryItem(context, '$awaitingCount', 'Awaiting', cardBg, isDark),
                const SizedBox(width: 8),
                _summaryItem(context, '$activeCount', 'Active', cardBg, isDark),
                const SizedBox(width: 8),
                _summaryItem(context, '$completedCount', 'Done', cardBg, isDark),
              ],
            ),
          ),

          // SEARCH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: TextStyle(color: textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search order, pharmacy, rider...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF8B9B94) : Colors.grey.shade600,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: isDark ? const Color(0xFF8B9B94) : Colors.grey.shade600,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                )
                    : null,
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // FILTERS
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                int count;

                switch (filter) {
                  case 'Awaiting':
                    count = awaitingCount;
                    break;
                  case 'Active':
                    count = activeCount;
                    break;
                  case 'Completed':
                    count = completedCount;
                    break;
                  default:
                    count = _orders.length;
                }

                return _filterChip(context, filter, count, cardBg, isDark);
              },
            ),
          ),

          const SizedBox(height: 10),

          // ORDER LIST
          Expanded(
            child: orders.isEmpty
                ? Center(
              child: Text(
                'No orders found',
                style: TextStyle(
                  color: isDark ? const Color(0xFF8B9B94) : Colors.grey,
                ),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _buildOrderCard(context, orders[index], cardBg, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  // SUMMARY ITEM
  Widget _summaryItem(
      BuildContext context,
      String value,
      String title,
      Color cardBg,
      bool isDark,
      ) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FILTER CHIP
  Widget _filterChip(
      BuildContext context,
      String title,
      int count,
      Color cardBg,
      bool isDark,
      ) {
    final selected = _selectedFilter == title;
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF133327) : const Color(0xFFDCEFE6))
              : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? primaryColor
                : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
          ),
          boxShadow: [
            if (!isDark && !selected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected
                    ? primaryColor
                    : (isDark ? const Color(0xFF8B9B94) : const Color(0xFF191C1B)),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? primaryColor
                    : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ORDER CARD
  Widget _buildOrderCard(
      BuildContext context,
      Map<String, dynamic> order,
      Color cardBg,
      bool isDark,
      ) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);

    final String status = order['status']?.toString() ?? '';
    final bool isCompleted = status == 'Delivered';
    final bool awaiting = status == 'Awaiting Assignment' || status == 'Ready';

    final Color statusColor = _statusColor(status, isDark);

    final String orderId = order['id']?.toString() ?? '';
    final String pharmacy = order['pharmacy']?.toString() ?? '';
    final String pickup = order['pickup']?.toString() ?? '';
    final String customer = order['customer']?.toString() ?? '';
    final String dropoff = order['dropoff']?.toString() ?? '';
    final String distance = order['distance']?.toString() ?? '';
    final String eta = order['eta']?.toString() ?? '';
    final String? rider = order['rider']?.toString();
    final bool coldChain = order['coldChain'] == true;
    final bool controlled = order['controlled'] == true;
    final String time = order['time']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ORDER HEADER
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF12241C) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_outline : Icons.receipt_long_outlined,
                  size: 20,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderId,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pharmacy,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(status, statusColor),
            ],
          ),

          const SizedBox(height: 14),

          // PICKUP
          _locationRow(
            context,
            icon: Icons.storefront,
            label: 'PICKUP',
            value: pickup,
            color: primaryColor,
            isDark: isDark,
          ),

          Padding(
            padding: const EdgeInsets.only(left: 13, top: 2, bottom: 2),
            child: Container(
              width: 2,
              height: 9,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
          ),

          // DROP OFF
          _locationRow(
            context,
            icon: Icons.location_on_outlined,
            label: 'DROP-OFF',
            value: '$customer • $dropoff',
            color: textSecondary,
            isDark: isDark,
          ),

          const SizedBox(height: 12),

          // INFORMATION
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _infoChip(Icons.route_outlined, distance, isDark),
              _infoChip(Icons.access_time_outlined, eta, isDark),
              if (coldChain)
                _infoChip(
                  Icons.ac_unit,
                  '2–8°C',
                  isDark,
                  color: const Color(0xFF4DD0E1),
                ),
              if (controlled)
                _infoChip(
                  Icons.verified_user_outlined,
                  'CD',
                  isDark,
                  color: const Color(0xFFFFB74D),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // RIDER
          if (rider != null && rider.isNotEmpty)
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: textSecondary),
                const SizedBox(width: 5),
                Text('Rider:', style: TextStyle(fontSize: 11, color: textSecondary)),
                const SizedBox(width: 4),
                Text(
                  rider,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ],
            )
          else
            const Row(
              children: [
                Icon(Icons.person_off_outlined, size: 16, color: Colors.orange),
                SizedBox(width: 5),
                Text(
                  'No rider assigned',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // ACTIONS
          if (awaiting)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAssignRiderSheet(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      ),
                      icon: const Icon(Icons.person_add_alt_1, size: 17),
                      label: const Text('Assign Rider', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                SizedBox(
                  height: 42,
                    child: OutlinedButton(
                      onPressed: () => _autoAssignRider(order),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                      ),
                      child: const Text('Auto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('View Order Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_forward, size: 15),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 7),

          Text(
            time,
            style: TextStyle(fontSize: 10, color: textSecondary),
          ),
        ],
      ),
    );
  }

  // LOCATION ROW
  Widget _locationRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        required Color color,
        required bool isDark,
      }) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18251F) : const Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STATUS BADGE
  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // INFO CHIP
  Widget _infoChip(IconData icon, String label, bool isDark, {Color? color}) {
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final chipColor = color ?? textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: chipColor),
          ),
        ],
      ),
    );
  }

  // STATUS COLOR SWITCHER
  Color _statusColor(String status, bool isDark) {
    switch (status) {
      case 'Awaiting Assignment':
      case 'Ready':
        return const Color(0xFFFFB74D);
      case 'On the Way':
      case 'Collecting':
      case 'Picked Up':
      case 'Assigned':
        return const Color(0xFF7C4DFF);
      case 'Delivered':
        return isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // ASSIGN RIDER SHEET
  // ============================================================

  void _showAssignRiderSheet(Map<String, dynamic> order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);
    final cardBg = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Assign Rider to ${order['id']}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 5),
                Text(
                  '${order['pharmacy']} → ${order['dropoff']}',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 18),
                ..._availableRiders.map((rider) {
                  final online = rider['online'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: online
                              ? (isDark ? const Color(0xFF18251F) : const Color(0xFFE8F5E9))
                              : Colors.grey.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: online ? primaryColor : textSecondary,
                          size: 22,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            rider['name'],
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: online
                                  ? (isDark ? const Color(0xFF15301D) : const Color(0xFFE8F5E9))
                                  : Colors.grey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              online ? 'Online' : 'Offline',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: online ? primaryColor : textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${rider['deliveries']} deliveries · ${rider['location']}',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: online ? primaryColor : textSecondary,
                      ),
                      onTap: online ? () {
                        Navigator.pop(ctx);
                        _confirmAssign(order, rider);
                      } : null,
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmAssign(Map<String, dynamic> order, Map<String, dynamic> rider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A14) : Colors.white,
          title: Text('Confirm Assignment', style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
          content: Text(
            'Assign ${order['id']} to ${rider['name']}?',
            style: TextStyle(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: textSecondary)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  order['rider'] = rider['name'];
                  order['status'] = 'Assigned';
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Assigned to ${rider['name']}'),
                    backgroundColor: primaryColor,
                  ),
                );
              },
              child: Text('Assign', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _autoAssignRider(Map<String, dynamic> order) {
    final onlineRiders = _availableRiders.where((r) => r['online'] == true).toList();

    if (onlineRiders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No riders available online.')),
      );
      return;
    }

    final bestRider = onlineRiders.reduce((a, b) =>
        (a['deliveries'] as int) <= (b['deliveries'] as int) ? a : b);

    setState(() {
      order['rider'] = bestRider['name'];
      order['status'] = 'Assigned';
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Auto-assigned to ${bestRider['name']}'),
        backgroundColor: primaryColor,
      ),
    );
  }
}