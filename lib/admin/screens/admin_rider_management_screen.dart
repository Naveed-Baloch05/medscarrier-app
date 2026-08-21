import 'package:flutter/material.dart';

class AdminRiderManagementScreen extends StatefulWidget {
  const AdminRiderManagementScreen({
    super.key,
  });

  @override
  State<AdminRiderManagementScreen> createState() =>
      _AdminRiderManagementScreenState();
}

class _AdminRiderManagementScreenState
    extends State<AdminRiderManagementScreen> {
  // ============================================================
  // TEMPORARY RIDER DATA
  // Backend/API will be connected later.
  // ============================================================

  final List<Map<String, dynamic>> _riders = [
    {
      'id': 'RID-1001',
      'name': 'Naveed Baloch',
      'phone': '+92 300 1234567',
      'email': 'naveed@example.com',
      'status': 'Active',
      'online': true,
      'deliveries': 24,
    },
    {
      'id': 'RID-1002',
      'name': 'Ali Ahmed',
      'phone': '+92 301 7654321',
      'email': 'ali@example.com',
      'status': 'Active',
      'online': false,
      'deliveries': 18,
    },
    {
      'id': 'RID-1003',
      'name': 'Usman Khan',
      'phone': '+92 302 9876543',
      'email': 'usman@example.com',
      'status': 'Inactive',
      'online': false,
      'deliveries': 9,
    },
  ];

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final activeRiders = _riders
        .where((rider) => rider['status'] == 'Active')
        .length;

    final onlineRiders = _riders
        .where((rider) => rider['online'] == true)
        .length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        title: const Text(
          'Rider Management',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          children: [
            // ====================================================
            // SUMMARY
            // ====================================================

            _buildSummary(
              total: _riders.length,
              active: activeRiders,
              online: onlineRiders,
            ),

            const SizedBox(height: 24),

            // ====================================================
            // RIDERS TITLE
            // ====================================================

            const Text(
              'Riders',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            // ====================================================
            // RIDER LIST
            // ====================================================

            ..._riders.map(
                  (rider) => Padding(
                padding: const EdgeInsets.only(
                  bottom: 12,
                ),
                child: _buildRiderCard(rider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary({
    required int total,
    required int active,
    required int online,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.people_outline_rounded,
            title: 'Total',
            value: '$total',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _summaryCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'Active',
            value: '$active',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _summaryCard(
            icon: Icons.circle,
            title: 'Online',
            value: '$online',
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
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade700,
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: TextStyle(
              fontSize: 10,
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
    );
  }

  // ============================================================
  // RIDER CARD
  // ============================================================

  Widget _buildRiderCard(
      Map<String, dynamic> rider,
      ) {
    final bool isActive =
        rider['status'] == 'Active';

    final bool isOnline =
        rider['online'] == true;

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
          // ======================================================
          // HEADER
          // ======================================================

          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  Icons.person_outline_rounded,
                  size: 25,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider['name'],
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      rider['id'],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              _statusBadge(
                label: rider['status'],
                active: isActive,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ======================================================
          // PHONE
          // ======================================================

          _detailRow(
            icon: Icons.phone_outlined,
            value: rider['phone'],
          ),

          const SizedBox(height: 9),

          // ======================================================
          // EMAIL
          // ======================================================

          _detailRow(
            icon: Icons.email_outlined,
            value: rider['email'],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // ONLINE + DELIVERIES
          // ======================================================

          Row(
            children: [
              _onlineBadge(isOnline),

              const Spacer(),

              Icon(
                Icons.local_shipping_outlined,
                size: 16,
                color: Colors.grey.shade500,
              ),

              const SizedBox(width: 5),

              Text(
                '${rider['deliveries']} deliveries',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),

          const SizedBox(height: 8),

          // ======================================================
          // ACTIONS
          // ======================================================

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    _showRiderDetails(rider);
                  },
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              Container(
                width: 1,
                height: 22,
                color: Colors.grey.shade200,
              ),

              Expanded(
                child: TextButton(
                  onPressed: () {
                    _toggleRiderStatus(rider);
                  },
                  child: Text(
                    isActive
                        ? 'Deactivate'
                        : 'Activate',
                    style: TextStyle(
                      color: isActive
                          ? Colors.red.shade600
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w600,
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
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: Colors.grey.shade500,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
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
          fontSize: 10,
          fontWeight: FontWeight.w600,
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

  Widget _onlineBadge(bool online) {
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
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: online
                  ? Colors.green.shade700
                  : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
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
      setState(() {
        rider['status'] = 'Active';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Rider activated.',
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
                  color: Colors.black,
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                setState(() {
                  rider['status'] = 'Inactive';
                  rider['online'] = false;
                });

                Navigator.pop(ctx);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Rider deactivated.',
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
  // RIDER DETAILS
  // ============================================================

  void _showRiderDetails(
      Map<String, dynamic> rider,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
              24,
              24,
              24,
              30,
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
                      color: Colors.grey.shade300,
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Rider Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 20),

                _detailItem(
                  'Rider ID',
                  rider['id'],
                ),

                _detailItem(
                  'Name',
                  rider['name'],
                ),

                _detailItem(
                  'Phone',
                  rider['phone'],
                ),

                _detailItem(
                  'Email',
                  rider['email'],
                ),

                _detailItem(
                  'Account Status',
                  rider['status'],
                ),

                _detailItem(
                  'Current Status',
                  rider['online']
                      ? 'Online'
                      : 'Offline',
                ),

                _detailItem(
                  'Completed Deliveries',
                  '${rider['deliveries']}',
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
        bottom: 15,
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}