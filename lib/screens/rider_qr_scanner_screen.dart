import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class RiderQrScannerScreen extends StatefulWidget {
  final Map<String, dynamic> delivery;

  const RiderQrScannerScreen({
    super.key,
    required this.delivery,
  });

  @override
  State<RiderQrScannerScreen> createState() =>
      _RiderQrScannerScreenState();
}

class _RiderQrScannerScreenState extends State<RiderQrScannerScreen> {
  static const Color primary = Color(0xFF0F7253);
  static const Color green = Color(0xFF32C787);

  late final MobileScannerController scannerController;

  bool isProcessing = false;
  bool torchEnabled = false;

  String? scannedValue;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    scannerController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 800,
      formats: const [
        BarcodeFormat.qrCode,
      ],
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ====================================================
            // CAMERA
            // ====================================================

            Positioned.fill(
              child: MobileScanner(
                controller: scannerController,
                onDetect: _onQrDetected,
                errorBuilder: _buildScannerError,
              ),
            ),

            // ====================================================
            // DARK OVERLAY
            // ====================================================

            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ScannerOverlayPainter(),
                ),
              ),
            ),

            // ====================================================
            // TOP BAR
            // ====================================================

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(context),
            ),

            // ====================================================
            // SCANNER AREA
            // ====================================================

            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: _buildScannerFrame(),
                ),
              ),
            ),

            // ====================================================
            // SCANNER INSTRUCTIONS
            // ====================================================

            Positioned(
              left: 24,
              right: 24,
              bottom: 145,
              child: _buildInstructions(),
            ),

            // ====================================================
            // BOTTOM CONTROLS
            // ====================================================

            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: _buildBottomControls(),
            ),

            // ====================================================
            // PROCESSING
            // ====================================================

            if (isProcessing)
              Positioned.fill(
                child: _buildProcessingOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(BuildContext context) {
    final String deliveryId =
        widget.delivery['id']?.toString() ??
            widget.delivery['orderId']?.toString() ??
            '#MC-0000';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.black.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // BACK BUTTON
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // TITLE
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan Pickup QR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  deliveryId,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.75,
                    ),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // FLASH BUTTON
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _toggleTorch,
              icon: Icon(
                torchEnabled
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCANNER FRAME
  // ============================================================

  Widget _buildScannerFrame() {
    return SizedBox(
      width: 270,
      height: 270,
      child: Stack(
        children: [
          // TOP LEFT
          Positioned(
            top: 0,
            left: 0,
            child: _corner(
              top: true,
              left: true,
            ),
          ),

          // TOP RIGHT
          Positioned(
            top: 0,
            right: 0,
            child: _corner(
              top: true,
              left: false,
            ),
          ),

          // BOTTOM LEFT
          Positioned(
            bottom: 0,
            left: 0,
            child: _corner(
              top: false,
              left: true,
            ),
          ),

          // BOTTOM RIGHT
          Positioned(
            bottom: 0,
            right: 0,
            child: _corner(
              top: false,
              left: false,
            ),
          ),

          // SCAN LINE
          if (!isProcessing)
            const _ScannerLine(),
        ],
      ),
    );
  }

  Widget _corner({
    required bool top,
    required bool left,
  }) {
    const double length = 35;
    const double thickness = 4;

    return SizedBox(
      width: length,
      height: length,
      child: CustomPaint(
        painter: _CornerPainter(
          color: green,
          top: top,
          left: left,
          thickness: thickness,
        ),
      ),
    );
  }

  // ============================================================
  // INSTRUCTIONS
  // ============================================================

  Widget _buildInstructions() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'Place the pharmacy QR code inside the frame',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 9),

        Text(
          'The QR code will be scanned automatically.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 11,
          ),
        ),

        if (errorMessage != null) ...[
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // BOTTOM CONTROLS
  // ============================================================

  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // SWITCH CAMERA
        _bottomControl(
          icon: Icons.flip_camera_ios_rounded,
          label: 'Switch',
          onPressed: _switchCamera,
        ),

        const SizedBox(width: 28),

        // CANCEL
        _bottomControl(
          icon: Icons.close_rounded,
          label: 'Cancel',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _bottomControl({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROCESSING OVERLAY
  // ============================================================

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 40,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: primary,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'QR Code Detected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Verifying pickup code...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QR DETECTION
  // ============================================================

  void _onQrDetected(BarcodeCapture capture) {
    if (isProcessing) {
      return;
    }

    if (capture.barcodes.isEmpty) {
      return;
    }

    final Barcode barcode = capture.barcodes.first;

    final String? value = barcode.rawValue;

    if (value == null || value.trim().isEmpty) {
      return;
    }

    _handleScannedQr(value.trim());
  }

  // ============================================================
  // HANDLE QR
  // ============================================================

  Future<void> _handleScannedQr(String value) async {
    if (isProcessing) {
      return;
    }

    setState(() {
      isProcessing = true;
      scannedValue = value;
      errorMessage = null;
    });

    await scannerController.stop();

    // ----------------------------------------------------------
    // TEMPORARY VALIDATION
    // ----------------------------------------------------------
    //
    // For now we accept the scanned QR value and return it to
    // rider_delivery_details_screen.dart.
    //
    // Later, this is where we will connect the real backend
    // validation:
    //
    // QR CODE -> DELIVERY ID -> PHARMACY -> VALID/INVALID
    //
    // ----------------------------------------------------------

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    if (!mounted) {
      return;
    }

    _showScanConfirmation(value);
  }

  // ============================================================
  // SCAN CONFIRMATION
  // ============================================================

  void _showScanConfirmation(String value) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HANDLE
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                const SizedBox(height: 20),

                // SUCCESS ICON
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_rounded,
                    color: primary,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'QR Code Scanned',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'The pickup QR code was successfully scanned.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 14),

                // SCANNED VALUE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SCANNED CODE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        value,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // CONFIRM
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      _returnSuccessfulScan(value);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_rounded,
                    ),
                    label: const Text(
                      'Confirm Pickup',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 9),

                // RESCAN
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);

                      setState(() {
                        isProcessing = false;
                        scannedValue = null;
                        errorMessage = null;
                      });

                      await scannerController.start();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 19,
                    ),
                    label: const Text(
                      'Scan Again',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // RETURN SUCCESSFUL SCAN
  // ============================================================

  void _returnSuccessfulScan(String value) {
    Navigator.pop(
      context,
      value,
    );
  }

  // ============================================================
  // TORCH
  // ============================================================

  Future<void> _toggleTorch() async {
    try {
      await scannerController.toggleTorch();

      if (!mounted) {
        return;
      }

      setState(() {
        torchEnabled = !torchEnabled;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage =
        'Flashlight is not available on this camera.';
      });
    }
  }

  // ============================================================
  // SWITCH CAMERA
  // ============================================================

  Future<void> _switchCamera() async {
    try {
      await scannerController.switchCamera();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage =
        'Unable to switch camera.';
      });
    }
  }

  // ============================================================
  // SCANNER ERROR
  // ============================================================

  Widget _buildScannerError(
      BuildContext context,
      MobileScannerException error,
      ) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: Colors.white,
            size: 54,
          ),

          const SizedBox(height: 16),

          const Text(
            'Camera unavailable',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Please allow camera permission and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          ElevatedButton(
            onPressed: () async {
              try {
                await scannerController.start();
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Try Again',
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SCANNER OVERLAY PAINTER
// ================================================================

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final double frameSize =
    size.width < size.height
        ? size.width * 0.70
        : size.height * 0.45;

    final double left =
        (size.width - frameSize) / 2;

    final double top =
        (size.height - frameSize) / 2;

    final Rect frameRect = Rect.fromLTWH(
      left,
      top,
      frameSize,
      frameSize,
    );

    final Paint overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.52);

    final Path path = Path()
      ..addRect(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          frameRect,
          const Radius.circular(18),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      overlayPaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant _ScannerOverlayPainter oldDelegate,
      ) {
    return false;
  }
}

// ================================================================
// CORNER PAINTER
// ================================================================

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool top;
  final bool left;
  final double thickness;

  _CornerPainter({
    required this.color,
    required this.top,
    required this.left,
    required this.thickness,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path path = Path();

    if (top && left) {
      path.moveTo(
        size.width,
        0,
      );

      path.lineTo(
        0,
        0,
      );

      path.lineTo(
        0,
        size.height,
      );
    } else if (top && !left) {
      path.moveTo(
        0,
        0,
      );

      path.lineTo(
        size.width,
        0,
      );

      path.lineTo(
        size.width,
        size.height,
      );
    } else if (!top && left) {
      path.moveTo(
        0,
        0,
      );

      path.lineTo(
        0,
        size.height,
      );

      path.lineTo(
        size.width,
        size.height,
      );
    } else {
      path.moveTo(
        0,
        size.height,
      );

      path.lineTo(
        size.width,
        size.height,
      );

      path.lineTo(
        size.width,
        0,
      );
    }

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
      covariant _CornerPainter oldDelegate,
      ) {
    return false;
  }
}

// ================================================================
// SCANNER ANIMATION LINE
// ================================================================

class _ScannerLine extends StatefulWidget {
  const _ScannerLine();

  @override
  State<_ScannerLine> createState() =>
      _ScannerLineState();
}

class _ScannerLineState
    extends State<_ScannerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 2,
      ),
    )..repeat(
      reverse: true,
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (
          context,
          child,
          ) {
        return Positioned(
          top: 10 +
              (animationController.value * 250),
          left: 15,
          right: 15,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: const Color(0xFF32C787),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF32C787)
                      .withValues(alpha: 0.60),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}