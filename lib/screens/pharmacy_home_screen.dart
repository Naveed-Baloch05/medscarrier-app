import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pharmacy_home/pharmacy_home_bloc.dart';
import '../bloc/pharmacy_home/pharmacy_home_event.dart';
import '../bloc/pharmacy_home/pharmacy_home_state.dart';
import '../bloc/pharmacy_orders/pharmacy_orders_bloc.dart';
import '../bloc/pharmacy_orders/pharmacy_orders_event.dart';

import '../widgets/pharmacy_home_header.dart';
import '../widgets/pharmacy_order_summary.dart';
import '../widgets/pharmacy_order_status.dart';
import '../widgets/pharmacy_active_order_card.dart';
import '../widgets/pharmacy_bottom_nav.dart';
import 'pharmacy_orders_screen.dart';
import 'pharmacy_medicines_screen.dart';
import 'pharmacy_profile_screen.dart';

class PharmacyHomeScreen extends StatelessWidget {
  const PharmacyHomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PharmacyHomeBloc()
            ..add(const LoadPharmacyHome()),
        ),
        BlocProvider(
          create: (_) => PharmacyOrdersBloc()
            ..add(const LoadPharmacyOrders()),
        ),
      ],
      child: const _PharmacyHomeView(),
    );
  }
}

class _PharmacyHomeView extends StatefulWidget {
  const _PharmacyHomeView();

  @override
  State<_PharmacyHomeView> createState() =>
      _PharmacyHomeViewState();
}

class _PharmacyHomeViewState
    extends State<_PharmacyHomeView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,

        body: SafeArea(
          child: _buildBody(),
        ),

      // --------------------------------------------------------------
      // BOTTOM NAVIGATION
      // --------------------------------------------------------------

      bottomNavigationBar: PharmacyBottomNav(
        currentIndex: _currentIndex,

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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
      builder: (context, state) {
        if (state is PharmacyHomeLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is PharmacyHomeError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 50,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PharmacyHomeBloc>().add(
                            const LoadPharmacyHome(),
                          );
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is PharmacyHomeLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<PharmacyHomeBloc>().add(
                    const PharmacyHomeRefreshed(),
                  );
              await Future.delayed(
                  const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  20, 16, 20, 30),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  PharmacyHomeHeader(
                    pharmacyName:
                        state.pharmacy.pharmacyName,
                    onNotificationTap: () {},
                  ),
                  const SizedBox(height: 24),
                  PharmacyOrderSummary(
                    totalOrders: state.totalOrders,
                    completedOrders:
                        state.completedOrders,
                    activeOrders: state.activeOrders,
                  ),
                  const SizedBox(height: 28),
                  PharmacyOrderStatus(
                    newOrders: state.newOrders,
                    preparingOrders:
                        state.preparingOrders,
                    readyOrders: state.readyOrders,
                    deliveredOrders:
                        state.deliveredOrders,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Text(
                        'Active Orders',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() =>
                              _currentIndex = 1);
                        },
                        child:
                            const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PharmacyActiveOrderCard(
                    orderId: '#ORD-1024',
                    customerName: 'John Smith',
                    orderTime: '10:45 AM',
                    medicineCount: '3 Medicines',
                    status: 'Preparing',
                    controlledDrug: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  PharmacyActiveOrderCard(
                    orderId: '#ORD-1023',
                    customerName: 'Sarah Wilson',
                    orderTime: '10:30 AM',
                    medicineCount: '2 Medicines',
                    status: 'Ready for Pickup',
                    coldChain: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  PharmacyActiveOrderCard(
                    orderId: '#ORD-1022',
                    customerName: 'Ali Ahmed',
                    orderTime: '10:15 AM',
                    medicineCount: '4 Medicines',
                    status: 'New Order',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}