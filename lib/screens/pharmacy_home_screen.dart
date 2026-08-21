import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pharmacy_home/pharmacy_home_bloc.dart';
import '../bloc/pharmacy_home/pharmacy_home_event.dart';
import '../bloc/pharmacy_home/pharmacy_home_state.dart';
import '../bloc/pharmacy_orders/pharmacy_orders_bloc.dart';
import '../bloc/pharmacy_orders/pharmacy_orders_event.dart';
import '../bloc/pharmacy_orders/pharmacy_orders_state.dart';

import '../widgets/pharmacy_home_header.dart';
import '../widgets/pharmacy_order_summary.dart';
import '../widgets/pharmacy_active_order_card.dart';
import '../widgets/pharmacy_bottom_nav.dart';
import 'pharmacy_orders_screen.dart';
import 'pharmacy_medicines_screen.dart';
import 'pharmacy_profile_screen.dart';
import 'pharmacy_notifications_screen.dart';

class PharmacyHomeScreen extends StatelessWidget {
  const PharmacyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PharmacyHomeBloc()..add(const LoadPharmacyHome()),
        ),
        BlocProvider(
          create: (_) => PharmacyOrdersBloc()..add(const LoadPharmacyOrders()),
        ),
      ],
      child: const _PharmacyHomeView(),
    );
  }
}

class _PharmacyHomeView extends StatefulWidget {
  const _PharmacyHomeView();

  @override
  State<_PharmacyHomeView> createState() => _PharmacyHomeViewState();
}

class _PharmacyHomeViewState extends State<_PharmacyHomeView> {
  int _currentIndex = 0;
  bool _isAcceptingOrders = true;
  int _selectedFilterTab = 0;

  static const _filterLabels = ['New', 'Preparing', 'Ready', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0C1310)
            : theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: _buildBody(),
        ),
        bottomNavigationBar: PharmacyBottomNav(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const PharmacyOrdersScreen();
      case 2:
        return const PharmacyMedicinesScreen();
      case 3:
        return const PharmacyProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return BlocBuilder<PharmacyHomeBloc, PharmacyHomeState>(
      builder: (context, homeState) {
        if (homeState is PharmacyHomeLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (homeState is PharmacyHomeError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 50),
                  const SizedBox(height: 16),
                  Text(
                    homeState.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<PharmacyHomeBloc>()
                          .add(const LoadPharmacyHome());
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        if (homeState is PharmacyHomeLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<PharmacyHomeBloc>()
                  .add(const PharmacyHomeRefreshed());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Top section: header + toggle + filter tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        PharmacyHomeHeader(
                          pharmacyName: homeState.pharmacy.pharmacyName,
                          pharmacyCode:
                              homeState.pharmacy.gphcNumber,
                          onNotificationTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const PharmacyNotificationsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Accepting Orders + Filter Tabs
                        PharmacyOrderSummary(
                          isAcceptingOrders: _isAcceptingOrders,
                          onToggleAccepting: (val) {
                            setState(() => _isAcceptingOrders = val);
                          },
                          newCount: homeState.newOrders,
                          preparingCount: homeState.preparingOrders,
                          readyCount: homeState.readyOrders,
                          deliveredCount: homeState.deliveredOrders,
                          selectedTab: _selectedFilterTab,
                          onTabTap: (index) {
                            setState(() => _selectedFilterTab = index);
                            context.read<PharmacyOrdersBloc>().add(
                                  PharmacyOrdersFiltered(
                                    _filterLabels[index],
                                  ),
                                );
                            // Switch to Orders tab
                            setState(() => _currentIndex = 1);
                          },
                        ),
                        const SizedBox(height: 20),

                        // Live Orders Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Live orders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() => _currentIndex = 1);
                              },
                              child: Text(
                                'View all',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Active order cards from bloc
                BlocBuilder<PharmacyOrdersBloc, PharmacyOrdersState>(
                  builder: (context, orderState) {
                    if (orderState is PharmacyOrdersLoaded) {
                      final activeOrders = orderState.allOrders
                          .where((o) => o.status != 'Delivered')
                          .toList();

                      if (activeOrders.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 40,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'All caught up!',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No active orders right now.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            activeOrders.take(4).map((order) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12),
                                child: PharmacyActiveOrderCard(
                                  orderId: order.id,
                                  customerName: order.customerName,
                                  orderTime: order.time,
                                  medicineCount:
                                      '${order.medicineCount} ${order.medicineCount == 1 ? "item" : "items"}',
                                  status: order.status,
                                  statusType:
                                      _mapStatus(order.status),
                                  location: 'London, UK',
                                  tags: _extractTags(order),
                                  actionButtonText:
                                      _actionForStatus(order.status),
                                  onActionPressed: () {
                                    _handleOrderAction(order);
                                  },
                                  riderName: order.riderName,
                                  driverInitials: order.riderName
                                          .isNotEmpty
                                      ? order.riderName
                                          .split(' ')
                                          .map((w) => w[0])
                                          .join()
                                      : '',
                                  driverStatus:
                                      order.riderName.isNotEmpty
                                          ? 'Collecting now'
                                          : '',
                                  onTap: () {},
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }

                    return const SliverToBoxAdapter(
                      child: SizedBox(),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  PharmacyOrderStatusType _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return PharmacyOrderStatusType.isNew;
      case 'preparing':
        return PharmacyOrderStatusType.preparing;
      case 'ready':
        return PharmacyOrderStatusType.ready;
      case 'rider en route':
        return PharmacyOrderStatusType.riderEnRoute;
      case 'on the way':
        return PharmacyOrderStatusType.onTheWay;
      case 'delivered':
        return PharmacyOrderStatusType.delivered;
      default:
        return PharmacyOrderStatusType.isNew;
    }
  }

  List<String> _extractTags(PharmacyOrder order) {
    final tags = <String>[];
    final lowerItems = order.items.map((i) => i.toLowerCase()).join(' ');
    if (lowerItems.contains('codeine') ||
        lowerItems.contains('tramadol') ||
        lowerItems.contains('morphine') ||
        lowerItems.contains('naproxen') ||
        lowerItems.contains('co-codamol')) {
      tags.add('CD');
    }
    if (lowerItems.contains('insulin') ||
        lowerItems.contains('injection') ||
        lowerItems.contains('inhaler')) {
      tags.add('2-8°C');
    }
    return tags;
  }

  String? _actionForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return 'Accept order';
      case 'preparing':
        return 'Mark ready for pickup';
      default:
        return null;
    }
  }

  void _handleOrderAction(PharmacyOrder order) {
    final bloc = context.read<PharmacyOrdersBloc>();
    switch (order.status.toLowerCase()) {
      case 'new':
        bloc.add(PharmacyOrderStatusChanged(
          id: order.id,
          newStatus: 'Preparing',
        ));
        break;
      case 'preparing':
        bloc.add(PharmacyOrderStatusChanged(
          id: order.id,
          newStatus: 'Ready',
          riderName: order.riderName,
          riderPhone: order.riderPhone,
        ));
        break;
    }
  }
}
