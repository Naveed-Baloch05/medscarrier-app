import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pharmacy_home/pharmacy_home_bloc.dart';
import '../bloc/pharmacy_home/pharmacy_home_event.dart';
import '../bloc/pharmacy_home/pharmacy_home_state.dart';

import '../bloc/pharmacy_notifications/pharmacy_notifications_bloc.dart';
import '../bloc/pharmacy_notifications/pharmacy_notifications_event.dart';

import '../bloc/pharmacy_orders/pharmacy_orders_bloc.dart';
import '../bloc/pharmacy_orders/pharmacy_orders_event.dart';
import '../bloc/pharmacy_orders/pharmacy_orders_state.dart';

import '../bloc/pharmacy_profile/pharmacy_profile_bloc.dart';
import '../bloc/pharmacy_profile/pharmacy_profile_event.dart';

import '../widgets/pharmacy_home_header.dart';
import '../widgets/pharmacy_order_summary.dart';
import '../widgets/pharmacy_active_order_card.dart';
import '../widgets/pharmacy_bottom_nav.dart';

import 'pharmacy_live_tracking_screen.dart';
import 'pharmacy_orders_screen.dart';
import 'pharmacy_history_screen.dart';
import 'pharmacy_profile_screen.dart';
import 'pharmacy_notifications_screen.dart';
import '../core/services/pharmacy_tracking_service.dart';
import '../models/delivery_route_model.dart';

class PharmacyHomeScreen extends StatelessWidget {
  const PharmacyHomeScreen({
    super.key,
    required this.pharmacyId,
  });

  final String pharmacyId;

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[HOME-SCREEN] pharmacyId=$pharmacyId',
    );

    return MultiBlocProvider(
      providers: [
        // ----------------------------------------------------------
        // PHARMACY HOME
        // ----------------------------------------------------------

        BlocProvider(
          create: (_) => PharmacyHomeBloc()
            ..add(
              LoadPharmacyHome(pharmacyId),
            ),
        ),

        // ----------------------------------------------------------
        // PHARMACY ORDERS
        // ----------------------------------------------------------

        BlocProvider(
          create: (_) => PharmacyOrdersBloc()
            ..add(
              LoadPharmacyOrders(pharmacyId),
            ),
        ),

        // ----------------------------------------------------------
        // PHARMACY PROFILE
        // ----------------------------------------------------------

        BlocProvider(
          create: (_) => PharmacyProfileBloc()
            ..add(
              LoadPharmacyProfile(pharmacyId),
            ),
        ),

        // ----------------------------------------------------------
        // PHARMACY NOTIFICATIONS
        // ----------------------------------------------------------

        BlocProvider(
          create: (_) => PharmacyNotificationsBloc()
            ..add(
              LoadPharmacyNotifications(pharmacyId),
            ),
        ),
      ],
      child: _PharmacyHomeView(
        pharmacyId: pharmacyId,
      ),
    );
  }
}

// ==================================================================
// HOME VIEW
// ==================================================================

class _PharmacyHomeView extends StatefulWidget {
  const _PharmacyHomeView({
    required this.pharmacyId,
  });

  final String pharmacyId;

  @override
  State<_PharmacyHomeView> createState() =>
      _PharmacyHomeViewState();
}

