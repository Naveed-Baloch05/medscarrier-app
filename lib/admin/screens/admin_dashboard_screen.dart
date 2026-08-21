import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
  });

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
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

            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 14),

            _buildStatistics(),

            const SizedBox(height: 24),

            const Text(
              'Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 14),

            _buildManagementCard(
              icon: Icons.local_pharmacy_outlined,
              title: 'Pharmacies',
              subtitle: 'Manage registered pharmacies',
              onTap: () {
                // Pharmacy management will be connected next.
              },
            ),

            const SizedBox(height: 12),

            _buildManagementCard(
              icon: Icons.delivery_dining_outlined,
              title: 'Riders',
              subtitle: 'Manage riders and approvals',
              onTap: () {
                // Rider management will be connected next.
              },
            ),

            const SizedBox(height: 12),

            _buildManagementCard(
              icon: Icons.receipt_long_outlined,
              title: 'Orders',
              subtitle: 'Monitor orders and deliveries',
              onTap: () {
                // Order management will be connected next.
              },
            ),

            const SizedBox(height: 12),

            _buildManagementCard(
              icon: Icons.medication_outlined,
              title: 'Medicines',
              subtitle: 'Manage medicine information',
              onTap: () {
                // Medicine management will be connected next.
              },
            ),

            const SizedBox(height: 12),

            _buildManagementCard(
              icon: Icons.people_outline_rounded,
              title: 'Users',
              subtitle: 'Manage application users',
              onTap: () {
                // User management will be connected next.
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: OutlinedButton.icon(
                onPressed: () {
                  // Admin logout will be connected later.
                },

                icon: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade600,
                ),

                label: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,

                  side: BorderSide(
                    color: Colors.red.shade200,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics() {
    return Column(
      children: [

        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.local_pharmacy_outlined,
                title: 'Pharmacies',
                value: '0',
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _statCard(
                icon: Icons.delivery_dining_outlined,
                title: 'Riders',
                value: '0',
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.receipt_long_outlined,
                title: 'Orders',
                value: '0',
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _statCard(
                icon: Icons.check_circle_outline_rounded,
                title: 'Delivered',
                value: '0',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
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

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

          const SizedBox(height: 12),

          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MANAGEMENT CARD
  // ============================================================

  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(18),

      child: Container(
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
              width: 44,
              height: 44,

              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(13),
              ),

              child: Icon(
                icon,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}