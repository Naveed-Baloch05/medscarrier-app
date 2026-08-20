import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/rider_home/rider_home_bloc.dart';
import '../bloc/rider_home/rider_home_event.dart';
import '../bloc/rider_home/rider_home_state.dart';

class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RiderHomeBloc()..add(const LoadRiderHome()),
      child: const _RiderHomeView(),
    );
  }
}

class _RiderHomeView extends StatefulWidget {
  const _RiderHomeView();

  @override
  State<_RiderHomeView> createState() => _RiderHomeViewState();
}

class _RiderHomeViewState extends State<_RiderHomeView> {
  int _currentIndex = 0;

  static const Color primaryAccent = Color(0xFFE05333);
  static const Color darkText = Color(0xFF0F231F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: BlocBuilder<RiderHomeBloc, RiderHomeState>(
          builder: (context, state) {
            if (state is RiderHomeLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is RiderHomeError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 50),
                      const SizedBox(height: 16),
                      Text(state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<RiderHomeBloc>()
                              .add(const LoadRiderHome());
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is RiderHomeLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<RiderHomeBloc>()
                      .add(const RiderHomeRefreshed());
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: primaryAccent,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.rider.fullName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: darkText,
                                  ),
                                ),
                                Text(
                                  'Ready to deliver?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: darkText,
                              size: 22,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // EARNINGS CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [darkText, primaryAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryAccent.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Earnings",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '£${state.totalEarnings.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // STATS ROW
                      Row(
                        children: [
                          _StatCard(
                            label: 'Today',
                            value: '${state.todayDeliveries}',
                            subtitle: 'deliveries',
                            color: const Color(0xFF2196F3),
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: 'Done',
                            value: '${state.completedDeliveries}',
                            subtitle: 'completed',
                            color: const Color(0xFF4CAF50),
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: 'Pending',
                            value: '${state.pendingDeliveries}',
                            subtitle: 'in queue',
                            color: const Color(0xFFFF9800),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // QUICK ACTIONS
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.local_shipping_outlined,
                              label: 'My Deliveries',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.map_outlined,
                              label: 'Route Map',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Earnings',
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.headset_mic_outlined,
                              label: 'Support',
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // PENDING DELIVERIES
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Pending Deliveries',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      _DeliveryCard(
                        orderId: '#ORD-2048',
                        customerName: 'John Smith',
                        address: '123 High Street, London',
                        distance: '1.2 km',
                        status: 'Ready for Pickup',
                      ),
                      const SizedBox(height: 10),
                      _DeliveryCard(
                        orderId: '#ORD-2049',
                        customerName: 'Sarah Wilson',
                        address: '456 Oxford Street, London',
                        distance: '2.5 km',
                        status: 'New Order',
                      ),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryAccent,
        unselectedItemColor: Colors.grey.shade500,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping_rounded),
            label: 'Deliveries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: const Color(0xFFE05333)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.orderId,
    required this.customerName,
    required this.address,
    required this.distance,
    required this.status,
  });

  final String orderId;
  final String customerName;
  final String address;
  final String distance;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Flexible(
                child: Text(
                  orderId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F231F),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'New Order'
                      ? const Color(0xFF2196F3).withValues(alpha: 0.1)
                      : const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: status == 'New Order'
                        ? const Color(0xFF2196F3)
                        : const Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            customerName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                distance,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
