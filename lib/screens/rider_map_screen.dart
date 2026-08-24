import 'package:flutter/material.dart';

class RiderMapScreen extends StatefulWidget {
  const RiderMapScreen({super.key});

  @override
  State<RiderMapScreen> createState() => _RiderMapScreenState();
}

class _RiderMapScreenState extends State<RiderMapScreen> {
  // 0 = navigating, 1 = arrived, 2 = completed
  int _deliveryStep = 0;
  bool isNavigating = false;

  final String orderId = '#MC-4818';
  final String pharmacy = 'Camden Pharmacy';
  final String pharmacyAddress = 'Camden High St, NW1';
  final String customer = 'Alessia Rossi';
  final String customerAddress = 'Primrose Hill, NW3';
  final String distance = '3.2 km';
  final String eta = '12 min';

  List<Offset?> _signaturePoints = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildMapArea(context, isDark),
            ),

            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  _buildMapButton(
                    context,
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 19,
                            color: isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _deliveryStep == 0
                                  ? 'Navigating to Customer'
                                  : _deliveryStep == 1
                                      ? 'Arrived at Customer'
                                      : 'Delivery Completed',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _deliveryStep == 2 ? const Color(0xFF32C787) : const Color(0xFF7C4DFF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _deliveryStep == 0
                                ? 'On the way'
                                : _deliveryStep == 1
                                    ? 'Arrived'
                                    : 'Done',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _deliveryStep == 2 ? const Color(0xFF32C787) : const Color(0xFF7C4DFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_deliveryStep == 0)
              Positioned(
                right: 16,
                bottom: 350,
                child: _buildMapButton(
                  context,
                  icon: Icons.my_location_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Current location selected'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: _deliveryStep == 2
                  ? _buildCompletedCard(context, isDark)
                  : _deliveryStep == 1
                      ? _buildArrivedCard(context, isDark)
                      : _buildDeliveryBottomCard(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAP AREA
  // ============================================================

  Widget _buildMapArea(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18231E) : const Color(0xFFE8EEE9),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _MapPainter(isDark: isDark)),
          ),
          Positioned(
            left: 95,
            top: 230,
            child: _buildMapMarker(icon: Icons.navigation_rounded, color: const Color(0xFF0F7253), label: 'You'),
          ),
          Positioned(
            right: 92,
            top: 155,
            child: _buildMapMarker(icon: Icons.storefront, color: const Color(0xFF32C787), label: 'Pickup'),
          ),
          Positioned(
            right: 72,
            bottom: 305,
            child: _buildMapMarker(icon: Icons.location_on_rounded, color: const Color(0xFF7C4DFF), label: 'Drop-off'),
          ),
          Positioned(
            top: 118,
            left: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.route_outlined, size: 16, color: Color(0xFF7C4DFF)),
                  const SizedBox(width: 6),
                  Text(
                    '$distance • $eta',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Icon(icon, size: 21),
        ),
      ),
    );
  }

  Widget _buildMapMarker({required IconData icon, required Color color, required String label}) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 8)],
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 5)],
          ),
          child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.black)),
        ),
      ],
    );
  }

  // ============================================================
  // STEP 1: NAVIGATING TO CUSTOMER
  // ============================================================

  Widget _buildDeliveryBottomCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(orderId, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 7, color: Color(0xFF7C4DFF)),
                    SizedBox(width: 5),
                    Text('On the way', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF7C4DFF))),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildLocationRow(
            icon: Icons.storefront,
            iconColor: const Color(0xFF32C787),
            title: 'PICKUP',
            name: pharmacy,
            address: pharmacyAddress,
          ),

          Padding(
            padding: const EdgeInsets.only(left: 16, top: 3, bottom: 3),
            child: Column(
              children: List.generate(
                3,
                (_) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  width: 2,
                  height: 4,
                  color: Colors.grey.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),

          _buildLocationRow(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFF7C4DFF),
            title: 'DROP-OFF',
            name: customer,
            address: customerAddress,
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1814) : const Color(0xFFF6F8F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(distance, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      const Text('Distance', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.grey.withValues(alpha: 0.20)),
                Expanded(
                  child: Column(
                    children: [
                      Text(eta, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      const Text('Estimated time', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _deliveryStep = 1;
                  isNavigating = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F7253),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.location_on_outlined, size: 19),
              label: const Text('Arrived at Customer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: () => _showDeliveryInformation(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
              child: Text(
                'View Delivery Details',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 2: ARRIVED – CUSTOMER NAME + SIGNATURE
  // ============================================================

  Widget _buildArrivedCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(orderId, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8A920).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 7, color: Color(0xFFE8A920)),
                    SizedBox(width: 5),
                    Text('Arrived', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFE8A920))),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF15301D) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1D322A) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, size: 22, color: Color(0xFF0F7253)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Customer', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(customer, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(customerAddress, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF32C787).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Delivering', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF32C787))),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Text('Customer Signature', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
              const Spacer(),
              if (_signaturePoints.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _signaturePoints.clear()),
                  child: Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade400)),
                ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1814) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _signaturePoints.isNotEmpty
                    ? cs.primary.withValues(alpha: 0.4)
                    : isDark
                        ? const Color(0xFF2A3A33)
                        : Colors.grey.shade300,
                width: _signaturePoints.isNotEmpty ? 1.5 : 1,
              ),
            ),
            child: _signaturePoints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.draw_outlined, size: 28, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 4),
                        Text('Tap and draw to sign', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _signaturePoints.add(details.localPosition);
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _signaturePoints.add(details.localPosition);
                        });
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _signaturePoints.add(null);
                        });
                      },
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _SignaturePainter(points: _signaturePoints),
                      ),
                    ),
                  ),
          ),

          if (_signaturePoints.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Customer must sign before completing delivery',
                style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
              ),
            ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _signaturePoints.isEmpty
                  ? null
                  : () {
                      setState(() => _deliveryStep = 2);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F7253),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                disabledForegroundColor: Colors.grey,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 19),
              label: const Text('Complete Delivery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP 3: DELIVERY COMPLETED
  // ============================================================

  Widget _buildCompletedCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF32C787).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, size: 40, color: Color(0xFF32C787)),
          ),

          const SizedBox(height: 16),

          const Text(
            'Delivery Completed!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 6),

          Text(
            'Order $orderId has been delivered to $customer',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1814) : const Color(0xFFF6F8F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _completedDetailRow(Icons.receipt_long_outlined, 'Order', orderId),
                const SizedBox(height: 10),
                _completedDetailRow(Icons.person_outline, 'Customer', customer),
                const SizedBox(height: 10),
                _completedDetailRow(Icons.location_on_outlined, 'Address', customerAddress),
                const SizedBox(height: 10),
                _completedDetailRow(Icons.timer_outlined, 'Delivery Time', '24 min'),
              ],
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F7253),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.home_outlined, size: 19),
              label: const Text('Back to Home', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _completedDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const Spacer(),
        Flexible(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // ============================================================
  // SHARED WIDGETS
  // ============================================================

  Widget _buildLocationRow({required IconData icon, required Color iconColor, required String title, required String name, required String address}) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.10), shape: BoxShape.circle),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 1),
              Text(address, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeliveryInformation(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.30), borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Delivery Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                _buildBottomDetailRow(Icons.receipt_long_outlined, 'Order', orderId),
                _buildBottomDetailRow(Icons.storefront, 'Pharmacy', pharmacy),
                _buildBottomDetailRow(Icons.person_outline, 'Customer', customer),
                _buildBottomDetailRow(Icons.location_on_outlined, 'Drop-off', customerAddress),
                _buildBottomDetailRow(Icons.route_outlined, 'Distance', distance),
                _buildBottomDetailRow(Icons.access_time_outlined, 'ETA', eta),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7253),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 17, color: const Color(0xFF0F7253)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SIGNATURE PAINTER
