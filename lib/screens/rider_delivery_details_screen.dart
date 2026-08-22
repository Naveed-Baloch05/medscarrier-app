import 'package:flutter/material.dart';

// IMPORTANT:
// This connects the delivery details screen to the
// separate QR scanner screen.
import 'rider_qr_scanner_screen.dart';

class RiderDeliveryDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> delivery;

  const RiderDeliveryDetailsScreen({
    super.key,
    required this.delivery,
  });

  @override
  State<RiderDeliveryDetailsScreen> createState() =>
      _RiderDeliveryDetailsScreenState();
}

class _RiderDeliveryDetailsScreenState
    extends State<RiderDeliveryDetailsScreen> {
  late Map<String, dynamic> delivery;

  bool qrScanned = false;
  bool medicineConfirmed = false;

  final TextEditingController recipientController =
  TextEditingController();

  final List<Offset> signaturePoints = [];

  @override
  void initState() {
    super.initState();

    delivery = Map<String, dynamic>.from(widget.delivery);

    // Support the existing data format.
    if (delivery['status'] == 'Ready') {
      delivery['status'] = 'Assigned';
    }

    if (delivery['status'] == 'Delivered') {
      delivery['status'] = 'Completed';
    }

    // If this delivery already contains a pickup QR value,
    // consider the QR step completed.
    if (delivery['pickupQrValue'] != null &&
        delivery['pickupQrValue'].toString().trim().isNotEmpty) {
      qrScanned = true;
    }
  }

  @override
  void dispose() {
    recipientController.dispose();
    super.dispose();
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
    final isDark = theme.brightness == Brightness.dark;

    final String status =
        delivery['status']?.toString() ?? 'Assigned';

    final bool controlled =
        delivery['controlled'] == true ||
            delivery['controlledDrug'] == true;

    final bool coldChain =
        delivery['coldChain'] == true;

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            30,
          ),
          children: [
            _buildOrderHeader(
              context,
              status,
            ),

            const SizedBox(height: 14),

            _buildRouteCard(
              context,
              isDark,
            ),

            const SizedBox(height: 14),

            _buildDeliveryInfoCard(
              context,
              isDark,
            ),

            if (controlled || coldChain) ...[
              const SizedBox(height: 14),
              _buildRequirementsCard(
                context,
                isDark,
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
      ),
    );
  }

  // ============================================================
  // ORDER HEADER
  // ============================================================

  Widget _buildOrderHeader(
      BuildContext context,
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
                  delivery['id']?.toString() ??
                      delivery['orderId']?.toString() ??
                      '#MC-0000',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  delivery['pharmacy']?.toString() ??
                      'Pharmacy',
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
      bool isDark,
      ) {
    final String pickup =
        delivery['pickup']?.toString() ??
            'Pickup address';

    final String dropoff =
        delivery['dropoff']?.toString() ??
            'Drop-off address';

    final String pharmacy =
        delivery['pharmacy']?.toString() ??
            'Pharmacy';

    final String customer =
        delivery['customer']?.toString() ??
            'Customer';

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
      bool isDark,
      ) {
    final String distance =
        delivery['distance']?.toString() ?? '—';

    final String time =
        delivery['time']?.toString() ??
            delivery['eta']?.toString() ??
            '—';

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
      bool isDark,
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
          label: 'Scan Pickup QR Code',
          onPressed: () {
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
            _setStatus('On the Way');
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
          delivery: delivery,
        ),
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      _handlePickupQrScanned(result);
    }
  }

  // ============================================================
  // QR SCANNED CALLBACK
  // ============================================================

  void _handlePickupQrScanned(
      String qrValue,
      ) {
    final String cleanQrValue = qrValue.trim();

    if (cleanQrValue.isEmpty) {
      _showErrorMessage(
        context,
        'Invalid QR code.',
      );
      return;
    }

    // Store the scanned QR value.
    delivery['pickupQrValue'] = cleanQrValue;

    // Mark QR as scanned.
    qrScanned = true;

    // Move delivery to Picked Up.
    setState(() {
      delivery['status'] = 'Picked Up';
    });

    _showSuccessMessage(
      context,
      'Pickup QR scanned successfully.',
    );
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
                            Colors.grey.shade50,
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                              borderSide:
                              BorderSide.none,
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
                            Colors.grey.shade50,
                            borderRadius:
                            BorderRadius
                                .circular(
                              12,
                            ),
                            border: Border.all(
                              color: Colors
                                  .grey.shade300,
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
                                      Offset.infinite,
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
                                  child: Text(
                                    'Sign here',
                                    style:
                                    TextStyle(
                                      color:
                                      Colors.grey,
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
                            Colors.white,
                            disabledBackgroundColor:
                            Colors
                                .grey.shade300,
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
    required VoidCallback onPressed,
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
  // STATUS UPDATE
  // ============================================================

  void _setStatus(
      String status,
      ) {
    setState(() {
      delivery['status'] = status;
    });

    _showSuccessMessage(
      context,
      'Delivery status updated to $status.',
    );
  }

  // ============================================================
  // COMPLETE DELIVERY
  // ============================================================

  void _completeDelivery() {
    setState(() {
      delivery['status'] = 'Completed';
    });

    _showSuccessMessage(
      context,
      'Delivery completed successfully.',
    );
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

  // ============================================================
  // SUCCESS MESSAGE
  // ============================================================

  void _showSuccessMessage(
      BuildContext context,
      String message,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showErrorMessage(
      BuildContext context,
      String message,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
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