class _PharmacyHomeViewState
    extends State<_PharmacyHomeView> {
  int _currentIndex = 0;

  bool _isAcceptingOrders = true;

  int _selectedFilterTab = 0;

  static const List<String> _filterLabels = [
    'New',
    'Preparing',
    'Ready',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark =
        theme.brightness == Brightness.dark;

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
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
          onTap: _onBottomNavigationTap,
        ),
      ),
    );
  }

  // ==============================================================
  // BOTTOM NAVIGATION
  // ==============================================================

  void _onBottomNavigationTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Refresh orders whenever Orders tab is opened.
    if (index == 1) {
      context
          .read<PharmacyOrdersBloc>()
          .add(
        const PharmacyOrdersRefreshed(),
      );
    }
  }

  // ==============================================================
  // BODY
  // ==============================================================

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();

      case 1:
        return const PharmacyOrdersScreen();

      case 2:
        return PharmacyHistoryScreen(
          pharmacyId: widget.pharmacyId,
        );

      case 3:
        return PharmacyProfileScreen(
          pharmacyId: widget.pharmacyId,
        );

      default:
        return _buildHomeTab();
    }
  }

  // ==============================================================
  // HOME TAB
  // ==============================================================

  Widget _buildHomeTab() {
    return BlocBuilder<
        PharmacyHomeBloc,
        PharmacyHomeState>(
      builder: (context, homeState) {
        // ----------------------------------------------------------
        // LOADING
        // ----------------------------------------------------------

        if (homeState is PharmacyHomeLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // ----------------------------------------------------------
        // ERROR
        // ----------------------------------------------------------

        if (homeState is PharmacyHomeError) {
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
                    homeState.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<PharmacyHomeBloc>()
                          .add(
                        LoadPharmacyHome(
                          widget.pharmacyId,
                        ),
                      );
                    },
                    child: const Text(
                      'Try Again',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ----------------------------------------------------------
        // LOADED
        // ----------------------------------------------------------

        if (homeState is PharmacyHomeLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<PharmacyHomeBloc>()
                  .add(
                LoadPharmacyHome(
                  widget.pharmacyId,
                ),
              );

              context
                  .read<PharmacyOrdersBloc>()
                  .add(
                const PharmacyOrdersRefreshed(),
              );

              await Future.delayed(
                const Duration(
                  milliseconds: 500,
                ),
              );
            },
            child: CustomScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              slivers: [
                // --------------------------------------------------
                // HEADER + SUMMARY
                // --------------------------------------------------

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        PharmacyHomeHeader(
                          pharmacyName:
                          homeState
                              .pharmacy
                              .pharmacyName,
                          pharmacyCode: homeState.pharmacy.pharmacyCode.isNotEmpty
                              ? homeState.pharmacy.pharmacyCode
                              : homeState.pharmacy.gphcNumber,
                          onNotificationTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BlocProvider(
                                      create: (_) =>
                                      PharmacyNotificationsBloc()
                                        ..add(
                                          LoadPharmacyNotifications(
                                            widget.pharmacyId,
                                          ),
                                        ),
                                      child:
                                      PharmacyNotificationsScreen(
                                        pharmacyId:
                                        widget.pharmacyId,
                                      ),
                                    ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        PharmacyOrderSummary(
                          isAcceptingOrders:
                          _isAcceptingOrders,
                          onToggleAccepting: (value) {
                            setState(() {
                              _isAcceptingOrders =
                                  value;
                            });
                          },
                          newCount:
                          homeState.newOrders,
                          preparingCount:
                          homeState.preparingOrders,
                          readyCount:
                          homeState.readyOrders,
                          deliveredCount:
                          homeState.deliveredOrders,
                          selectedTab:
                          _selectedFilterTab,
                          onTabTap: (index) {
                            if (index < 0 ||
                                index >=
                                    _filterLabels.length) {
                              return;
                            }

                            setState(() {
                              _selectedFilterTab =
                                  index;
                              _currentIndex = 1;
                            });

                            context
                                .read<
                                PharmacyOrdersBloc>()
                                .add(
                              PharmacyOrdersFiltered(
                                _filterLabels[
                                index],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // ------------------------------------------------
                        // LIVE ROUTE TRACKING
                        // ------------------------------------------------
                        _buildLiveRouteTrackingCard(context),

                        const SizedBox(height: 20),

                        // ------------------------------------------------
                        // LIVE ORDERS HEADER
                        // ------------------------------------------------

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                          children: [
                            Text(
                              'Live orders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.bold,
                                color: Theme.of(
                                  context,
                                )
                                    .colorScheme
                                    .onSurface,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _currentIndex =
                                  1;
                                });

                                context
                                    .read<
                                    PharmacyOrdersBloc>()
                                    .add(
                                  const PharmacyOrdersRefreshed(),
                                );
                              },
                              child: Text(
                                'View all',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  )
                                      .colorScheme
                                      .primary,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ------------------------------------------------------
                // LIVE ORDERS
                // ------------------------------------------------------

                BlocBuilder<
                    PharmacyOrdersBloc,
                    PharmacyOrdersState>(
                  builder:
                      (context, orderState) {
                    // ------------------------------
                    // ERROR
                    // ------------------------------

                    if (orderState
                    is PharmacyOrdersError) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 16,
                          ),
                          child: Container(
                            padding:
                            const EdgeInsets.all(
                              20,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              Theme.of(
                                context,
                              ).cardColor,
                              borderRadius:
                              BorderRadius
                                  .circular(
                                16,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons
                                      .error_outline_rounded,
                                  size: 40,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  orderState
                                      .message,
                                  textAlign:
                                  TextAlign
                                      .center,
                                  style:
                                  const TextStyle(
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    context
                                        .read<
                                        PharmacyOrdersBloc>()
                                        .add(
                                      const PharmacyOrdersRefreshed(),
                                    );
                                  },
                                  child:
                                  const Text(
                                    'Retry',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // ------------------------------
                    // LOADING
                    // ------------------------------

                    if (orderState
                    is PharmacyOrdersLoading) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding:
                          EdgeInsets.all(30),
                          child: Center(
                            child:
                            CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }

                    // ------------------------------
                    // LOADED
                    // ------------------------------

                    if (orderState
                    is PharmacyOrdersLoaded) {
                      final activeOrders =
                      orderState.allOrders
                          .where(
                            (order) {
                          final status =
                          order.status
                              .toLowerCase();

                          return status !=
                              'delivered' &&
                              status !=
                                  'completed';
                        },
                      ).toList();

                      // ----------------------------
                      // NO ACTIVE ORDERS
                      // ----------------------------

                      if (activeOrders
                          .isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 16,
                            ),
                            child: Container(
                              width:
                              double.infinity,
                              padding:
                              const EdgeInsets
                                  .all(24),
                              decoration:
                              BoxDecoration(
                                color:
                                Theme.of(
                                  context,
                                ).cardColor,
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  16,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons
                                        .check_circle_outline_rounded,
                                    size: 40,
                                    color: Theme
                                        .of(
                                      context,
                                    )
                                        .colorScheme
                                        .primary,
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  Text(
                                    'All caught up!',
                                    style:
                                    TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                      FontWeight
                                          .w700,
                                      color: Theme
                                          .of(
                                        context,
                                      )
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    'No active orders right now.',
                                    style:
                                    TextStyle(
                                      fontSize: 13,
                                      color: Theme
                                          .of(
                                        context,
                                      )
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

                      // ----------------------------
                      // ACTIVE ORDERS
                      // ----------------------------

                      return SliverPadding(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 16,
                        ),
                        sliver: SliverList(
                          delegate:
                          SliverChildListDelegate(
                            activeOrders
                                .take(4)
                                .map(
                                  (order) {
                                return Padding(
                                  padding:
                                  const EdgeInsets
                                      .only(
                                    bottom: 12,
                                  ),
                                  child:
                                  PharmacyActiveOrderCard(
                                    orderId:
                                    order.id,
                                    customerName:
                                    order
                                        .customerName,
                                    orderTime:
                                    order.time,
                                    medicineCount:
                                    '${order.medicineCount} ${order.medicineCount == 1 ? "item" : "items"}',
                                    status:
                                    order.status,
                                    statusType:
                                    _mapStatus(
                                      order.status,
                                    ),
                                    location: order.deliveryAddress,
                                    tags:
                                    _extractTags(
                                      order,
                                    ),
                                    actionButtonText:
                                    _actionForStatus(
                                      order.status,
                                    ),
                                    onActionPressed:
                                        () {
                                      _handleOrderAction(
                                        order,
                                      );
                                    },
                                    riderName:
                                    order
                                        .riderName,
                                    driverInitials:
                                    _driverInitials(
                                      order
                                          .riderName,
                                    ),
                                    driverStatus:
                                    order.riderName.isNotEmpty
                                        ? (order.isInTransit
                                            ? 'Out for delivery • Tap to track'
                                            : 'Assigned • Tap to track')
                                        : '',
                                    onTap: () {
                                      if (order.canTrackLive) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PharmacyLiveTrackingScreen(
                                              pharmacyId: widget.pharmacyId,
                                              riderId: order.riderId,
                                              riderName: order.riderName,
                                              initialOrderId: order.docId,
                                            ),
                                          ),
                                        );
                                      } else {
                                        _openOrdersScreen();
                                      }
                                    },
                                  ),
                                );
                              },
                            ).toList(),
                          ),
                        ),
                      );
                    }

                    return const SliverToBoxAdapter(
                      child: SizedBox(),
                    );
                  },
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  // ==============================================================
  // OPEN ORDERS
  // ==============================================================

  void _openOrdersScreen() {
    setState(() {
      _currentIndex = 1;
    });

    context
        .read<PharmacyOrdersBloc>()
        .add(
      const PharmacyOrdersRefreshed(),
    );
  }

  // ==============================================================
  // ORDER ACTION
  // ==============================================================

  void _handleOrderAction(
      PharmacyOrder order,
      ) {
    final bloc =
    context.read<PharmacyOrdersBloc>();

    switch (order.status.toLowerCase()) {
      case 'new':
        bloc.add(
          PharmacyOrderStatusChanged(
            id: order.id,
            newStatus: 'Preparing',
          ),
        );
        break;

      case 'preparing':
        bloc.add(
          PharmacyOrderStatusChanged(
            id: order.id,
            newStatus: 'Ready',
            riderName: order.riderName,
            riderPhone: order.riderPhone,
          ),
        );
        break;
    }
  }

  // ==============================================================
  // STATUS MAPPING
  // ==============================================================

  PharmacyOrderStatusType _mapStatus(
      String status,
      ) {
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

  // ==============================================================
  // ORDER TAGS
  // ==============================================================

  List<String> _extractTags(
      PharmacyOrder order,
      ) {
    final tags = <String>[];

    if (order.controlledDrug) {
      tags.add('CD');
    }

    if (order.coldChain) {
      tags.add('2-8°C');
    }

    final lowerItems = order.items
        .map(
          (item) => item.toLowerCase(),
    )
        .join(' ');

    if (!tags.contains('CD') &&
        (lowerItems.contains('codeine') ||
            lowerItems.contains('tramadol') ||
            lowerItems.contains('morphine') ||
            lowerItems.contains('naproxen') ||
            lowerItems.contains('co-codamol'))) {
      tags.add('CD');
    }

    if (!tags.contains('2-8°C') &&
        (lowerItems.contains('insulin') ||
            lowerItems.contains('injection') ||
            lowerItems.contains('inhaler'))) {
      tags.add('2-8°C');
    }

    return tags;
  }

  // ==============================================================
  // DRIVER INITIALS
  // ==============================================================

  String _driverInitials(
      String name,
      ) {
    if (name.trim().isEmpty) {
      return '';
    }

    final words = name
        .trim()
        .split(RegExp(r'\s+'));

    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }

    return words
        .take(2)
        .map(
          (word) => word[0].toUpperCase(),
    )
        .join();
  }

  // ==============================================================
  // ACTION BUTTON TEXT
  // ==============================================================

  String? _actionForStatus(
      String status,
      ) {
    switch (status.toLowerCase()) {
      case 'new':
        return 'Accept order';

      case 'preparing':
        return 'Mark ready for pickup';

      default:
        return null;
    }
  }

  // ==============================================================
  // LIVE ROUTE TRACKING CARD
  // ==============================================================

  Widget _buildLiveRouteTrackingCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DeliveryRouteModel?>(
      stream: PharmacyTrackingService().activeRouteForPharmacyStream(
        pharmacyId: widget.pharmacyId,
      ),
      builder: (context, snapshot) {
        final route = snapshot.data;
        final hasActiveRoute = route != null && route.isActive;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PharmacyLiveTrackingScreen(
                  pharmacyId: widget.pharmacyId,
                  routeId: route?.id,
                  riderId: route?.riderId ?? '',
                  riderName: route?.riderName ?? '',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasActiveRoute
                  ? (isDark
                      ? const Color(0xFF15301D)
                      : Colors.green.shade50)
                  : Theme.of(context).cardColor,
              border: Border.all(
                color: hasActiveRoute
                    ? (isDark
                        ? const Color(0xFF1D322A)
                        : Colors.green.shade200)
                    : (isDark
                        ? const Color(0xFF1D322A)
                        : Colors.grey.shade200),
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasActiveRoute
                        ? const Color(0xFF0F7253)
                        : (isDark
                            ? const Color(0xFF1D322A)
                            : Colors.grey.shade100),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.two_wheeler_rounded,
                    color: hasActiveRoute ? Colors.white : cs.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Live Route Tracking',
                            style: TextStyle(
                              color: cs.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (hasActiveRoute) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F7253),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasActiveRoute
                            ? 'Rider: ${route.riderName.isNotEmpty ? route.riderName : "Assigned Rider"} • ${route.deliveredCount}/${route.totalStops} stops completed'
                            : 'Monitor live rider positions & delivery sequence',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: cs.onSurfaceVariant,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}