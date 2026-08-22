import 'package:flutter/material.dart';
import 'admin_orders_screen.dart';
import 'admin_rider_management_screen.dart';
import 'admin_pharmacy_management_screen.dart';
import 'admin_account_screen.dart';
import 'admin_rider_monitoring_screen.dart';
import 'admin_reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Design System Color Palette
    final bgColor =
    isDark ? const Color(0xFF08100C) : const Color(0xFFF2F5F3);

    final cardBgColor =
    isDark ? const Color(0xFF0E1A14) : Colors.white;

    final primaryColor =
    isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);

    final textPrimary =
    isDark ? Colors.white : const Color(0xFF191C1B);

    final textSecondary =
    isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);

    final chipBgColor =
    isDark ? const Color(0xFF14261E) : const Color(0xFFE8F5E9);

    final borderColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.04);

    return Scaffold(
      backgroundColor: bgColor,

      // ============================================================
      // HOME CONTENT
      // ============================================================

      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            // ======================================================
            // 1. TOP HEADER
            // ======================================================

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [

                    Container(
                      width: 40,
                      height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    ),

                    const SizedBox(width: 12),

                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Text(
                          'MedsCarrier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),

                        Row(
                          children: [

                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color:
                                primaryColor.withOpacity(0.2),
                                borderRadius:
                                BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ADMIN',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight:
                                  FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),

                            const SizedBox(width: 4),

                            Text(
                              'Operations',
                              style: TextStyle(
                                fontSize: 11,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    GestureDetector(
                      onTap: () => setState(() {}),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: cardBgColor,
                        child: Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    CircleAvatar(
                      radius: 18,
                      backgroundColor: cardBgColor,
                      child: Icon(
                        Icons.notifications_outlined,
                        size: 20,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ======================================================
            // 2. OVERVIEW HEADER
            // ======================================================

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [

                    Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius:
                        BorderRadius.circular(16),
                        border:
                        Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [

                          Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 12,
                              color: textPrimary,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),

                          const Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ======================================================
            // 3. OVERVIEW GRID
            // ======================================================

            SliverPadding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 16.0,
              ),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [

                  _buildMetricCard(
                    context,
                    icon:
                    Icons.local_shipping_outlined,
                    badgeText: '+12%',
                    value: '142',
                    label: 'Deliveries today',
                    isBadgeGreen: true,
                  ),

                  _buildMetricCard(
                    context,
                    icon: Icons.timer_outlined,
                    value: '34',
                    unit: 'min',
                    label: 'Avg delivery time',
                  ),

                  _buildMetricCard(
                    context,
                    icon: Icons.two_wheeler_outlined,
                    value: '8',
                    total: '/ 11',
                    label: 'Riders on the road',
                  ),

                  _buildMetricCard(
                    context,
                    icon: Icons.storefront_outlined,
                    value: '24',
                    label: 'Active pharmacies',
                  ),
                ],
              ),
            ),

            // ======================================================
            // 4. LIVE FLEET MAP
            // ======================================================

            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius:
                    BorderRadius.circular(16),
                    border:
                    Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [

                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [

                              Text(
                                'Live fleet',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                  FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),

                              Text(
                                '8 riders on the road · 12 active deliveries',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                  textSecondary,
                                ),
                              ),
                            ],
                          ),

                          Icon(
                            Icons.open_in_full,
                            size: 16,
                            color: textSecondary,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF060B08)
                              : const Color(0xFFE3ECE8),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [

                            Positioned(
                              top: 30,
                              left: 60,
                              child: _buildMapPin(
                                const Color(
                                  0xFF32C787,
                                ),
                              ),
                            ),

                            Positioned(
                              top: 40,
                              left: 110,
                              child: _buildMapPin(
                                const Color(
                                  0xFF7C4DFF,
                                ),
                              ),
                            ),

                            Positioned(
                              top: 25,
                              right: 70,
                              child: _buildMapPin(
                                const Color(
                                  0xFFFFB74D,
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: 25,
                              left: 140,
                              child: _buildMapPin(
                                const Color(
                                  0xFF32C787,
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: 15,
                              right: 100,
                              child: _buildMapPin(
                                const Color(
                                  0xFF32C787,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [

                          _buildLegendItem(
                            const Color(0xFF32C787),
                            'Idle rider',
                          ),

                          const SizedBox(width: 12),

                          _buildLegendItem(
                            const Color(0xFF7C4DFF),
                            'In transit',
                          ),

                          const SizedBox(width: 12),

                          _buildLegendItem(
                            const Color(0xFFFFB74D),
                            'CD delivery',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ======================================================
            // 5. PHARMACY APPROVALS
            // ======================================================

            _buildSectionHeader(
              'Pharmacy approvals',
              badgeText: '2 pending',
              badgeColor:
              const Color(0xFFFFB74D),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius:
                    BorderRadius.circular(16),
                    border:
                    Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [

                      Row(
                        children: [

                          Container(
                            padding:
                            const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: chipBgColor,
                              borderRadius:
                              BorderRadius.circular(
                                8,
                              ),
                            ),
                            child: Icon(
                              Icons.storefront,
                              color: primaryColor,
                              size: 20,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [

                                Text(
                                  'Wellgate Pharmacy',
                                  style: TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 14,
                                    color:
                                    textPrimary,
                                  ),
                                ),

                                Text(
                                  'GPhC • 2643117',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                    textSecondary,
                                  ),
                                ),

                                Text(
                                  'Islington, N1',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                    textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Text(
                            '18 min ago',
                            style: TextStyle(
                              fontSize: 10,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [

                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child:
                              ElevatedButton.icon(
                                style:
                                ElevatedButton.styleFrom(
                                  backgroundColor:
                                  primaryColor,
                                  elevation: 0,
                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      10,
                                    ),
                                  ),
                                ),
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Approve',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child:
                              OutlinedButton.icon(
                                style:
                                OutlinedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? const Color(
                                    0xFF181F1B,
                                  )
                                      : const Color(
                                    0xFFF5F7F6,
                                  ),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black12,
                                  ),
                                  shape:
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      10,
                                    ),
                                  ),
                                ),
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color:
                                  Colors.black87,
                                ),
                                label: const Text(
                                  'Reject',
                                  style: TextStyle(
                                    color:
                                    Colors.black87,
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 13,
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

            // ======================================================
            // SECOND PHARMACY
            // ======================================================

            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius:
                    BorderRadius.circular(12),
                    border:
                    Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [

                      Container(
                        padding:
                        const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: chipBgColor,
                          borderRadius:
                          BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.storefront,
                          color: primaryColor,
                          size: 18,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [

                            Text(
                              "St. Mary's Pharmacy",
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                fontSize: 13,
                                color: textPrimary,
                              ),
                            ),

                            Text(
                              'Hackney, E8',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        '1h ago',
                        style: TextStyle(
                          fontSize: 10,
                          color: textSecondary,
                        ),
                      ),

                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ======================================================
            // 6. AWAITING ASSIGNMENT
            // ======================================================

            _buildSectionHeader(
              'Awaiting assignment',
              badgeText: '3 orders',
              badgeColor:
              const Color(0xFF7C4DFF),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius:
                    BorderRadius.circular(16),
                    border:
                    Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [

                          Row(
                            children: [

                              Text(
                                '#MC-4822',
                                style: TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                  color: primaryColor,
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(width: 6),

                              _buildStatusTag(
                                'CD',
                                const Color(
                                  0xFFFFB74D,
                                ),
                              ),
                            ],
                          ),

                          _buildStatusTag(
                            'Ready',
                            primaryColor,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [

                          Icon(
                            Icons.storefront,
                            size: 14,
                            color: textSecondary,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            'Camden Pharmacy',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                              FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Icon(
                            Icons.arrow_forward,
                            size: 12,
                            color: textSecondary,
                          ),

                          const SizedBox(width: 8),

                          Text(
                            'Kentish Town, NW5',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                              textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [

                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 38,
                              child:
                              ElevatedButton.icon(
                                style:
                                ElevatedButton.styleFrom(
                                  backgroundColor:
                                  primaryColor,
                                  elevation: 0,
                                ),
                                onPressed: () {},
                                icon: const Icon(
                                  Icons
                                      .person_add_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Assign rider',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 38,
                              child: OutlinedButton(
                                style:
                                OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black12,
                                  ),
                                ),
                                onPressed: () {},
                                child: Text(
                                  'Auto-assign',
                                  style: TextStyle(
                                    color:
                                    textPrimary,
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight.bold,
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

            // ======================================================
            // 7. LIVE DELIVERIES
            // ======================================================

            _buildSectionHeader(
              'Live deliveries',
              actionText: 'View all',
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: Column(
                  children: [

                    _buildDeliveryItem(
                      context,
                      orderId: '#MC-4818',
                      riderName: 'Tom Reilly',
                      route:
                      'Camden Pharmacy → Primrose Hill, ...',
                      tags: [

                        _buildStatusTag(
                          'CD',
                          const Color(
                            0xFFFFB74D,
                          ),
                        ),

                        _buildStatusTag(
                          '2–8°C',
                          const Color(
                            0xFF4DD0E1,
                          ),
                        ),

                        _buildStatusTag(
                          'On the way',
                          const Color(
                            0xFF7C4DFF,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    _buildDeliveryItem(
                      context,
                      orderId: '#MC-4816',
                      riderName: 'Maya Aslam',
                      route:
                      'Riverside Pharmacy → Angel, N1',
                      tags: [

                        _buildStatusTag(
                          '2–8°C',
                          const Color(
                            0xFF4DD0E1,
                          ),
                        ),

                        _buildStatusTag(
                          'Collecting',
                          const Color(
                            0xFF7C4DFF,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tools',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildToolCard(
                            context,
                            icon: Icons.monitor_heart_outlined,
                            title: 'Rider Monitoring',
                            subtitle: 'Live locations & status',
                            primaryColor: primaryColor,
                            cardBgColor: cardBgColor,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminRiderMonitoringScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildToolCard(
                            context,
                            icon: Icons.bar_chart_outlined,
                            title: 'Reports',
                            subtitle: 'Stats & analytics',
                            primaryColor: primaryColor,
                            cardBgColor: cardBgColor,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminReportsScreen(),
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
          ],
        ),
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,

        // ========================================================
        // IMPORTANT NAVIGATION CHANGE
        // ========================================================

        onTap: (index) {

          // HOME
          if (index == 0) {
            setState(() {
              _selectedIndex = 0;
            });
            return;
          }

          // ORDERS
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                const AdminOrdersScreen(),
              ),
            );
            return;
          }

          // RIDERS
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                const AdminRiderManagementScreen(),
              ),
            );
            return;
          }

          // PHARMACY
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                const AdminPharmacyManagementScreen(),
              ),
            );
            return;
          }

          // ACCOUNT
          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                const AdminAccountScreen(),
              ),
            );
            return;
          }
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: primaryColor,

        unselectedItemColor: textSecondary,

        backgroundColor: cardBgColor,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.assignment_outlined,
            ),
            label: 'Orders',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.two_wheeler_outlined,
            ),
            label: 'Riders',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.storefront_outlined,
            ),
            label: 'Pharmacy',
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline,
            ),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // METRIC CARD
  // ============================================================

  Widget _buildMetricCard(
      BuildContext context, {
        required IconData icon,
        String? badgeText,
        bool isBadgeGreen = false,
        required String value,
        String? unit,
        String? total,
        required String label,
      }) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final cardBgColor =
    isDark
        ? const Color(0xFF0E1A14)
        : Colors.white;

    final textPrimary =
    isDark
        ? Colors.white
        : const Color(0xFF191C1B);

    final textSecondary =
    isDark
        ? const Color(0xFF8B9B94)
        : const Color(0xFF6E7A75);

    final primaryColor =
    isDark
        ? const Color(0xFF32C787)
        : const Color(0xFF0F7253);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
        children: [

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [

              Container(
                padding:
                const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                  primaryColor.withOpacity(
                    0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 16,
                ),
              ),

              if (badgeText != null)
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isBadgeGreen
                        ? primaryColor
                        .withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [

                      Icon(
                        Icons.trending_up,
                        size: 10,
                        color: primaryColor,
                      ),

                      const SizedBox(width: 2),

                      Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                          FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
                color: textPrimary,
              ),
              children: [

                if (unit != null)
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                      textSecondary,
                    ),
                  ),

                if (total != null)
                  TextSpan(
                    text: ' $total',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                      textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(
      String title, {
        String? badgeText,
        Color? badgeColor,
        String? actionText,
      }) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final textPrimary =
    isDark
        ? Colors.white
        : const Color(0xFF191C1B);

    final primaryColor =
    isDark
        ? const Color(0xFF32C787)
        : const Color(0xFF0F7253);

    return SliverToBoxAdapter(
      child: Padding(
        padding:
        const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          4,
        ),
        child: Row(
          children: [

            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight.bold,
                color: textPrimary,
              ),
            ),

            if (badgeText != null) ...[

              const SizedBox(width: 8),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color:
                  (badgeColor ??
                      primaryColor)
                      .withOpacity(0.15),
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    badgeColor ??
                        primaryColor,
                  ),
                ),
              ),
            ],

            const Spacer(),

            if (actionText != null)
              Text(
                actionText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  FontWeight.bold,
                  color: primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DELIVERY ITEM
  // ============================================================

  Widget _buildDeliveryItem(
      BuildContext context, {
        required String orderId,
        required String riderName,
        required String route,
        required List<Widget> tags,
      }) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final cardBgColor =
    isDark
        ? const Color(0xFF0E1A14)
        : Colors.white;

    final textPrimary =
    isDark
        ? Colors.white
        : const Color(0xFF191C1B);

    final textSecondary =
    isDark
        ? const Color(0xFF8B9B94)
        : const Color(0xFF6E7A75);

    final primaryColor =
    isDark
        ? const Color(0xFF32C787)
        : const Color(0xFF0F7253);

    return Container(
      padding:
      const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        children: [

          Row(
            children: [

              Text(
                orderId,
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                  color: primaryColor,
                  fontSize: 13,
                ),
              ),

              const Spacer(),

              Wrap(
                spacing: 4,
                children: tags,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [

              CircleAvatar(
                radius: 12,
                backgroundColor:
                primaryColor
                    .withOpacity(0.2),
                child: Text(
                  riderName
                      .substring(0, 2)
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: primaryColor,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [

                    Text(
                      riderName,
                      style: TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        fontSize: 12,
                        color:
                        textPrimary,
                      ),
                    ),

                    Text(
                      route,
                      style: TextStyle(
                        fontSize: 10,
                        color:
                        textSecondary,
                      ),
                      overflow:
                      TextOverflow
                          .ellipsis,
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                size: 18,
                color: textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS TAG
  // ============================================================

  Widget _buildStatusTag(
      String label,
      Color color,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color:
        color.withOpacity(0.12),
        borderRadius:
        BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight:
          FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // MAP PIN
  // ============================================================

  Widget _buildMapPin(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
    );
  }

  // ============================================================
  // MAP LEGEND
  // ============================================================

  Widget _buildLegendItem(
      Color color,
      String label,
      ) {
    return Row(
      children: [

        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 4),

        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required Color cardBgColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}