import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/admin_dashboard/admin_dashboard_bloc.dart';
import '../../bloc/admin_dashboard/admin_dashboard_event.dart';
import '../../bloc/admin_dashboard/admin_dashboard_state.dart';
import '../../bloc/admin_notification/admin_notification_bloc.dart';
import '../../bloc/admin_notification/admin_notification_event.dart';
import '../../bloc/admin_notification/admin_notification_state.dart';
import '../../models/pharmacy_model.dart';
import '../../models/rider_application_model.dart';
import '../../widgets/document_preview_dialog.dart';
import 'admin_notifications_screen.dart';
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
  late final AdminDashboardBloc _dashboardBloc;
  late final AdminNotificationBloc _notificationBloc;

  @override
  void initState() {
    super.initState();
    _dashboardBloc = AdminDashboardBloc()
      ..add(const AdminDashboardLoadRequested());
    _notificationBloc = AdminNotificationBloc()
      ..add(const AdminNotificationLoadRequested());
  }

  @override
  void dispose() {
    _dashboardBloc.close();
    _notificationBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF08100C) : const Color(0xFFF2F5F3);
    final cardBgColor = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AdminDashboardBloc>.value(value: _dashboardBloc),
        BlocProvider<AdminNotificationBloc>.value(value: _notificationBloc),
      ],
      child: BlocListener<AdminDashboardBloc, AdminDashboardState>(
        listener: (context, state) {
          if (state is AdminDashboardActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF0F7253),
              ),
            );
          } else if (state is AdminDashboardError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: RefreshIndicator(
              color: primaryColor,
              onRefresh: () async {
                _dashboardBloc.add(const AdminDashboardRefreshed());
                _notificationBloc.add(const AdminNotificationLoadRequested());
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: SizedBox(
                        height: 40,
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
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MedsCarrier',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ADMIN',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Operations',
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 10),
                        BlocBuilder<AdminNotificationBloc, AdminNotificationState>(
                          bloc: _notificationBloc,
                          builder: (context, notifState) {
                            final unreadCount = notifState is AdminNotificationLoaded
                                ? notifState.unreadCount
                                : 0;
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider.value(
                                      value: _notificationBloc,
                                      child: const AdminNotificationsScreen(),
                                    ),
                                  ),
                                );
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: cardBgColor,
                                    child: Icon(Icons.notifications_outlined, size: 20, color: textPrimary),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE53935),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: cardBgColor, width: 2),
                                        ),
                                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                        child: Text(
                                          '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overview',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Text('Today', style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w600)),
                            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
                  bloc: _dashboardBloc,
                  builder: (context, state) {
                    int activeOrders = 0;
                    int avgDeliveryTime = 0;
                    int onlineRiders = 0;
                    int totalRiders = 0;
                    int activePharmacies = 0;

                    if (state is AdminDashboardLoaded) {
                      activeOrders = state.activeOrders;
                      avgDeliveryTime = state.avgDeliveryTime;
                      onlineRiders = state.onlineRiders;
                      totalRiders = state.totalRiders;
                      activePharmacies = state.activePharmacies;
                    }

                    return SliverGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.45,
                      children: [
                        _buildMetricCard(
                          context,
                          icon: Icons.local_shipping_outlined,
                          value: '$activeOrders',
                          label: 'Active deliveries',
                          badgeText: state is AdminDashboardLoading ? null : null,
                        ),
                        _buildMetricCard(
                          context,
                          icon: Icons.timer_outlined,
                          value: '$avgDeliveryTime',
                          unit: 'min',
                          label: 'Avg delivery time',
                        ),
                        _buildMetricCard(
                          context,
                          icon: Icons.two_wheeler_outlined,
                          value: '$onlineRiders',
                          total: '/ $totalRiders',
                          label: 'Riders on the road',
                        ),
                        _buildMetricCard(
                          context,
                          icon: Icons.storefront_outlined,
                          value: '$activePharmacies',
                          label: 'Active pharmacies',
                        ),
                      ],
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Live fleet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
                                BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
                                  bloc: _dashboardBloc,
                                  builder: (context, state) {
                                    final or = state is AdminDashboardLoaded ? state.onlineRiders : 0;
                                    final ao = state is AdminDashboardLoaded ? state.activeOrders : 0;
                                    return Text(
                                      '$or riders on the road · $ao active deliveries',
                                      style: TextStyle(fontSize: 11, color: textSecondary),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Icon(Icons.open_in_full, size: 16, color: textSecondary),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 110,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF060B08) : const Color(0xFFE3ECE8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              Positioned(top: 30, left: 60, child: _buildMapPin(const Color(0xFF0F7253))),
                              Positioned(top: 40, left: 110, child: _buildMapPin(const Color(0xFF7C4DFF))),
                              Positioned(top: 25, right: 70, child: _buildMapPin(const Color(0xFFFFB74D))),
                              Positioned(bottom: 25, left: 140, child: _buildMapPin(const Color(0xFF0F7253))),
                              Positioned(bottom: 15, right: 100, child: _buildMapPin(const Color(0xFF0F7253))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildLegendItem(const Color(0xFF0F7253), 'Idle rider'),
                            const SizedBox(width: 12),
                            _buildLegendItem(const Color(0xFF7C4DFF), 'In transit'),
                            const SizedBox(width: 12),
                            _buildLegendItem(const Color(0xFFFFB74D), 'CD delivery'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
                bloc: _dashboardBloc,
                builder: (context, state) {
                  final pendingCount = state is AdminDashboardLoaded ? state.pendingPharmacies : 0;
                  final pendingList = state is AdminDashboardLoaded ? state.pendingPharmacyList : [];

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            title: 'Pharmacy approvals',
                            badgeText: '$pendingCount pending',
                            badgeBg: const Color(0xFFFFF3E0),
                            badgeTextColor: const Color(0xFFE65100),
                            actionText: 'See all',
                            onActionTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminPharmacyManagementScreen()),
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (pendingList.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text('No pending pharmacy approvals', style: TextStyle(fontSize: 13, color: textSecondary)),
                              ),
                            ),

                          for (int i = 0; i < pendingList.length; i++) ...[
                            if (i == 0)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardBgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF0F7253).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: primaryColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.store, color: primaryColor, size: 22),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(pendingList[i].pharmacyName,
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 15)),
                                              const SizedBox(height: 2),
                                              Text('GPhC \u2022 ${pendingList[i].gphcNumber}', style: TextStyle(color: textSecondary, fontSize: 11)),
                                              Text(pendingList[i].businessAddress, style: TextStyle(color: textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                        Text(_getTimeAgo(pendingList[i].createdAt), style: TextStyle(color: textSecondary, fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    DocumentImageThumbnail(
                                      title: 'GPhC License Document',
                                      imageUrl: pendingList[i].licenseDocumentUrl,
                                      height: 130,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            onPressed: () {
                                              _showApprovePharmacyDialog(pendingList[i], primaryColor, isDark);
                                            },
                                            icon: const Icon(Icons.check, size: 16),
                                            label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: isDark ? Colors.transparent : const Color(0xFFF0F0F0),
                                              side: BorderSide.none,
                                              foregroundColor: textPrimary,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            onPressed: () {
                                              _showRejectPharmacyDialog(pendingList[i], isDark);
                                            },
                                            icon: const Icon(Icons.close, size: 16),
                                            label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            if (i > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AdminPharmacyManagementScreen()),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: cardBgColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: primaryColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.store, color: primaryColor, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(pendingList[i].pharmacyName, style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                                              Text(pendingList[i].businessAddress, style: TextStyle(color: textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                        Text('${_getTimeAgo(pendingList[i].createdAt)}  ', style: TextStyle(color: textSecondary, fontSize: 10)),
                                        Icon(Icons.arrow_forward_ios, size: 12, color: textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // RIDER APPROVALS SECTION
              BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
                bloc: _dashboardBloc,
                builder: (context, state) {
                  final pendingRiderCount = state is AdminDashboardLoaded ? state.pendingRiders : 0;
                  final pendingRiderList = state is AdminDashboardLoaded ? state.pendingRiderList : <RiderApplicationModel>[];

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            title: 'Rider approvals',
                            badgeText: '$pendingRiderCount pending',
                            badgeBg: const Color(0xFFFF9800).withValues(alpha: 0.15),
                            badgeTextColor: const Color(0xFFE65100),
                            actionText: 'See all',
                            onActionTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminRiderManagementScreen()),
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (pendingRiderList.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text('No pending rider approvals', style: TextStyle(fontSize: 13, color: textSecondary)),
                              ),
                            ),

                          for (int i = 0; i < pendingRiderList.length; i++) ...[
                            if (i == 0)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardBgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.two_wheeler, color: Color(0xFFFF9800), size: 22),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(pendingRiderList[i].fullName,
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 15)),
                                              const SizedBox(height: 2),
                                              Text('${pendingRiderList[i].vehicleType} \u2022 ${pendingRiderList[i].vehicleRegistrationNumber}',
                                                  style: TextStyle(color: textSecondary, fontSize: 11)),
                                              Text('${pendingRiderList[i].phone} \u2022 ${pendingRiderList[i].email}',
                                                  style: TextStyle(color: textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                        Text(_getTimeAgo(pendingRiderList[i].submittedAt), style: TextStyle(color: textSecondary, fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Driving licence front & back thumbnails side-by-side
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DocumentImageThumbnail(
                                            title: 'Licence Front',
                                            imageUrl: pendingRiderList[i].drivingLicenceFrontUrl,
                                            height: 100,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: DocumentImageThumbnail(
                                            title: 'Licence Back',
                                            imageUrl: pendingRiderList[i].drivingLicenceBackUrl,
                                            height: 100,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: isDark ? Colors.transparent : const Color(0xFFF0F0F0),
                                              side: BorderSide.none,
                                              foregroundColor: textPrimary,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            onPressed: () {
                                              _showRiderDetailsDialog(pendingRiderList[i], primaryColor, isDark);
                                            },
                                            child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0F7253),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            onPressed: () {
                                              _showApproveRiderDialog(pendingRiderList[i], primaryColor, isDark);
                                            },
                                            icon: const Icon(Icons.check, size: 16),
                                            label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () {
                                            _showRejectRiderDialog(pendingRiderList[i], isDark);
                                          },
                                          icon: Icon(Icons.close, size: 18, color: Colors.red.shade600),
                                          tooltip: 'Reject',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            if (i > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const AdminRiderManagementScreen()),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: cardBgColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.two_wheeler, color: Color(0xFFFF9800), size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(pendingRiderList[i].fullName, style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                                              Text('${pendingRiderList[i].vehicleType} \u2022 ${pendingRiderList[i].vehicleRegistrationNumber}',
                                                  style: TextStyle(color: textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                        Text('${_getTimeAgo(pendingRiderList[i].submittedAt)}  ', style: TextStyle(color: textSecondary, fontSize: 10)),
                                        Icon(Icons.arrow_forward_ios, size: 12, color: textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),

              BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
                bloc: _dashboardBloc,
                builder: (context, state) {
                  final readyList = state is AdminDashboardLoaded ? state.readyOrderList : [];

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            title: 'Awaiting assignment',
                            badgeText: '${readyList.length} orders',
                            badgeBg: const Color(0xFFE8EAF6),
                            badgeTextColor: const Color(0xFF3F51B5),
                            actionText: 'See all',
                            onActionTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (readyList.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text('No orders awaiting assignment', style: TextStyle(fontSize: 13, color: textSecondary)),
                              ),
                            ),

                          for (final order in readyList)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cardBgColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('#${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 12)),
                                        const SizedBox(width: 6),
                                        if (order.controlledDrug) _buildTag('CD', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
                                        if (order.coldChain) ...[
                                          if (order.controlledDrug) const SizedBox(width: 4),
                                          _buildTag('2\u20138\u00B0C', const Color(0xFFE0F7FA), const Color(0xFF00838F)),
                                        ],
                                        const Spacer(),
                                        _buildTag('Ready', const Color(0xFFE8F5E9), primaryColor),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(order.pharmacyName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary)),
                                        ),
                                        Icon(Icons.arrow_right_alt, color: textSecondary),
                                        Expanded(
                                          child: Text(order.dropoffAddress, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary), overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () {
                                              _showAssignRiderDialog(order.id);
                                            },
                                            icon: const Icon(Icons.two_wheeler, size: 16),
                                            label: const Text('Assign rider', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: isDark ? Colors.transparent : const Color(0xFFF0F0F0),
                                              side: BorderSide.none,
                                              foregroundColor: textPrimary,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () {
                                              _dashboardBloc.add(AdminDashboardAutoAssignOrder(order.id));
                                            },
                                            child: const Text('Auto-assign', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),

              BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
                bloc: _dashboardBloc,
                builder: (context, state) {
                  final activeList = state is AdminDashboardLoaded ? state.activeOrderList : [];

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            title: 'Live deliveries',
                            actionText: 'View all',
                            onActionTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (activeList.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text('No active deliveries', style: TextStyle(fontSize: 13, color: textSecondary)),
                              ),
                            ),

                          for (final order in activeList)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildDeliveryTile(
                                orderId: '#${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}',
                                tags: [
                                  if (order.controlledDrug) _buildTag('CD', const Color(0xFFFFF3E0), const Color(0xFFE65100)),
                                  if (order.coldChain) _buildTag('2\u20138\u00B0C', const Color(0xFFE0F7FA), const Color(0xFF00838F)),
                                  _buildTag(order.status, const Color(0xFFEDE7F6), const Color(0xFF512DA8)),
                                ],
                                avatarInitial: (order.riderName ?? 'NA').substring(0, 2).toUpperCase(),
                                name: order.riderName ?? 'Unassigned',
                                routeText: '${order.pharmacyName} \u2192 ${order.dropoffAddress}',
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tools', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
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
          ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (index == 0) {
              setState(() { _selectedIndex = 0; });
              return;
            }
            if (index == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersScreen()));
              return;
            }
            if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRiderManagementScreen()));
              return;
            }
            if (index == 3) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPharmacyManagementScreen()));
              return;
            }
            if (index == 4) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAccountScreen()));
              return;
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primaryColor,
          unselectedItemColor: textSecondary,
          backgroundColor: cardBgColor,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.two_wheeler_outlined), label: 'Riders'),
            BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Pharmacy'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
          ],
        ),
      ),
    ),
  );
}

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primaryColor, size: 16),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isBadgeGreen ? primaryColor.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, size: 10, color: primaryColor),
                      const SizedBox(width: 2),
                      Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                ),
            ],
          ),
          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
              children: [
                if (unit != null) TextSpan(text: unit, style: TextStyle(fontSize: 12, color: textSecondary)),
                if (total != null) TextSpan(text: ' $total', style: TextStyle(fontSize: 13, color: textSecondary)),
              ],
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? badgeText,
    Color? badgeBg,
    Color? badgeTextColor,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);

    return Row(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary)),
        if (badgeText != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
            child: Text(badgeText, style: TextStyle(fontSize: 10, color: badgeTextColor, fontWeight: FontWeight.bold)),
          ),
        ],
        const Spacer(),
        if (actionText != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(actionText, style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  String _getTimeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showAssignRiderDialog(String orderId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Assign Rider'),
        content: const Text('Go to Rider Management to assign a rider to this order.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminRiderManagementScreen()),
              );
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 9, color: text, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDeliveryTile({
    required String orderId,
    required List<Widget> tags,
    required String avatarInitial,
    required String name,
    required String routeText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(orderId, style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 11)),
              const SizedBox(width: 6),
              Wrap(spacing: 4, children: tags),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: primaryColor.withValues(alpha: 0.15),
                child: Text(avatarInitial, style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textPrimary)),
                    Text(routeText, style: TextStyle(fontSize: 10, color: textSecondary), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 12, color: textSecondary),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMapPin(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
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
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, color: textSecondary)),
          ],
        ),
      ),
    );
  }

  void _showApprovePharmacyDialog(
    PharmacyModel pharmacy,
    Color primaryColor,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0E1A14) : Colors.white,
        title: Text(
          'Approve Pharmacy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF191C1B),
          ),
        ),
        content: Text(
          'Approve ${pharmacy.pharmacyName}? This will activate their pharmacy account and send an email to ${pharmacy.email.isNotEmpty ? pharmacy.email : "their email"} with a link to create their password.',
          style: TextStyle(
            color: isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _dashboardBloc.add(AdminDashboardApprovePharmacy(pharmacy.id));
            },
            child: const Text('Approve & Send Email'),
          ),
        ],
      ),
    );
  }

  void _showRejectPharmacyDialog(
    PharmacyModel pharmacy,
    bool isDark,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0E1A14) : Colors.white,
        title: Text(
          'Reject Pharmacy Application',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF191C1B),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reject the application for ${pharmacy.pharmacyName}?',
              style: TextStyle(
                color: isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason for rejection (optional)',
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _dashboardBloc.add(AdminDashboardRejectPharmacy(pharmacy.id));
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showApproveRiderDialog(
    RiderApplicationModel rider,
    Color primaryColor,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0E1A14) : Colors.white,
        title: Text(
          'Approve Rider',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF191C1B),
          ),
        ),
        content: Text(
          'Approve ${rider.fullName}? This will activate their rider account and send an email to ${rider.email.isNotEmpty ? rider.email : "their email"} with approval details.',
          style: TextStyle(
            color: isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F7253),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _dashboardBloc.add(AdminDashboardApproveRider(rider.id));
            },
            child: const Text('Approve & Send Email'),
          ),
        ],
      ),
    );
  }

  void _showRejectRiderDialog(
    RiderApplicationModel rider,
    bool isDark,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0E1A14) : Colors.white,
        title: Text(
          'Reject Rider Application',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF191C1B),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to reject the application for ${rider.fullName}?',
              style: TextStyle(
                color: isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason for rejection (optional)',
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _dashboardBloc.add(
                AdminDashboardRejectRider(
                  rider.id,
                  reason: reasonController.text.trim(),
                ),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showRiderDetailsDialog(
    RiderApplicationModel rider,
    Color primaryColor,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0E1A14) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rider.fullName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF191C1B),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDialogDetail('Email', rider.email, isDark),
            _buildDialogDetail('Phone', rider.phone, isDark),
            _buildDialogDetail('Vehicle Type', rider.vehicleType, isDark),
            _buildDialogDetail('Vehicle Reg', rider.vehicleRegistrationNumber, isDark),
            _buildDialogDetail(
              'Submitted',
              rider.submittedAt != null
                  ? '${rider.submittedAt!.day}/${rider.submittedAt!.month}/${rider.submittedAt!.year}'
                  : 'Unknown',
              isDark,
            ),
            const SizedBox(height: 14),
            Text(
              'Driving Licence Documents',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF191C1B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DocumentImageThumbnail(
                    title: 'Licence Front',
                    imageUrl: rider.drivingLicenceFrontUrl,
                    height: 120,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DocumentImageThumbnail(
                    title: 'Licence Back',
                    imageUrl: rider.drivingLicenceBackUrl,
                    height: 120,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7253),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showApproveRiderDialog(rider, primaryColor, isDark);
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve Application', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showRejectRiderDialog(rider, isDark);
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject Application', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogDetail(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF191C1B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
