import 'package:flutter/material.dart';

import 'rider_delivery_details_screen.dart';

class RiderDeliveriesScreen extends StatefulWidget {
  const RiderDeliveriesScreen({
    super.key,
  });

  @override
  State<RiderDeliveriesScreen> createState() =>
      _RiderDeliveriesScreenState();
}

class _RiderDeliveriesScreenState
    extends State<RiderDeliveriesScreen> {
  // ============================================================
  // TEMPORARY DELIVERY DATA
  // Backend will be connected later.
  // ============================================================

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
    },
    {
      'orderId': 'ORD-1022',
      'pharmacy': 'Wellness Pharmacy',
      'customer': 'Customer Delivery',
      'address': 'DHA Phase 5, Lahore',
      'status': 'Delivered',
      'distance': '4.1 km',
      'eta': 'Completed',
      'controlledDrug': false,
      'coldChain': false,
    },
  ];

  // ============================================================
  // SELECTED FILTER
  // ============================================================

  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Assigned',
    'Picked Up',
    'On the Way',
    'Completed',
  ];

  // ============================================================
  // FILTERED DELIVERIES
  // ============================================================

  List<Map<String, dynamic>> get _filteredDeliveries {
    if (_selectedFilter == 'All') {
      return _deliveries;
    }

    if (_selectedFilter == 'Completed') {
      return _deliveries.where((delivery) {
        return delivery['status'] == 'Delivered';
      }).toList();
    }

    return _deliveries.where((delivery) {
      return delivery['status'] == _selectedFilter;
    }).toList();
  }

  // ============================================================
  // COUNTS
  // ============================================================

  int _countForFilter(String filter) {
    if (filter == 'All') {
      return _deliveries.length;
    }

    if (filter == 'Completed') {
      return _deliveries.where((delivery) {
        return delivery['status'] == 'Delivered';
      }).length;
    }

    return _deliveries.where((delivery) {
      return delivery['status'] == filter;
    }).length;
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

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Deliveries',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // ====================================================
            // STATUS FILTER TABS
            // ====================================================

            _buildFilterTabs(),

            const SizedBox(height: 8),

            // ====================================================
            // DELIVERY LIST
            // ====================================================

            Expanded(
              child: filteredDeliveries.isEmpty
                  ? _buildFilteredEmptyState()
                  : ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  30,
                ),
                children: [
                  _buildSummary(),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedFilter == 'All'
                            ? 'Your Deliveries'
                            : _selectedFilter ==
                            'Completed'
                            ? 'Completed Deliveries'
                            : '$_selectedFilter Deliveries',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      Text(
                        '${filteredDeliveries.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  ...filteredDeliveries.map(
                        (delivery) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: _buildDeliveryCard(
                        delivery,
                      ),
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

  // ============================================================
  // FILTER TABS
  // ============================================================

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          final count = _countForFilter(filter);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 180,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0F7253)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0F7253)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(width: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(
                        alpha: 0.18,
                      )
                          : Colors.grey.shade100,
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    final activeCount = _deliveries.where((delivery) {
      return delivery['status'] != 'Delivered';
    }).length;

    final completedCount = _deliveries.where((delivery) {
      return delivery['status'] == 'Delivered';
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
              crossAxisAlignment:
              CrossAxisAlignment.start,
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

  Widget _buildDeliveryCard(
      Map<String, dynamic> delivery,
      ) {
    final bool isControlledDrug =
        delivery['controlledDrug'] == true;

    final bool isColdChain =
        delivery['coldChain'] == true;

    final bool isCompleted =
        delivery['status'] == 'Delivered';

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
          crossAxisAlignment:
          CrossAxisAlignment.start,
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

                _statusBadge(
                  delivery['status'],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ----------------------------------------------------
            // PHARMACY
            // ----------------------------------------------------

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                    BorderRadius.circular(11),
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
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        delivery['address'],
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
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
                      icon:
                      Icons.warning_amber_rounded,
                      label: 'Controlled Drug',
                    ),

                  if (isColdChain)
                    _specialBadge(
                      icon: Icons.ac_unit_rounded,
                      label: 'Cold Chain 2–8°C',
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
                  foregroundColor: isCompleted
                      ? Colors.grey.shade700
                      : Colors.black,
                  side: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Text(
                      isCompleted
                          ? 'View Delivery'
                          : 'View Delivery Details',
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 6),

                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OPEN DELIVERY DETAILS
  // ============================================================

  void _openDelivery(
      Map<String, dynamic> delivery,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RiderDeliveryDetailsScreen(
              delivery: delivery,
            ),
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
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF0F7253);
        break;

      case 'Picked Up':
        backgroundColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        break;

      case 'On the Way':
        backgroundColor = const Color(0xFFEDE7F6);
        textColor = const Color(0xFF7C4DFF);
        break;

      case 'Delivered':
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
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
  // FILTERED EMPTY STATE
  // ============================================================

  Widget _buildFilteredEmptyState() {
    String title;
    String message;

    switch (_selectedFilter) {
      case 'Assigned':
        title = 'No Assigned Deliveries';
        message =
        'You currently have no deliveries assigned to you.';
        break;

      case 'Picked Up':
        title = 'No Picked Up Deliveries';
        message =
        'You currently have no picked up deliveries.';
        break;

      case 'On the Way':
        title = 'No Deliveries On the Way';
        message =
        'You currently have no deliveries on the way.';
        break;

      case 'Completed':
        title = 'No Completed Deliveries';
        message =
        'Your completed deliveries will appear here.';
        break;

      default:
        title = 'No Deliveries';
        message =
        'You currently have no assigned deliveries.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 34,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}