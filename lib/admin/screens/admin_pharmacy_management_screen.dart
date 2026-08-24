import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/admin_pharmacy/admin_pharmacy_bloc.dart';
import '../../bloc/admin_pharmacy/admin_pharmacy_event.dart';
import '../../bloc/admin_pharmacy/admin_pharmacy_state.dart';
import '../../models/pharmacy_application_model.dart';

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
  late final AdminPharmacyBloc _pharmacyBloc;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _pharmacyBloc = AdminPharmacyBloc()..add(const AdminPharmacyLoadRequested());
  }

  @override
  void dispose() {
    _pharmacyBloc.close();
    super.dispose();
  }

  // ============================================================
  // COLORS
  // ============================================================

  Color _backgroundColor(bool isDark) {
    return isDark
        ? const Color(0xFF08100C)
        : const Color(0xFFF2F5F3);
  }

  Color _cardColor(bool isDark) {
    return isDark
        ? const Color(0xFF0E1A14)
        : Colors.white;
  }

  Color _primaryColor(bool isDark) {
    return isDark
        ? const Color(0xFF0F7253)
        : const Color(0xFF0F7253);
  }

  Color _primaryText(bool isDark) {
    return isDark
        ? Colors.white
        : const Color(0xFF191C1B);
  }

  Color _secondaryText(bool isDark) {
    return isDark
        ? const Color(0xFF8B9B94)
        : const Color(0xFF6E7A75);
  }

  Color _borderColor(bool isDark) {
    return isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.05);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return BlocProvider<AdminPharmacyBloc>.value(
      value: _pharmacyBloc,
      child: BlocBuilder<AdminPharmacyBloc, AdminPharmacyState>(
      builder: (context, state) {
        final List<Map<String, dynamic>> pharmacies;
        final List<PharmacyApplicationModel> pendingApplications;

        if (state is AdminPharmacyLoadedWithApplications) {
          pharmacies = _mapPharmacyData(state.pharmacies);
          pendingApplications = state.pendingApplications;
        } else if (state is AdminPharmacyLoaded) {
          pharmacies = _mapPharmacyData(state.pharmacies);
          pendingApplications = [];
        } else {
          pharmacies = <Map<String, dynamic>>[];
          pendingApplications = [];
        }

        final filteredPharmacies =
        _filteredPharmacies(pharmacies);

        return Scaffold(
      backgroundColor: _backgroundColor(isDark),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: _backgroundColor(isDark),
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        iconTheme: IconThemeData(
          color: _primaryText(isDark),
        ),

        title: Text(
          'Pharmacy Management',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: _primaryText(isDark),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: _primaryText(isDark)),
            onPressed: () => context
                .read<AdminPharmacyBloc>()
                .add(const AdminPharmacyRefreshed()),
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
            8,
            16,
            30,
          ),
          children: [
            // ====================================================
            // SUMMARY
            // ====================================================

            _buildSummary(pharmacies, isDark),

            const SizedBox(height: 22),

            // ====================================================
            // PENDING PHARMACY APPLICATIONS
            // ====================================================

            if (pendingApplications.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.how_to_reg_rounded,
                    size: 18,
                    color: Color(0xFFFF9800),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pending Applications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _primaryText(isDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800)
                          .withValues(alpha: 0.10),
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
                  child: _buildApplicationCard(app, isDark),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // ====================================================
            // SEARCH
            // ====================================================

            _buildSearchField(isDark),

            const SizedBox(height: 14),

            // ====================================================
            // FILTERS
            // ====================================================

            _buildFilters(isDark),

            const SizedBox(height: 18),

            // ====================================================
            // PHARMACY COUNT
            // ====================================================

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pharmacies',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _primaryText(isDark),
                  ),
                ),
                Text(
                  '${filteredPharmacies.length} found',
                  style: TextStyle(
                    fontSize: 11,
                    color: _secondaryText(isDark),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ====================================================
            // LIST
            // ====================================================

            if (filteredPharmacies.isEmpty)
              _buildEmptyState(isDark)
            else
              ...filteredPharmacies.map(
                    (pharmacy) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: _buildPharmacyCard(
                    pharmacy,
                    isDark,
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
  // MAP BLOC DATA
  // Maps backend keys to the keys used by the UI.
  // ============================================================

  List<Map<String, dynamic>> _mapPharmacyData(
      List<Map<String, dynamic>> pharmacies,
      ) {
    return pharmacies.map((pharmacy) {
      return <String, dynamic>{
        'id': pharmacy['id'],
        'name': pharmacy['pharmacyName'] ?? '',
        'pharmacist': pharmacy['contactName'] ?? '',
        'email': pharmacy['email'] ?? '',
        'phone': pharmacy['phone'] ?? '',
        'address': pharmacy['businessAddress'] ?? '',
        'license': pharmacy['gphcNumber'] ?? '',
        'status': pharmacy['status'] ?? 'Pending',
        'active': pharmacy['active'] == true,
      };
    }).toList();
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(
      List<Map<String, dynamic>> pharmacies,
      bool isDark,
      ) {
    final total = pharmacies.length;

    final approved = pharmacies
        .where(
          (pharmacy) =>
      pharmacy['status'] == 'Approved',
    )
        .length;

    final pending = pharmacies
        .where(
          (pharmacy) =>
      pharmacy['status'] == 'Pending',
    )
        .length;

    final active = pharmacies
        .where(
          (pharmacy) =>
      pharmacy['active'] == true,
    )
        .length;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            isDark: isDark,
            icon: Icons.local_pharmacy_outlined,
            title: 'Total',
            value: '$total',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            isDark: isDark,
            icon: Icons.check_circle_outline_rounded,
            title: 'Approved',
            value: '$approved',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            isDark: isDark,
            icon: Icons.pending_outlined,
            title: 'Pending',
            value: '$pending',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            isDark: isDark,
            icon: Icons.circle_outlined,
            title: 'Active',
            value: '$active',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _cardColor(isDark),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _borderColor(isDark),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: _primaryColor(isDark),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: _secondaryText(isDark),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _primaryText(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchField(bool isDark) {
    return TextField(
      style: TextStyle(
        color: _primaryText(isDark),
        fontSize: 13,
      ),

      cursorColor: _primaryColor(isDark),

      decoration: InputDecoration(
        hintText: 'Search pharmacy, pharmacist or license...',
        hintStyle: TextStyle(
          color: _secondaryText(isDark),
          fontSize: 12,
        ),

        prefixIcon: Icon(
          Icons.search_rounded,
          color: _secondaryText(isDark),
        ),

        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
          icon: Icon(
            Icons.close,
            color: _secondaryText(isDark),
          ),
          onPressed: () {
            setState(() {
              _searchQuery = '';
            });
          },
        )
            : null,

        filled: true,
        fillColor: _cardColor(isDark),

        contentPadding:
        const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _borderColor(isDark),
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _borderColor(isDark),
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _primaryColor(isDark),
            width: 1.2,
          ),
        ),
      ),

      onChanged: (value) {
        setState(() {
          _searchQuery =
              value.trim().toLowerCase();
        });
      },
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterButton('All', isDark),
          const SizedBox(width: 8),
          _filterButton('Approved', isDark),
          const SizedBox(width: 8),
          _filterButton('Pending', isDark),
          const SizedBox(width: 8),
          _filterButton('Rejected', isDark),
          const SizedBox(width: 8),
          _filterButton('Inactive', isDark),
        ],
      ),
    );
  }

  Widget _filterButton(
      String filter,
      bool isDark,
      ) {
    final selected =
        _selectedFilter == filter;

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
              ? _primaryColor(isDark)
              : _cardColor(isDark),
          borderRadius:
          BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _primaryColor(isDark)
                : _borderColor(isDark),
          ),
        ),
        child: Text(
          filter,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : _secondaryText(isDark),
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
      bool isDark,
      ) {
    final bool active =
        pharmacy['active'] == true;

    final String status =
    pharmacy['status'];

    return InkWell(
      onTap: () {
        _showPharmacyDetails(
          pharmacy,
          isDark,
        );
      },

      borderRadius:
      BorderRadius.circular(18),

      child: Container(
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: _cardColor(isDark),

          borderRadius:
          BorderRadius.circular(18),

          border: Border.all(
            color: _borderColor(isDark),
          ),

          boxShadow: isDark
              ? null
              : [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.025),
              blurRadius: 8,
              offset:
              const Offset(0, 3),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,

                  decoration:
                  BoxDecoration(
                    color: _primaryColor(
                      isDark,
                    ).withOpacity(0.12),
                    borderRadius:
                    BorderRadius.circular(
                      13,
                    ),
                  ),

                  child: Icon(
                    Icons
                        .local_pharmacy_outlined,
                    color:
                    _primaryColor(isDark),
                    size: 23,
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          _primaryText(
                            isDark,
                          ),
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        pharmacy['pharmacist'],
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                          _secondaryText(
                            isDark,
                          ),
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        pharmacy['id'],
                        style: TextStyle(
                          fontSize: 9,
                          color:
                          _secondaryText(
                            isDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _statusBadge(
                  status,
                  isDark,
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ==================================================
            // DETAILS
            // ==================================================

            _detailRow(
              Icons.phone_outlined,
              pharmacy['phone'],
              isDark,
            ),

            const SizedBox(height: 8),

            _detailRow(
              Icons.location_on_outlined,
              pharmacy['address'],
              isDark,
            ),

            const SizedBox(height: 8),

            _detailRow(
              Icons.badge_outlined,
              pharmacy['license'],
              isDark,
            ),

            const SizedBox(height: 14),

            Divider(
              height: 1,
              color: _borderColor(isDark),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // ACCOUNT STATUS + MANAGE
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration:
                        BoxDecoration(
                          color: active
                              ? const Color(
                            0xFF0F7253,
                          )
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        active
                            ? 'Account Active'
                            : 'Account Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                          FontWeight.w600,
                          color: active
                              ? _primaryColor(
                            isDark,
                          )
                              : _secondaryText(
                            isDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                TextButton(
                  onPressed: () {
                    _showPharmacyActions(
                      pharmacy,
                      isDark,
                    );
                  },

                  child: Text(
                    'Manage',
                    style: TextStyle(
                      color:
                      _primaryColor(
                        isDark,
                      ),
                      fontWeight:
                      FontWeight.w700,
                      fontSize: 12,
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
      bool isDark,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: _secondaryText(isDark),
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
              color:
              _secondaryText(isDark),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
      String status,
      bool isDark,
      ) {
    late Color background;
    late Color text;

    switch (status) {
      case 'Approved':
        background =
            const Color(0xFF0F7253)
                .withOpacity(0.12);
        text = _primaryColor(isDark);
        break;

      case 'Pending':
        background =
            const Color(0xFFFFB74D)
                .withOpacity(0.13);
        text = const Color(0xFFE68A00);
        break;

      case 'Rejected':
        background =
            const Color(0xFFE53935)
                .withOpacity(0.10);
        text = const Color(0xFFD32F2F);
        break;

      default:
        background =
            Colors.grey.withOpacity(0.1);
        text = Colors.grey;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: background,
        borderRadius:
        BorderRadius.circular(20),
      ),

      child: Text(
        status,
        style: TextStyle(
          fontSize: 9,
          fontWeight:
          FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  // ============================================================
  // FILTER DATA
  // ============================================================

  List<Map<String, dynamic>>
  _filteredPharmacies(
      List<Map<String, dynamic>> pharmacies,
      ) {
    Iterable<Map<String, dynamic>>
    result = pharmacies;

    // Status filter
    if (_selectedFilter == 'Inactive') {
      result = result.where(
            (pharmacy) =>
        pharmacy['active'] == false,
      );
    } else if (_selectedFilter != 'All') {
      result = result.where(
            (pharmacy) =>
        pharmacy['status'] ==
            _selectedFilter,
      );
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where(
            (pharmacy) {
          final name =
          pharmacy['name']
              .toString()
              .toLowerCase();

          final pharmacist =
          pharmacy['pharmacist']
              .toString()
              .toLowerCase();

          final license =
          pharmacy['license']
              .toString()
              .toLowerCase();

          final address =
          pharmacy['address']
              .toString()
              .toLowerCase();

          return name.contains(
            _searchQuery,
          ) ||
              pharmacist.contains(
                _searchQuery,
              ) ||
              license.contains(
                _searchQuery,
              ) ||
              address.contains(
                _searchQuery,
              );
        },
      );
    }

    return result.toList();
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(
      bool isDark,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(30),

      decoration: BoxDecoration(
        color: _cardColor(isDark),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: _borderColor(isDark),
        ),
      ),

      child: Column(
        children: [
          Icon(
            Icons
                .local_pharmacy_outlined,
            size: 42,
            color:
            _secondaryText(isDark),
          ),

          const SizedBox(height: 12),

          Text(
            'No pharmacies found',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
              FontWeight.w700,
              color:
              _primaryText(isDark),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'There are no pharmacies matching your search or filter.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color:
              _secondaryText(isDark),
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
      bool isDark,
      ) {
    showModalBottomSheet(
      context: context,

      backgroundColor:
      _cardColor(isDark),

      isScrollControlled: true,

      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.fromLTRB(
              22,
              20,
              22,
              28,
            ),

            child:
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration:
                      BoxDecoration(
                        color:
                        _secondaryText(
                          isDark,
                        ).withOpacity(
                          0.25,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration:
                        BoxDecoration(
                          color:
                          _primaryColor(
                            isDark,
                          ).withOpacity(
                            0.12,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: Icon(
                          Icons
                              .local_pharmacy_outlined,
                          color:
                          _primaryColor(
                            isDark,
                          ),
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
                              pharmacy['name'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.w700,
                                color:
                                _primaryText(
                                  isDark,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 3,
                            ),

                            Text(
                              pharmacy[
                              'pharmacist'],
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                _secondaryText(
                                  isDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  _bottomDetail(
                    'Pharmacy ID',
                    pharmacy['id'],
                    isDark,
                  ),

                  _bottomDetail(
                    'Pharmacist',
                    pharmacy['pharmacist'],
                    isDark,
                  ),

                  _bottomDetail(
                    'Phone',
                    pharmacy['phone'],
                    isDark,
                  ),

                  _bottomDetail(
                    'Email',
                    pharmacy['email'],
                    isDark,
                  ),

                  _bottomDetail(
                    'Address',
                    pharmacy['address'],
                    isDark,
                  ),

                  _bottomDetail(
                    'License Number',
                    pharmacy['license'],
                    isDark,
                  ),

                  _bottomDetail(
                    'Approval Status',
                    pharmacy['status'],
                    isDark,
                  ),

                  _bottomDetail(
                    'Account Status',
                    pharmacy['active']
                        ? 'Active'
                        : 'Inactive',
                    isDark,
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width:
                    double.infinity,
                    height: 48,
                    child:
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          ctx,
                        );

                        _showPharmacyActions(
                          pharmacy,
                          isDark,
                        );
                      },

                      style:
                      ElevatedButton
                          .styleFrom(
                        backgroundColor:
                        _primaryColor(
                          isDark,
                        ),
                        foregroundColor:
                        Colors.white,
                        elevation: 0,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            13,
                          ),
                        ),
                      ),

                      child:
                      const Text(
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
      bool isDark,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 14,
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color:
              _secondaryText(isDark),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w600,
              color:
              _primaryText(isDark),
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
      bool isDark,
      ) {
    showModalBottomSheet(
      context: context,

      backgroundColor:
      _cardColor(isDark),

      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (ctx) {
        final bool active =
            pharmacy['active'] == true;

        final bool pending =
            pharmacy['status'] ==
                'Pending';

        final bool rejected =
            pharmacy['status'] ==
                'Rejected';

        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.fromLTRB(
              22,
              20,
              22,
              24,
            ),

            child: Column(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration:
                    BoxDecoration(
                      color:
                      _secondaryText(
                        isDark,
                      ).withOpacity(
                        0.25,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  pharmacy['name'],
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    _primaryText(
                      isDark,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =================================================
                // APPROVE
                // =================================================

                if (pending || rejected)
                  _actionTile(
                    isDark: isDark,
                    icon: Icons
                        .check_circle_outline,
                    title:
                    pending
                        ? 'Approve Pharmacy'
                        : 'Re-approve Pharmacy',
                    subtitle:
                    'Approve this pharmacy account',
                    iconColor:
                    _primaryColor(
                      isDark,
                    ),
                    onTap: () {
                      Navigator.pop(
                        ctx,
                      );

                      context
                          .read<
                          AdminPharmacyBloc>()
                          .add(
                        AdminPharmacyApproved(
                          pharmacy['id'],
                        ),
                      );

                      _showMessage(
                        'Pharmacy approved.',
                      );
                    },
                  ),

                // =================================================
                // REJECT
                // =================================================

                if (pending)
                  _actionTile(
                    isDark: isDark,
                    icon: Icons
                        .cancel_outlined,
                    title:
                    'Reject Pharmacy',
                    subtitle:
                    'Reject this pharmacy application',
                    iconColor:
                    Colors.red.shade600,
                    onTap: () {
                      Navigator.pop(
                        ctx,
                      );

                      _showRejectConfirmation(
                        pharmacy,
                        isDark,
                      );
                    },
                  ),

                // =================================================
                // ACTIVATE / DEACTIVATE
                // =================================================

                if (!pending &&
                    !rejected)
                  _actionTile(
                    isDark: isDark,
                    icon: active
                        ? Icons
                        .block_outlined
                        : Icons
                        .check_circle_outline,
                    title: active
                        ? 'Deactivate Pharmacy'
                        : 'Activate Pharmacy',
                    subtitle: active
                        ? 'Disable this pharmacy account'
                        : 'Enable this pharmacy account',
                    iconColor: active
                        ? Colors.red.shade600
                        : _primaryColor(
                      isDark,
                    ),
                    onTap: () {
                      Navigator.pop(
                        ctx,
                      );

                      if (active) {
                        _showDeactivateConfirmation(
                          pharmacy,
                          isDark,
                        );
                      } else {
                        context
                            .read<
                            AdminPharmacyBloc>()
                            .add(
                          AdminPharmacyActivated(
                            pharmacy['id'],
                          ),
                        );

                        _showMessage(
                          'Pharmacy activated.',
                        );
                      }
                    },
                  ),

                // =================================================
                // EDIT
                // =================================================

                _actionTile(
                  isDark: isDark,
                  icon:
                  Icons.edit_outlined,
                  title:
                  'Edit Pharmacy',
                  subtitle:
                  'Update pharmacy information',
                  iconColor:
                  _secondaryText(
                    isDark,
                  ),
                  onTap: () {
                    Navigator.pop(
                      ctx,
                    );
                    _showEditPharmacySheet(pharmacy);
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
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
      EdgeInsets.zero,

      leading: Container(
        width: 42,
        height: 42,
        decoration:
        BoxDecoration(
          color: iconColor
              .withOpacity(0.09),
          borderRadius:
          BorderRadius.circular(
            12,
          ),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),

      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight:
          FontWeight.w600,
          color:
          _primaryText(isDark),
        ),
      ),

      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 10,
          color:
          _secondaryText(isDark),
        ),
      ),

      onTap: onTap,
    );
  }

  // ============================================================
  // DEACTIVATE CONFIRMATION
  // ============================================================

  void _showDeactivateConfirmation(
      Map<String, dynamic> pharmacy,
      bool isDark,
      ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor:
          _cardColor(isDark),

          title: Text(
            'Deactivate Pharmacy',
            style: TextStyle(
              fontWeight:
              FontWeight.w700,
              color:
              _primaryText(isDark),
            ),
          ),

          content: Text(
            'Are you sure you want to deactivate ${pharmacy['name']}?',
            style: TextStyle(
              color:
              _secondaryText(isDark),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                  _primaryText(
                    isDark,
                  ),
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                context
                    .read<
                    AdminPharmacyBloc>()
                    .add(
                  AdminPharmacyDeactivated(
                    pharmacy['id'],
                  ),
                );

                Navigator.pop(ctx);

                _showMessage(
                  'Pharmacy deactivated.',
                );
              },
              child: Text(
                'Deactivate',
                style: TextStyle(
                  color:
                  Colors.red.shade600,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // REJECT CONFIRMATION
  // ============================================================

  void _showRejectConfirmation(
      Map<String, dynamic> pharmacy,
      bool isDark,
      ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor:
          _cardColor(isDark),

          title: Text(
            'Reject Pharmacy',
            style: TextStyle(
              fontWeight:
              FontWeight.w700,
              color:
              _primaryText(isDark),
            ),
          ),

          content: Text(
            'Are you sure you want to reject ${pharmacy['name']}?',
            style: TextStyle(
              color:
              _secondaryText(isDark),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                  _primaryText(
                    isDark,
                  ),
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                context
                    .read<
                    AdminPharmacyBloc>()
                    .add(
                  AdminPharmacyRejected(
                    pharmacy['id'],
                  ),
                );

                Navigator.pop(ctx);

                _showMessage(
                  'Pharmacy rejected.',
                );
              },
              child: Text(
                'Reject',
                style: TextStyle(
                  color:
                  Colors.red.shade600,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
        SnackBarBehavior.floating,
        content:
        Text(message),
      ),
    );
  }

  // ============================================================
  // EDIT PHARMACY SHEET
  // ============================================================

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 19),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF111D17)
            : const Color(0xFFF5F7F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F7253)),
        ),
      ),
    );
  }

  void _showEditPharmacySheet(Map<String, dynamic> pharmacy) {
    final nameCtrl = TextEditingController(text: pharmacy['name']);
    final pharmacistCtrl = TextEditingController(text: pharmacy['pharmacist']);
    final phoneCtrl = TextEditingController(text: pharmacy['phone']);
    final emailCtrl = TextEditingController(text: pharmacy['email']);
    final addressCtrl = TextEditingController(text: pharmacy['address']);
    final licenseCtrl = TextEditingController(text: pharmacy['license']);

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor(Theme.of(context).brightness == Brightness.dark),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 15, 20, MediaQuery.of(ctx).viewInsets.bottom + 25),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                    'Edit Pharmacy',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: _primaryText(isDark),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _inputField(controller: nameCtrl, label: 'Pharmacy Name', hint: 'Enter pharmacy name', icon: Icons.store_outlined),
                  const SizedBox(height: 11),
                  _inputField(controller: pharmacistCtrl, label: 'Pharmacist', hint: 'Enter pharmacist name', icon: Icons.person_outline),
                  const SizedBox(height: 11),
                  _inputField(controller: phoneCtrl, label: 'Phone', hint: 'Enter phone number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 11),
                  _inputField(controller: emailCtrl, label: 'Email', hint: 'Enter email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 11),
                  _inputField(controller: addressCtrl, label: 'Address', hint: 'Enter address', icon: Icons.location_on_outlined),
                  const SizedBox(height: 11),
                  _inputField(controller: licenseCtrl, label: 'License', hint: 'Enter license number', icon: Icons.badge_outlined),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final pharmacist = pharmacistCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final email = emailCtrl.text.trim();
                        final address = addressCtrl.text.trim();
                        final license = licenseCtrl.text.trim();

                        if (name.isEmpty || pharmacist.isEmpty || phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Name, pharmacist, and phone are required.')),
                          );
                          return;
                        }

                        _pharmacyBloc.add(
                          AdminPharmacyUpdated(
                            pharmacy['id'],
                            {
                              'pharmacyName': name,
                              'contactName': pharmacist,
                              'phone': phone,
                              'email': email,
                              'businessAddress': address,
                              'gphcNumber': license,
                            },
                          ),
                        );

                        Navigator.pop(ctx);
                        _showMessage('$name updated successfully.');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor(isDark),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                      icon: const Icon(Icons.save_outlined, size: 19),
                      label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
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
  // APPLICATION CARD (pending pharmacy applications)
  // ============================================================

  Widget _buildApplicationCard(
    PharmacyApplicationModel app,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.3),
        ),
        boxShadow: isDark
            ? null
            : [
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
                  Icons.local_pharmacy_outlined,
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
                      app.pharmacyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _primaryText(isDark),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Applied ${_formatAppliedDate(app.submittedAt)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: _secondaryText(isDark),
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
          _detailRow(
            Icons.email_outlined,
            app.email,
            isDark,
          ),
          const SizedBox(height: 8),
          _detailRow(
            Icons.phone_outlined,
            app.phone,
            isDark,
          ),
          const SizedBox(height: 8),
          _detailRow(
            Icons.badge_outlined,
            app.gphcNumber,
            isDark,
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: _borderColor(isDark)),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _showApplicationDetails(app, isDark),
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: _secondaryText(isDark),
                  ),
                  label: Text(
                    'View Details',
                    style: TextStyle(
                      color: _secondaryText(isDark),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 22,
                color: _borderColor(isDark),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _showRejectApplicationDialog(app, isDark),
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
                color: _borderColor(isDark),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _approveApplication(app, isDark),
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

  void _approveApplication(PharmacyApplicationModel app, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _cardColor(isDark),
          title: Text(
            'Approve Application',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _primaryText(isDark),
            ),
          ),
          content: Text(
            'Approve ${app.pharmacyName}\'s pharmacy application? '
            'This will create their login account and send a password reset email.',
            style: TextStyle(color: _secondaryText(isDark)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: _primaryText(isDark)),
              ),
            ),
            TextButton(
              onPressed: () {
                _pharmacyBloc.add(
                  AdminPharmacyApplicationApprove(app.applicationId),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pharmacy application approved.'),
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

  void _showRejectApplicationDialog(
    PharmacyApplicationModel app,
    bool isDark,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _cardColor(isDark),
          title: Text(
            'Reject Application',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _primaryText(isDark),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reject ${app.pharmacyName}\'s pharmacy application?',
                style: TextStyle(color: _secondaryText(isDark)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Rejection reason (optional)',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: _secondaryText(isDark),
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
              child: Text(
                'Cancel',
                style: TextStyle(color: _primaryText(isDark)),
              ),
            ),
            TextButton(
              onPressed: () {
                _pharmacyBloc.add(
                  AdminPharmacyApplicationReject(
                    app.applicationId,
                    reasonController.text.trim(),
                  ),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pharmacy application rejected.'),
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

  void _showApplicationDetails(
    PharmacyApplicationModel app,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor(isDark),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _secondaryText(isDark).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.local_pharmacy_outlined,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.pharmacyName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _primaryText(isDark),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              app.contactName,
                              style: TextStyle(
                                fontSize: 11,
                                color: _secondaryText(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _bottomDetail('Application ID', app.applicationId, isDark),
                  _bottomDetail('Contact Name', app.contactName, isDark),
                  _bottomDetail('Phone', app.phone, isDark),
                  _bottomDetail('Email', app.email, isDark),
                  _bottomDetail('Address', app.businessAddress, isDark),
                  _bottomDetail('GPhC Number', app.gphcNumber, isDark),
                  if (app.licenseDocumentUrl != null &&
                      app.licenseDocumentUrl!.isNotEmpty)
                    _bottomDetail('License Document', app.licenseDocumentUrl!, isDark),
                  _bottomDetail(
                    'Submitted',
                    app.submittedAt != null
                        ? '${app.submittedAt!.day}/${app.submittedAt!.month}/${app.submittedAt!.year}'
                        : 'Unknown',
                    isDark,
                  ),
                  _bottomDetail('Status', app.status, isDark),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showRejectApplicationDialog(app, isDark);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(color: Colors.red.shade300),
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
                            _approveApplication(app, isDark);
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
}
