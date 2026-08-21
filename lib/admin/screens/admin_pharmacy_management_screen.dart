import 'package:flutter/material.dart';

class AdminPharmacyManagementScreen extends StatefulWidget {
  const AdminPharmacyManagementScreen({
    super.key,
  });

  @override
  State<AdminPharmacyManagementScreen> createState() =>
      _AdminPharmacyManagementScreenState();
}

class _AdminPharmacyManagementScreenState
    extends State<AdminPharmacyManagementScreen> {
  // ============================================================
  // TEMPORARY DATA
  // Backend/API will replace this later.
  // ============================================================

  final List<Map<String, dynamic>> _pharmacies = [
    {
      'name': 'MedCare Pharmacy',
      'pharmacist': 'Naveed Baloch',
      'phone': '+92 300 1234567',
      'email': 'pharmacy@example.com',
      'address': 'Main Market, Lahore',
      'license': 'PH-2026-00125',
      'status': 'Approved',
      'active': true,
    },
    {
      'name': 'City Pharmacy',
      'pharmacist': 'Ahmed Khan',
      'phone': '+92 301 9876543',
      'email': 'city@example.com',
      'address': 'Gulberg, Lahore',
      'license': 'PH-2026-00126',
      'status': 'Pending',
      'active': false,
    },
    {
      'name': 'HealthCare Pharmacy',
      'pharmacist': 'Ali Raza',
      'phone': '+92 302 4567890',
      'email': 'healthcare@example.com',
      'address': 'Model Town, Lahore',
      'license': 'PH-2026-00127',
      'status': 'Approved',
      'active': true,
    },
  ];

  String _selectedFilter = 'All';

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filteredPharmacies = _filteredPharmacies();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        title: const Text(
          'Pharmacies',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================

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

            _buildSummary(),

            const SizedBox(height: 22),

            // ====================================================
            // SEARCH
            // ====================================================

            _buildSearchField(),

            const SizedBox(height: 14),

            // ====================================================
            // FILTERS
            // ====================================================

            _buildFilters(),

            const SizedBox(height: 18),

            // ====================================================
            // PHARMACY LIST
            // ====================================================

            if (filteredPharmacies.isEmpty)
              _buildEmptyState()
            else
              ...filteredPharmacies.map(
                    (pharmacy) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: _buildPharmacyCard(
                    pharmacy,
                  ),
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

  Widget _buildSummary() {
    final total = _pharmacies.length;

    final approved = _pharmacies
        .where(
          (pharmacy) =>
      pharmacy['status'] == 'Approved',
    )
        .length;

    final pending = _pharmacies
        .where(
          (pharmacy) =>
      pharmacy['status'] == 'Pending',
    )
        .length;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.local_pharmacy_outlined,
            title: 'Total',
            value: '$total',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _summaryCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'Approved',
            value: '$approved',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _summaryCard(
            icon: Icons.pending_outlined,
            title: 'Pending',
            value: '$pending',
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
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: Colors.grey.shade700,
          ),

          const SizedBox(height: 8),

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
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search pharmacy...',

        prefixIcon: const Icon(
          Icons.search_rounded,
        ),

        filled: true,
        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.black,
          ),
        ),
      ),

      onChanged: (value) {
        setState(() {});
      },
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      child: Row(
        children: [
          _filterButton('All'),
          const SizedBox(width: 8),
          _filterButton('Approved'),
          const SizedBox(width: 8),
          _filterButton('Pending'),
          const SizedBox(width: 8),
          _filterButton('Inactive'),
        ],
      ),
    );
  }

  Widget _filterButton(String filter) {
    final selected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),

        decoration: BoxDecoration(
          color: selected
              ? Colors.black
              : Colors.white,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: selected
                ? Colors.black
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
  }

  // ============================================================
  // PHARMACY CARD
  // ============================================================

  Widget _buildPharmacyCard(
      Map<String, dynamic> pharmacy,
      ) {
    final bool active =
        pharmacy['active'] == true;

    final String status =
    pharmacy['status'];

    return InkWell(
      onTap: () {
        _showPharmacyDetails(
          pharmacy,
        );
      },

      borderRadius: BorderRadius.circular(18),

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
          BorderRadius.circular(18),

          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // ----------------------------------------------------
            // NAME + STATUS
            // ----------------------------------------------------

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Container(
                  width: 44,
                  height: 44,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                    BorderRadius.circular(13),
                  ),

                  child: Icon(
                    Icons.local_pharmacy_outlined,
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
                        pharmacy['name'],
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        pharmacy['pharmacist'],
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                _statusBadge(status),
              ],
            ),

            const SizedBox(height: 14),

            // ----------------------------------------------------
            // DETAILS
            // ----------------------------------------------------

            _detailRow(
              Icons.phone_outlined,
              pharmacy['phone'],
            ),

            const SizedBox(height: 7),

            _detailRow(
              Icons.location_on_outlined,
              pharmacy['address'],
            ),

            const SizedBox(height: 7),

            _detailRow(
              Icons.badge_outlined,
              pharmacy['license'],
            ),

            const SizedBox(height: 14),

            Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------
            // ACTIVE + ACTION
            // ----------------------------------------------------

            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,

                        decoration: BoxDecoration(
                          color: active
                              ? Colors.green.shade600
                              : Colors.grey.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        active
                            ? 'Active'
                            : 'Inactive',

                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w600,
                          color: active
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                TextButton(
                  onPressed: () {
                    _showPharmacyActions(
                      pharmacy,
                    );
                  },

                  child: const Text(
                    'Manage',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
      IconData icon,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: Colors.grey.shade500,
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,

            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(String status) {
    final bool approved =
        status == 'Approved';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: approved
            ? Colors.green.shade50
            : Colors.orange.shade50,

        borderRadius:
        BorderRadius.circular(20),
      ),

      child: Text(
        status,

        style: TextStyle(
          fontSize: 10,
          fontWeight:
          FontWeight.w600,

          color: approved
              ? Colors.green.shade700
              : Colors.orange.shade700,
        ),
      ),
    );
  }

  // ============================================================
  // FILTER DATA
  // ============================================================

  List<Map<String, dynamic>> _filteredPharmacies() {
    if (_selectedFilter == 'All') {
      return _pharmacies;
    }

    if (_selectedFilter == 'Inactive') {
      return _pharmacies
          .where(
            (pharmacy) =>
        pharmacy['active'] == false,
      )
          .toList();
    }

    return _pharmacies
        .where(
          (pharmacy) =>
      pharmacy['status'] ==
          _selectedFilter,
    )
        .toList();
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(18),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        children: [
          Icon(
            Icons.local_pharmacy_outlined,
            size: 42,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 12),

          const Text(
            'No pharmacies found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'There are no pharmacies matching this filter.',
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

  // ============================================================
  // PHARMACY DETAILS
  // ============================================================

  void _showPharmacyDetails(
      Map<String, dynamic> pharmacy,
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
                        color: Colors.grey.shade300,
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,

                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius:
                          BorderRadius.circular(14),
                        ),

                        child: Icon(
                          Icons.local_pharmacy_outlined,
                          color:
                          Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacy['name'],
                              style:
                              const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              pharmacy['pharmacist'],
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  _bottomDetail(
                    'Phone',
                    pharmacy['phone'],
                  ),

                  _bottomDetail(
                    'Email',
                    pharmacy['email'],
                  ),

                  _bottomDetail(
                    'Address',
                    pharmacy['address'],
                  ),

                  _bottomDetail(
                    'License Number',
                    pharmacy['license'],
                  ),

                  _bottomDetail(
                    'Status',
                    pharmacy['status'],
                  ),

                  _bottomDetail(
                    'Account',
                    pharmacy['active']
                        ? 'Active'
                        : 'Inactive',
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 48,

                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);

                        _showPharmacyActions(
                          pharmacy,
                        );
                      },

                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,

                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(13),
                        ),
                      ),

                      child: const Text(
                        'Manage Pharmacy',
                        style: TextStyle(
                          fontWeight:
                          FontWeight.w700,
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
  // BOTTOM DETAIL
  // ============================================================

  Widget _bottomDetail(
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 15,
      ),

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

          const SizedBox(height: 3),

          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PHARMACY ACTIONS
  // ============================================================

  void _showPharmacyActions(
      Map<String, dynamic> pharmacy,
      ) {
    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (ctx) {
        final bool active =
            pharmacy['active'] == true;

        final bool pending =
            pharmacy['status'] == 'Pending';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24,
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

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

                Text(
                  pharmacy['name'],
                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 18),

                if (pending)
                  _actionTile(
                    icon: Icons.check_circle_outline,
                    title: 'Approve Pharmacy',
                    subtitle:
                    'Approve this pharmacy account',
                    iconColor:
                    Colors.green.shade600,
                    onTap: () {
                      Navigator.pop(ctx);

                      setState(() {
                        pharmacy['status'] =
                        'Approved';
                        pharmacy['active'] = true;
                      });

                      _showMessage(
                        'Pharmacy approved.',
                      );
                    },
                  ),

                _actionTile(
                  icon: active
                      ? Icons.block_outlined
                      : Icons.check_circle_outline,
                  title: active
                      ? 'Deactivate Pharmacy'
                      : 'Activate Pharmacy',
                  subtitle: active
                      ? 'Disable this pharmacy account'
                      : 'Enable this pharmacy account',
                  iconColor: active
                      ? Colors.red.shade600
                      : Colors.green.shade600,
                  onTap: () {
                    Navigator.pop(ctx);

                    setState(() {
                      pharmacy['active'] =
                      !active;
                    });

                    _showMessage(
                      active
                          ? 'Pharmacy deactivated.'
                          : 'Pharmacy activated.',
                    );
                  },
                ),

                _actionTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit Pharmacy',
                  subtitle:
                  'Update pharmacy information',
                  iconColor:
                  Colors.grey.shade700,
                  onTap: () {
                    Navigator.pop(ctx);

                    _showMessage(
                      'Edit pharmacy will be connected next.',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ACTION TILE
  // ============================================================

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,

      leading: Container(
        width: 42,
        height: 42,

        decoration: BoxDecoration(
          color: iconColor.withValues(
            alpha: 0.08,
          ),
          borderRadius:
          BorderRadius.circular(12),
        ),

        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),

      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade500,
        ),
      ),

      onTap: onTap,
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}