// ============================================================

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F7253)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => oldDelegate.points != points;
}

// ============================================================
// MAP PAINTER
// ============================================================

class _MapPainter extends CustomPainter {
  final bool isDark;

  _MapPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = isDark ? const Color(0xFF18231E) : const Color(0xFFE8EEE9);

    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF26342D) : const Color(0xFFD3DDD6)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    final roadPaintSmall = Paint()
      ..color = isDark ? const Color(0xFF33443A) : const Color(0xFFDEE6E0)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(-50, size.height * 0.28)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.18, size.width + 50, size.height * 0.35);

    final path2 = Path()
      ..moveTo(size.width * 0.15, -30)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.40, size.width * 0.25, size.height + 30);

    final path3 = Path()
      ..moveTo(-20, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.52, size.width + 30, size.height * 0.75);

    canvas.drawPath(path1, roadPaint);
    canvas.drawPath(path2, roadPaint);
    canvas.drawPath(path3, roadPaintSmall);

    final routePaint = Paint()
      ..color = const Color(0xFF7C4DFF)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final route = Path()
      ..moveTo(size.width * 0.20, size.height * 0.47)
      ..quadraticBezierTo(size.width * 0.40, size.height * 0.28, size.width * 0.62, size.height * 0.32)
      ..quadraticBezierTo(size.width * 0.77, size.height * 0.40, size.width * 0.78, size.height * 0.63);

    canvas.drawPath(route, routePaint);

    final blockPaint = Paint()
      ..color = isDark ? const Color(0xFF202D26) : const Color(0xFFDDE6DF);

    final blocks = [
      Rect.fromLTWH(25, 90, 75, 45),
      Rect.fromLTWH(170, 80, 90, 52),
      Rect.fromLTWH(300, 100, 75, 48),
      Rect.fromLTWH(40, 330, 95, 55),
      Rect.fromLTWH(200, 350, 100, 48),
      Rect.fromLTWH(330, 300, 80, 60),
    ];

    for (final block in blocks) {
      canvas.drawRRect(RRect.fromRectAndRadius(block, const Radius.circular(8)), blockPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => oldDelegate.isDark != isDark;
}
