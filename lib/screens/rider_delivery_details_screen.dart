import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/rider_delivery_details/rider_delivery_details_bloc.dart';
import '../bloc/rider_delivery_details/rider_delivery_details_event.dart';
import '../bloc/rider_delivery_details/rider_delivery_details_state.dart';
import '../models/order_model.dart';
import 'rider_qr_scanner_screen.dart';

class RiderDeliveryDetailsScreen extends StatefulWidget {
  const RiderDeliveryDetailsScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  final String orderId;
  final OrderModel? initialOrder;

  @override
  State<RiderDeliveryDetailsScreen> createState() =>
      _RiderDeliveryDetailsScreenState();
}

class _RiderDeliveryDetailsScreenState
    extends State<RiderDeliveryDetailsScreen> {
  late final RiderDeliveryDetailsBloc _bloc;

  bool medicineConfirmed = false;

  final TextEditingController recipientController =
      TextEditingController();

  final List<Offset> signaturePoints = [];

  String get _orderId => widget.orderId;

  @override
  void initState() {
    super.initState();
    _bloc = RiderDeliveryDetailsBloc();
    _bloc.add(SubscribeToOrder(_orderId));
  }

  @override
  void dispose() {
    recipientController.dispose();
    _bloc.close();
    super.dispose();
  }

  OrderModel get _order {
    final s = _bloc.state;
    if (s is RiderDeliveryDetailsLoaded) return s.order;
    if (s is RiderDeliveryDetailsUpdating) return s.order;
    if (s is RiderDeliveryDetailsOperationSuccess) return s.order;
    if (s is RiderDeliveryDetailsError && s.order != null) return s.order!;
    if (widget.initialOrder != null) return widget.initialOrder!;
    throw StateError('Order not loaded');
  }

  bool get _qrAlreadyScanned {
    final s = _bloc.state;
    if (s is RiderDeliveryDetailsLoaded) return s.qrAlreadyScanned;
    if (s is RiderDeliveryDetailsUpdating) return s.qrAlreadyScanned;
    if (s is RiderDeliveryDetailsOperationSuccess) return s.qrAlreadyScanned;
    return false;
  }

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primary = Color(0xFF0F7253);
  static const Color green = Color(0xFF32C787);
  static const Color purple = Color(0xFF7C4DFF);
  static const Color orange = Color(0xFFFFA726);
  static const Color blue = Color(0xFF42A5F5);
  static const Color cyan = Color(0xFF4DD0E1);

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Delivery Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: BlocListener<RiderDeliveryDetailsBloc, RiderDeliveryDetailsState>(
        bloc: _bloc,
        listener: (context, state) {
          if (state is RiderDeliveryDetailsOperationSuccess) {
            _showMessage(context, state.message, isError: false);
          } else if (state is RiderDeliveryDetailsError &&
              state.message.isNotEmpty) {
            _showMessage(context, state.message, isError: true);
          }
        },
        child: BlocBuilder<RiderDeliveryDetailsBloc, RiderDeliveryDetailsState>(
          bloc: _bloc,
          builder: (context, state) {
          if (state is RiderDeliveryDetailsInitial ||
              state is RiderDeliveryDetailsLoading) {
            return _buildLoading(context);
          }

          final OrderModel order;
          try {
            order = _order;
          } catch (_) {
            return const _ErrorView(message: 'Order not loaded.');
          }

          if (state is RiderDeliveryDetailsError && state.order == null) {
            return _ErrorView(message: state.message);
          }

          final String status = _normalizedStatus(order.status);
          final bool controlled = order.controlledDrug;
          final bool coldChain = order.coldChain;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                30,
              ),
              children: [
                _buildOrderHeader(context, order, status),

                const SizedBox(height: 14),

                _buildRouteCard(context, order),

                const SizedBox(height: 14),

                _buildDeliveryInfoCard(context, order),

                if (controlled || coldChain) ...[
                  const SizedBox(height: 14),
                  _buildRequirementsCard(
                    context,
                    controlled,
                    coldChain,
                  ),
                ],

                const SizedBox(height: 18),

                _buildActionSection(
                  context,
                  status,
                  controlled,
                  coldChain,
                ),
              ],
            ),
          );
          },
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message,
      {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _normalizedStatus(String status) {
    switch (status) {
      case 'Ready':
        return 'Assigned';
      case 'Delivered':
        return 'Completed';
      default:
        return status;
    }
  }

  Widget _buildLoading(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: primary),
          const SizedBox(height: 16),
          Text(
            'Loading delivery...',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER HEADER
  // ============================================================

  Widget _buildOrderHeader(
    BuildContext context,
    OrderModel order,
    String status,
  ) {
    final theme = Theme.of(context);
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: primary,
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
                  '#${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  order.pharmacyName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          _buildStatusBadge(
            context,
            status,
            color,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(
    BuildContext context,
    String status,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 5),

          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROUTE CARD
  // ============================================================

  Widget _buildRouteCard(
    BuildContext context,
    OrderModel order,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String pickup = order.pickupAddress.isEmpty
        ? 'Pickup address'
        : order.pickupAddress;

    final String dropoff = order.dropoffAddress.isEmpty
        ? 'Drop-off address'
        : order.dropoffAddress;

    final String pharmacy = order.pharmacyName.isEmpty
        ? 'Pharmacy'
        : order.pharmacyName;

    final String customer = order.customerName.isEmpty
        ? 'Customer'
        : order.customerName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Route',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 16),

          // PICKUP
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _routeIcon(
                Icons.storefront_outlined,
                green,
                isDark,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PICKUP',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey,
                        letterSpacing: 0.4,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      pharmacy,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      pickup,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ROUTE CONNECTOR
          Padding(
            padding: const EdgeInsets.only(
              left: 19,
              top: 6,
              bottom: 6,
            ),
            child: Container(
              width: 2,
              height: 26,
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.30),
                borderRadius:
                    BorderRadius.circular(2),
              ),
            ),
          ),

          // DROP OFF
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _routeIcon(
                Icons.location_on_outlined,
                purple,
                isDark,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DROP-OFF',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey,
                        letterSpacing: 0.4,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      customer,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      dropoff,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeIcon(
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 19,
        color: color,
      ),
    );
  }

  // ============================================================
  // DELIVERY INFORMATION
  // ============================================================

  Widget _buildDeliveryInfoCard(
    BuildContext context,
    OrderModel order,
  ) {
    final String distance = order.distance?.isNotEmpty == true
        ? order.distance!
        : '—';

    final String time = order.estimatedTime?.isNotEmpty == true
        ? order.estimatedTime!
        : (order.deliveryTimeMinutes != null
            ? '${order.deliveryTimeMinutes} min'
            : '—');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _infoItem(
              Icons.route_outlined,
              distance,
              'Distance',
            ),
          ),

          Container(
            width: 1,
            height: 38,
            color: Colors.grey.withValues(
              alpha: 0.20,
            ),
          ),

          Expanded(
            child: _infoItem(
              Icons.access_time_outlined,
              time,
              'ETA',
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),

        const SizedBox(height: 5),

        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REQUIREMENTS
  // ============================================================

  Widget _buildRequirementsCard(
    BuildContext context,
    bool controlled,
    bool coldChain,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Requirements',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          if (controlled)
            _requirementTile(
              icon: Icons.verified_user_outlined,
              title: 'Controlled Drug',
              subtitle:
                  'Recipient signature is required at handover.',
              color: orange,
            ),

          if (controlled && coldChain)
            const SizedBox(height: 8),

          if (coldChain)
            _requirementTile(
              icon: Icons.ac_unit_rounded,
              title: 'Cold-chain Medicine',
              subtitle:
                  'Keep medicine between 2–8°C.',
              color: cyan,
            ),
        ],
      ),
    );
  }

  Widget _requirementTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: color,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(
                      alpha: 0.80,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION SECTION
  // ============================================================

  Widget _buildActionSection(
    BuildContext context,
    String status,
    bool controlled,
    bool coldChain,
  ) {
    switch (status) {
      case 'Assigned':
        return _buildAssignedAction(context);

      case 'Picked Up':
        return _buildPickedUpAction(context);

      case 'On the Way':
      case 'On the way':
        return _buildOnTheWayAction(
          context,
          controlled,
        );

      case 'Completed':
      case 'Delivered':
        return _buildCompletedState(context);

      default:
        return _buildAssignedAction(context);
    }
  }

  // ============================================================
  // ASSIGNED
  // ============================================================

  Widget _buildAssignedAction(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Pickup Action',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Navigate to the pharmacy and scan the pickup QR code when you arrive.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 14),

        _primaryButton(
          icon: Icons.navigation_outlined,
          label: 'Navigate to Pharmacy',
          onPressed: () {
            _showNavigationMessage(
              context,
              'Opening navigation to pharmacy...',
            );
          },
        ),

        const SizedBox(height: 10),

        _secondaryButton(
          icon: Icons.qr_code_scanner_rounded,
          label: _qrAlreadyScanned
              ? 'Pickup QR Scanned'
              : 'Scan Pickup QR Code',
          onPressed: _qrAlreadyScanned
              ? null
              : () {
                  _openQrScanner(context);
                },
        ),
      ],
    );
  }

  // ============================================================
  // PICKED UP
  // ============================================================

  Widget _buildPickedUpAction(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _stepCompleteCard(
          icon: Icons.check_circle_rounded,
          title: 'Pickup confirmed',
          subtitle:
              'The medicine has been picked up from the pharmacy.',
          color: green,
        ),

        const SizedBox(height: 14),

        _primaryButton(
          icon: Icons.navigation_outlined,
          label: 'Navigate to Customer',
          onPressed: () {
            _showNavigationMessage(
              context,
              'Opening navigation to customer...',
            );
          },
        ),

        const SizedBox(height: 10),

        _secondaryButton(
          icon: Icons.local_shipping_outlined,
          label: 'Start Delivery',
          onPressed: () {
            context
                .read<RiderDeliveryDetailsBloc>()
                .add(StartDelivery(_orderId));
          },
        ),
      ],
    );
  }

  // ============================================================
  // ON THE WAY
  // ============================================================

  Widget _buildOnTheWayAction(
    BuildContext context,
    bool controlled,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _stepCompleteCard(
          icon: Icons.local_shipping_rounded,
          title: 'Delivery is on the way',
          subtitle:
              'Proceed to the customer drop-off location.',
          color: purple,
        ),

        const SizedBox(height: 14),

        _primaryButton(
          icon: Icons.navigation_outlined,
          label: 'Navigate to Customer',
          onPressed: () {
            _showNavigationMessage(
              context,
              'Opening navigation to customer...',
            );
          },
        ),

        const SizedBox(height: 10),

        _secondaryButton(
          icon: Icons.assignment_turned_in_outlined,
          label: 'Complete Delivery',
          onPressed: () {
            _showCompletionSheet(
              context,
              controlled,
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // COMPLETED
  // ============================================================

  Widget _buildCompletedState(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: green.withValues(alpha: 0.20),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: green,
            size: 25,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Completed',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: green,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'This delivery has been successfully completed.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONNECT TO SEPARATE QR SCANNER
  // ============================================================

  void _openQrScanner(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => RiderQrScannerScreen(
          orderId: _orderId,
        ),
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      if (!mounted) return;
      _bloc.add(
        VerifyPickupQR(
          orderId: _orderId,
          qrValue: result,
        ),
      );
    }
  }

  // ============================================================
  // COMPLETION SHEET
  // ============================================================

  void _showCompletionSheet(
    BuildContext context,
    bool controlled,
  ) {
    medicineConfirmed = false;
    recipientController.clear();
    signaturePoints.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            final bool hasRecipient =
                recipientController.text
                    .trim()
                    .isNotEmpty;

            final bool hasSignature =
                signaturePoints.length > 2;

            final bool canComplete =
                !controlled ||
                    (
                        hasRecipient &&
                            hasSignature &&
                            medicineConfirmed
                    );

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom:
                      MediaQuery.of(context)
                          .viewInsets
                          .bottom +
                          20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration:
                              BoxDecoration(
                                color: Colors.grey
                                    .withValues(
                                  alpha: 0.30,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(4),
                              ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Complete Delivery',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Confirm the handover before completing this delivery.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      if (controlled) ...[
                        const SizedBox(height: 18),

                        _completionSectionTitle(
                          'Recipient Name',
                        ),

                        const SizedBox(height: 7),

                        TextField(
                          controller:
                              recipientController,
                          onChanged: (_) {
                            setSheetState(
                                  () {},
                            );
                          },
                          decoration:
                              InputDecoration(
                                hintText:
                                    'Enter recipient name',
                                prefixIcon:
                                    const Icon(
                                      Icons.person_outline,
                                    ),
                                filled: true,
                                fillColor:
                                    Colors.grey
                                        .shade50,
                                border:
                                    OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                            12,
                                          ),
                                      borderSide:
                                          BorderSide
                                              .none,
                                    ),
                              ),
                        ),

                        const SizedBox(height: 16),

                        _completionSectionTitle(
                          'Recipient Signature',
                        ),

                        const SizedBox(height: 7),

                        Container(
                          height: 130,
                          width: double.infinity,
                          decoration:
                              BoxDecoration(
                                color:
                                    Colors.grey
                                        .shade50,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                          12,
                                        ),
                                border: Border.all(
                                  color: Colors
                                      .grey
                                      .shade300,
                                ),
                              ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius
                                    .circular(
                                  12,
                                ),
                            child:
                                GestureDetector(
                                  onPanStart:
                                      (details) {
                                    setSheetState(
                                          () {
                                        signaturePoints
                                            .add(
                                          details
                                              .localPosition,
                                        );
                                      },
                                    );
                                  },
                                  onPanUpdate:
                                      (details) {
                                    setSheetState(
                                          () {
                                        signaturePoints
                                            .add(
                                          details
                                              .localPosition,
                                        );
                                      },
                                    );
                                  },
                                  onPanEnd: (_) {
                                    setSheetState(
                                          () {
                                        signaturePoints
                                            .add(
                                          Offset
                                              .infinite,
                                        );
                                      },
                                    );
                                  },
                                  child:
                                      CustomPaint(
                                        painter:
                                            _SignaturePainter(
                                              points:
                                                  signaturePoints,
                                            ),
                                        child:
                                            const Center(
                                              child:
                                                  Text(
                                                    'Sign here',
                                                    style:
                                                        TextStyle(
                                                          color:
                                                              Colors
                                                                  .grey,
                                                          fontSize:
                                                              12,
                                                        ),
                                                  ),
                                            ),
                                      ),
                                ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Align(
                          alignment:
                              Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setSheetState(
                                    () {
                                  signaturePoints
                                      .clear();
                                },
                              );
                            },
                            child:
                                const Text(
                                  'Clear Signature',
                                ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        CheckboxListTile(
                          contentPadding:
                              EdgeInsets.zero,
                          value:
                              medicineConfirmed,
                          onChanged:
                              (value) {
                            setSheetState(
                                  () {
                                medicineConfirmed =
                                    value ??
                                        false;
                              },
                            );
                          },
                          title:
                              const Text(
                                'Medicine handed over successfully',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                          subtitle:
                              const Text(
                                'Confirm the correct medicine was handed to the recipient.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      Colors.grey,
                                ),
                              ),
                          controlAffinity:
                              ListTileControlAffinity
                                  .leading,
                        ),
                      ],

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child:
                            ElevatedButton.icon(
                              onPressed:
                                  canComplete
                                      ? () {
                                    Navigator.pop(
                                      sheetContext,
                                    );

                                    _completeDelivery();
                                  }
                                      : null,
                              style:
                                  ElevatedButton
                                      .styleFrom(
                                        backgroundColor:
                                            primary,
                                        foregroundColor:
                                            Colors
                                                .white,
                                        disabledBackgroundColor:
                                            Colors
                                                .grey
                                                .shade300,
                                        elevation: 0,
                                        shape:
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                        12,
                                                      ),
                                            ),
                                      ),
                              icon: const Icon(
                                Icons.check_rounded,
                              ),
                              label: const Text(
                                'Complete Delivery',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w700,
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
      },
    );
  }

  // ============================================================
  // COMPLETION HELPERS
  // ============================================================

  Widget _completionSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  // ============================================================
  // STEP COMPLETE CARD
  // ============================================================

  Widget _stepCompleteCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 23,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRIMARY BUTTON
  // ============================================================

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
        icon: Icon(
          icon,
          size: 19,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECONDARY BUTTON
  // ============================================================

  Widget _secondaryButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.cardColor,
          foregroundColor:
              theme.colorScheme.onSurface,
          side: BorderSide(
            color: Colors.grey.withValues(
              alpha: 0.25,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
        icon: Icon(
          icon,
          size: 19,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'Assigned':
        return orange;

      case 'Picked Up':
        return blue;

      case 'On the Way':
      case 'On the way':
        return purple;

      case 'Completed':
      case 'Delivered':
        return green;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // COMPLETE DELIVERY
  // ============================================================

  void _completeDelivery() {
    final List<Map<String, double>>? signature = _encodeSignature();
    context.read<RiderDeliveryDetailsBloc>().add(
          CompleteDelivery(
            orderId: _orderId,
            recipientName: recipientController.text.trim(),
            signaturePoints: signature,
            medicineHandoverConfirmed: medicineConfirmed,
          ),
        );
  }

  List<Map<String, double>>? _encodeSignature() {
    if (signaturePoints.length <= 2) return null;
    return signaturePoints
        .where((p) => p != Offset.infinite)
        .map((p) => <String, double>{
              'x': p.dx,
              'y': p.dy,
            })
        .toList();
  }

  // ============================================================
  // NAVIGATION MESSAGE
  // ============================================================

  void _showNavigationMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ================================================================
// ERROR VIEW
// ================================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message.isEmpty ? 'Unable to load delivery.' : message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SIGNATURE PAINTER
// ================================================================

class _SignaturePainter extends CustomPainter {
  final List<Offset> points;

  _SignaturePainter({
    required this.points,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = const Color(0xFF191C1B)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (
      int i = 0;
      i < points.length - 1;
      i++
    ) {
      final current = points[i];
      final next = points[i + 1];

      if (current == Offset.infinite ||
          next == Offset.infinite) {
        continue;
      }

      canvas.drawLine(
        current,
        next,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _SignaturePainter oldDelegate,
  ) {
    return oldDelegate.points != points;
  }
}
