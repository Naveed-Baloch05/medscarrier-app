import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../bloc/admin_order/admin_order_bloc.dart';
import '../../bloc/admin_order/admin_order_event.dart';
import '../../bloc/admin_order/admin_order_state.dart';
import '../../bloc/admin_rider/admin_rider_bloc.dart';
import '../../bloc/admin_rider/admin_rider_event.dart';
import '../../bloc/admin_rider/admin_rider_state.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final AdminOrderBloc _orderBloc = AdminOrderBloc();
  final AdminRiderBloc _riderBloc = AdminRiderBloc();

  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filters = [
    'All',
    'Awaiting',
    'Active',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _orderBloc.add(const AdminOrderLoadRequested());
    _riderBloc.add(const AdminRiderLoadRequested());
  }

  @override
  void dispose() {
    _orderBloc.close();
    _riderBloc.close();
    super.dispose();
  }

  List<Map<String, dynamic>> _mapOrders(
    List<Map<String, dynamic>> rawOrders,
    List<Map<String, dynamic>> riders,
  ) {
    return rawOrders.map((order) {
      final String? riderId = order['riderId']?.toString();
      String? riderName;

      if (riderId != null && riderId.isNotEmpty) {
        for (final rider in riders) {
          if (rider['id']?.toString() == riderId) {
            riderName = rider['name']?.toString();
            break;
          }
        }
      }
      riderName ??= order['riderName']?.toString();

      final String status = order['status']?.toString() ?? '';
      String eta = order['estimatedTime']?.toString() ?? '';
      if (eta.isEmpty && status == 'Delivered') {
        eta = 'Completed';
      }

      return <String, dynamic>{
        'id': order['id']?.toString() ?? '',
        'pharmacy': order['pharmacyName']?.toString() ?? '',
        'customer': order['customerName']?.toString() ?? '',
        'pickup': order['pickupAddress']?.toString() ?? '',
        'dropoff': order['dropoffAddress']?.toString() ?? '',
        'status': status,
        'rider': (riderName != null && riderName.isNotEmpty) ? riderName : null,
        'distance': order['distance']?.toString() ?? '',
        'eta': eta,
        'controlled': order['controlledDrug'] == true,
        'coldChain': order['coldChain'] == true,
        'time': _relativeTime(order['createdAt']),
      };
    }).toList();
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _relativeTime(dynamic createdAt) {
    final DateTime? created = _parseDateTime(createdAt);
    if (created == null) return '';

    final difference = DateTime.now().difference(created);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) {
      return difference.inHours == 1
          ? '1 hr ago'
          : '${difference.inHours} hrs ago';
    }
    return difference.inDays == 1 ? '1 day ago' : '${difference.inDays} days ago';
  }

  List<Map<String, dynamic>> _filteredOrders(List<Map<String, dynamic>> orders) {
    List<Map<String, dynamic>> result = List.from(orders);

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
    return MultiBlocProvider(
      providers: [
        BlocProvider<AdminOrderBloc>.value(value: _orderBloc),
        BlocProvider<AdminRiderBloc>.value(value: _riderBloc),
      ],
      child: BlocBuilder<AdminOrderBloc, AdminOrderState>(
        buildWhen: (previous, current) => current is! AdminOrderOperationSuccess,
        builder: (context, orderState) {

          if (orderState is AdminOrderError) {
            final errorIsDark = Theme.of(context).brightness == Brightness.dark;
            final scaffoldBg =
                errorIsDark ? const Color(0xFF08100C) : const Color(0xFFF2F5F3);
            return Scaffold(
              backgroundColor: scaffoldBg,
              appBar: AppBar(
                backgroundColor: scaffoldBg,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
              body: Center(
                child: Text(
                  orderState.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        errorIsDark ? const Color(0xFF8B9B94) : Colors.grey,
                  ),
                ),
              ),
            );
          }

          return BlocBuilder<AdminRiderBloc, AdminRiderState>(
            buildWhen: (previous, current) =>
                current is! AdminRiderOperationSuccess,
            builder: (context, riderState) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;

              // Surface and scaffold colors explicitly defined for maximum clarity
              final scaffoldBg =
                  isDark ? const Color(0xFF08100C) : const Color(0xFFF2F5F3);
              final cardBg = isDark ? const Color(0xFF0E1A14) : Colors.white;
              final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);

              final riders = riderState is AdminRiderLoaded
                  ? riderState.riders
                  : const <Map<String, dynamic>>[];

              final allOrders = orderState is AdminOrderLoaded
                  ? _mapOrders(orderState.orders, riders)
                  : const <Map<String, dynamic>>[];

              final orders = _filteredOrders(allOrders);

              final awaitingCount = allOrders.where((order) {
                final status = order['status']?.toString() ?? '';
                return status == 'Awaiting Assignment' || status == 'Ready';
              }).length;

              final activeCount = allOrders.where((order) {
                final status = order['status']?.toString() ?? '';
                return status == 'Assigned' ||
                    status == 'Collecting' ||
                    status == 'Picked Up' ||
                    status == 'On the Way';
              }).length;

              final completedCount = allOrders.where((order) {
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
                      onPressed: () {
                        context.read<AdminOrderBloc>().add(const AdminOrderRefreshed());
                        context.read<AdminRiderBloc>().add(const AdminRiderRefreshed());
                      },
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
                          _summaryItem(context, '${allOrders.length}', 'Total', cardBg, isDark),
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
                              count = allOrders.length;
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
            },
          );
        },
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

    final riderState = context.read<AdminRiderBloc>().state;
    final riders = riderState is AdminRiderLoaded
        ? riderState.riders
        : const <Map<String, dynamic>>[];

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
                ...riders.map((rider) {
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
                                  ? (isDark ? const Color(0xFF1D322A) : const Color(0xFFE8F5E9))
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
                context.read<AdminOrderBloc>().add(
                  AdminOrderAssigned(
                    order['id'].toString(),
                    rider['id'].toString(),
                  ),
                );
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
    context.read<AdminOrderBloc>().add(
      AdminOrderAutoAssigned(order['id'].toString()),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Auto-assignment in progress.'),
        backgroundColor: primaryColor,
      ),
    );
  }
}
