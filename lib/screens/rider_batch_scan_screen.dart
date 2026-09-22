import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../bloc/rider_batch/rider_batch_bloc.dart';
import '../bloc/rider_batch/rider_batch_event.dart';
import '../bloc/rider_batch/rider_batch_state.dart';
import '../core/services/rider_batch_service.dart';
import '../core/utils/delivery_address_ocr_parser.dart';
import '../models/delivery_route_model.dart';
import 'rider_batch_route_screen.dart';

enum ScanMode {
  addressOcr,
  barcodeQr,
}

class RiderBatchScanScreen extends StatefulWidget {
  const RiderBatchScanScreen({
    super.key,
    required this.riderId,
    this.route,
    this.pharmacyId,
    this.pharmacyName,
    this.bloc,
  });

  final String riderId;
  final DeliveryRouteModel? route;
  final String? pharmacyId;
  final String? pharmacyName;
  final RiderBatchBloc? bloc;

  @override
  State<RiderBatchScanScreen> createState() => _RiderBatchScanScreenState();
}

class _RiderBatchScanScreenState extends State<RiderBatchScanScreen>
    with WidgetsBindingObserver {
  static const Color primaryColor = Color(0xFF0F7253);
  static const Color secondaryColor = Color(0xFF32C787);

  ScanMode _currentScanMode = ScanMode.addressOcr;

  CameraController? _cameraController;
  late final TextRecognizer _textRecognizer;

  bool _isCameraInitialized = false;
  bool _isCameraInitializing = false;
  bool _isOcrScanning = false;
  String? _cameraErrorMessage;

  MobileScannerController? _scannerController;
  late final RiderBatchBloc _bloc;
  bool _internalBloc = false;
  bool _torchEnabled = false;
  LatLng? _riderLocation;
  bool _isVerificationModalOpen = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    if (widget.bloc != null) {
      _bloc = widget.bloc!;
    } else {
      _internalBloc = true;

      _bloc = RiderBatchBloc()
        ..add(
          InitBatchSession(
            riderId: widget.riderId,
            pharmacyId: widget.pharmacyId,
            pharmacyName: widget.pharmacyName,
            existingRoute: widget.route,
          ),
        );
    }

    _resolveLocation();
    _initOcrCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (_currentScanMode != ScanMode.addressOcr) return;

    if (lifecycleState != AppLifecycleState.resumed) return;

    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      _initOcrCamera();
    }
  }

  Future<void> _initOcrCamera() async {
    if (_isCameraInitializing) return;

    _isCameraInitializing = true;

    try {
      if (_cameraController != null &&
          _cameraController!.value.isInitialized) {
        return;
      }

      try {
        await _cameraController?.dispose();
      } catch (_) {}

      _cameraController = null;

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraErrorMessage =
            'No camera available on this device.';
          });
        }
        return;
      }

      final backCamera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final ctrl = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await ctrl.initialize();

      if (mounted) {
        setState(() {
          _cameraController = ctrl;
          _isCameraInitialized = true;
          _cameraErrorMessage = null;
          _torchEnabled = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraErrorMessage =
          'Camera initialization failed: $e';
        });
      }
    } finally {
      _isCameraInitializing = false;
    }
  }

  Future<void> _switchToMode(ScanMode mode) async {
    if (_currentScanMode == mode) return;

    setState(() {
      _currentScanMode = mode;
      _torchEnabled = false;
    });

    if (mode == ScanMode.addressOcr) {
      await _scannerController?.dispose();
      _scannerController = null;

      await _initOcrCamera();
    } else {
      await _cameraController?.dispose();

      _cameraController = null;
      _isCameraInitialized = false;

      _scannerController = MobileScannerController(
        facing: CameraFacing.back,
        detectionSpeed: DetectionSpeed.normal,
        detectionTimeoutMs: 1200,
        formats: const [
          BarcodeFormat.qrCode,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
        ],
      );

      setState(() {});
    }
  }

  Future<void> _resolveLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _riderLocation = LatLng(
            pos.latitude,
            pos.longitude,
          );
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _cameraController?.dispose();
    _scannerController?.dispose();
    _textRecognizer.close();

    if (_internalBloc) {
      _bloc.close();
    }

    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isVerificationModalOpen) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;

    if (rawValue == null || rawValue.trim().isEmpty) return;

    _bloc.add(
      ScanPackageQr(rawValue.trim()),
    );
  }

  Future<void> _toggleTorch() async {
    try {
      if (_currentScanMode == ScanMode.addressOcr) {
        if (_cameraController != null &&
            _cameraController!.value.isInitialized) {
          final newMode =
          _torchEnabled ? FlashMode.off : FlashMode.torch;

          await _cameraController!.setFlashMode(newMode);

          setState(() {
            _torchEnabled = !_torchEnabled;
          });
        }
      } else {
        if (_scannerController != null) {
          await _scannerController!.toggleTorch();

          setState(() {
            _torchEnabled = !_torchEnabled;
          });
        }
      }
    } catch (_) {}
  }

  // ============================================================
  // SMART OCR ADDRESS DETECTION
  // ============================================================

  Future<void> _captureAndProcessAddress() async {
    if (_isOcrScanning || _isVerificationModalOpen) return;

    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera not ready. Please try again.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isOcrScanning = true;
    });

    String? photoPath;
    String? croppedPath;

    try {
      // --------------------------------------------------------
      // STEP 1: Capture complete package label
      // --------------------------------------------------------

      final photo = await _cameraController!.takePicture();
      photoPath = photo.path;

      final inputImage = InputImage.fromFilePath(photo.path);

      // --------------------------------------------------------
      // STEP 2: First OCR
      //
      // This OCR is ONLY used to locate the address heading.
      // --------------------------------------------------------

      final RecognizedText fullText =
      await _textRecognizer.processImage(inputImage);

      debugPrint('==========================================');
      debugPrint('SMART OCR - FULL IMAGE');
      debugPrint('==========================================');
      debugPrint(fullText.text);

      // --------------------------------------------------------
      // STEP 3: Find address heading
      // --------------------------------------------------------

      final TextBlock? addressHeader =
      _findAddressHeader(fullText);

      String addressOcrText = '';

      // --------------------------------------------------------
      // STEP 4:
      // If address heading found:
      // Crop everything below the heading.
      // --------------------------------------------------------

      if (addressHeader != null) {
        debugPrint(
          'SMART OCR: Address header found: '
              '${addressHeader.text}',
        );

        croppedPath = await _cropAddressRegion(
          imagePath: photo.path,
          fullText: fullText,
          addressHeader: addressHeader,
        );

        if (croppedPath != null) {
          final croppedInput =
          InputImage.fromFilePath(croppedPath);

          final RecognizedText croppedText =
          await _textRecognizer.processImage(
            croppedInput,
          );

          addressOcrText = croppedText.text;

          debugPrint(
            '==========================================',
          );
          debugPrint('SMART OCR - CROPPED ADDRESS');
          debugPrint(
            '==========================================',
          );
          debugPrint(addressOcrText);
        }
      }

      // --------------------------------------------------------
      // STEP 5:
      // Fallback if no address heading was detected
      // --------------------------------------------------------

      if (addressOcrText.trim().isEmpty) {
        debugPrint(
          'SMART OCR: Header not found or crop empty.',
        );

        addressOcrText =
            _extractAddressFromFullText(fullText.text);

        debugPrint(
          'SMART OCR - FALLBACK ADDRESS:',
        );
        debugPrint(addressOcrText);
      }

      // --------------------------------------------------------
      // STEP 6:
      // Remove obvious non-address OCR noise
      // --------------------------------------------------------

      final cleanedAddressText =
      _cleanAddressOcrText(addressOcrText);

      debugPrint(
        'SMART OCR - CLEAN ADDRESS:',
      );
      debugPrint(cleanedAddressText);

      // --------------------------------------------------------
      // STEP 7:
      // Existing parser receives ONLY address-related text
      // --------------------------------------------------------

      final ocrResult =
      DeliveryAddressOcrParser.parse(
        cleanedAddressText,
      );

      debugPrint('=== SMART OCR DEBUG BEGIN ===');
      debugPrint(
        'OCR address text: $cleanedAddressText',
      );
      debugPrint(
        'OCR parsed address: ${ocrResult.address}',
      );
      debugPrint(
        'OCR recipient: ${ocrResult.recipientName}',
      );
      debugPrint(
        'OCR phone: ${ocrResult.phoneNumber}',
      );
      debugPrint(
        'OCR reference: ${ocrResult.referenceId}',
      );
      debugPrint(
        'OCR notes: ${ocrResult.notes}',
      );
      debugPrint(
        'OCR city: ${ocrResult.city}',
      );
      debugPrint(
        'OCR postcode: ${ocrResult.postcode}',
      );
      debugPrint('=== SMART OCR DEBUG END ===');

      // --------------------------------------------------------
      // STEP 8:
      // Validate address
      // --------------------------------------------------------

      if (!ocrResult.isValid ||
          ocrResult.address.trim().length < 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No clear delivery address detected. '
                          'Hold camera steady and align package label.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        return;
      }

      // --------------------------------------------------------
      // STEP 9:
      // Geocode address
      // --------------------------------------------------------

      final geocodeQuery =
      ocrResult.address.replaceAll('\n', ', ');

      final geocoded =
      await RiderBatchService.instance.geocodeAddress(
        geocodeQuery,
      );

      // --------------------------------------------------------
      // STEP 10:
      // Build RouteStopModel
      // --------------------------------------------------------

      final stopId =
          'STOP-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

      final refId =
      ocrResult.referenceId.isNotEmpty
          ? ocrResult.referenceId
          : stopId;

      final currentStops =
      (_bloc.state is RiderBatchScanning)
          ? (_bloc.state as RiderBatchScanning).stops
          : <RouteStopModel>[];

      final currentRoute =
      (_bloc.state is RiderBatchScanning)
          ? (_bloc.state as RiderBatchScanning).route
          : widget.route;

      final stop = RouteStopModel(
        id: stopId,
        orderId: refId,
        routeId: currentRoute?.id ?? '',
        customerName:
        ocrResult.recipientName.isNotEmpty
            ? ocrResult.recipientName
            : 'Recipient',
        customerPhone: ocrResult.phoneNumber,
        address: ocrResult.address,
        city: ocrResult.city,
        notes: ocrResult.notes.isNotEmpty
            ? ocrResult.notes
            : null,
        latitude: geocoded?.latitude,
        longitude: geocoded?.longitude,
        status: 'pending',
        sequence: currentStops.length + 1,
        originalSequence: currentStops.length + 1,
      );

      // --------------------------------------------------------
      // STEP 11:
      // Show verification sheet
      // --------------------------------------------------------

      if (mounted) {
        _showVerificationSheet(
          context,
          stop,
          isOcrSource: true,
        );
      }
    } catch (e) {
      debugPrint('SMART OCR ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OCR reading error: $e',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // --------------------------------------------------------
      // Cleanup temporary files
      // --------------------------------------------------------

      if (croppedPath != null) {
        try {
          await File(croppedPath).delete();
        } catch (_) {}
      }

      if (photoPath != null) {
        try {
          await File(photoPath).delete();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _isOcrScanning = false;
        });
      }
    }
  }

  // ============================================================
  // FIND ADDRESS HEADER
  // ============================================================

  TextBlock? _findAddressHeader(
      RecognizedText recognizedText,
      ) {
    const headerKeywords = [
      'DELIVERY ADDRESS',
      'DELIVERY ADD',
      'DELIVER TO',
      'SHIP TO',
      'SHIPPING ADDRESS',
      'SHIPPING ADD',
      'DELIVERY LOCATION',
      'DELIVERY DETAILS',
      'DESTINATION',
      'DROP OFF',
      'DROP-OFF',
      'ADDRESS',
    ];

    TextBlock? bestMatch;

    int bestPriority = 999;

    for (final block in recognizedText.blocks) {
      final normalized = _normalizeOcrText(
        block.text,
      );

      if (normalized.isEmpty) continue;

      for (int i = 0; i < headerKeywords.length; i++) {
        final keyword = headerKeywords[i];

        if (_matchesHeader(normalized, keyword)) {
          if (i < bestPriority) {
            bestPriority = i;
            bestMatch = block;
          }

          break;
        }
      }
    }

    return bestMatch;
  }

  bool _matchesHeader(
      String text,
      String keyword,
      ) {
    final normalizedText =
    text.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9 ]'),
      ' ',
    );

    final normalizedKeyword =
    keyword.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9 ]'),
      ' ',
    );

    final cleanText =
    normalizedText.replaceAll(
      RegExp(r'\s+'),
      ' ',
    ).trim();

    final cleanKeyword =
    normalizedKeyword.replaceAll(
      RegExp(r'\s+'),
      ' ',
    ).trim();

    return cleanText == cleanKeyword ||
        cleanText.contains(cleanKeyword);
  }

  // ============================================================
  // CROP ADDRESS REGION
  // ============================================================

  Future<String?> _cropAddressRegion({
    required String imagePath,
    required RecognizedText fullText,
    required TextBlock addressHeader,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();

      img.Image? original =
      img.decodeImage(bytes);

      if (original == null) {
        return null;
      }

      // Make orientation consistent before cropping.
      original = img.bakeOrientation(original);

      final imageWidth = original.width;
      final imageHeight = original.height;

      final headerBox = addressHeader.boundingBox;

      // --------------------------------------------------------
      // Convert header coordinates safely into image bounds
      // --------------------------------------------------------

      final headerBottom = headerBox.bottom
          .clamp(0.0, imageHeight.toDouble());

      // --------------------------------------------------------
      // Find nearest section below address heading.
      //
      // Example:
      //
      // DELIVERY ADDRESS
      // House 123
      // Street 4
      // Lahore
      //
      // CUSTOMER
      // PHONE
      // ORDER
      //
      // Crop stops before CUSTOMER/PHONE/ORDER.
      // --------------------------------------------------------

      double nextSectionTop =
      imageHeight.toDouble();

      const sectionKeywords = [
        'CUSTOMER',
        'RECIPIENT',
        'PHONE',
        'MOBILE',
        'CONTACT',
        'ORDER',
        'ORDER ID',
        'REFERENCE',
        'REFERENCE ID',
        'TRACKING',
        'TRACKING ID',
        'TRACKING NUMBER',
        'AWB',
        'COD',
        'TOTAL',
        'AMOUNT',
        'PRICE',
        'PAYMENT',
        'ITEM',
        'PRODUCT',
        'QUANTITY',
        'QTY',
        'BARCODE',
        'QR CODE',
        'DATE',
        'TIME',
      ];

      for (final block in fullText.blocks) {
        if (identical(block, addressHeader)) {
          continue;
        }

        final box = block.boundingBox;

        if (box.top <= headerBottom + 4) {
          continue;
        }

        final normalized =
        _normalizeOcrText(block.text);

        if (normalized.isEmpty) continue;

        bool isSection = false;

        for (final keyword in sectionKeywords) {
          if (_matchesHeader(normalized, keyword)) {
            isSection = true;
            break;
          }
        }

        if (isSection &&
            box.top < nextSectionTop) {
          nextSectionTop = box.top;
        }
      }

      // --------------------------------------------------------
      // Vertical crop
      // --------------------------------------------------------

      int cropTop =
      (headerBottom + 8).round();

      int cropBottom =
      (nextSectionTop - 8).round();

      cropTop =
          cropTop.clamp(0, imageHeight - 1);

      cropBottom =
          cropBottom.clamp(
            cropTop + 1,
            imageHeight,
          );

      // --------------------------------------------------------
      // Horizontal crop:
      // Keep almost the complete label width.
      //
      // This is intentional because the word ADDRESS may be
      // short while the actual address can be much wider.
      // --------------------------------------------------------

      final horizontalMargin =
      (imageWidth * 0.05).round();

      final cropX =
      horizontalMargin.clamp(
        0,
        imageWidth - 1,
      );

      final cropWidth =
      (imageWidth - (horizontalMargin * 2))
          .clamp(
        1,
        imageWidth - cropX,
      );

      final cropHeight =
          cropBottom - cropTop;

      if (cropHeight < 20) {
        return null;
      }

      debugPrint(
        'SMART OCR CROP: '
            'x=$cropX '
            'y=$cropTop '
            'w=$cropWidth '
            'h=$cropHeight',
      );

      // --------------------------------------------------------
      // Crop image
      // --------------------------------------------------------

      img.Image cropped = img.copyCrop(
        original,
        x: cropX,
        y: cropTop,
        width: cropWidth,
        height: cropHeight,
      );

      // --------------------------------------------------------
      // Upscale small address regions.
      // This helps ML Kit recognize small printed text.
      // --------------------------------------------------------

      if (cropped.width < 1200) {
        final scale =
            1200 / cropped.width;

        final newWidth = 1200;
        final newHeight =
        (cropped.height * scale).round();

        cropped = img.copyResize(
          cropped,
          width: newWidth,
          height: newHeight,
          interpolation:
          img.Interpolation.cubic,
        );
      }

      // --------------------------------------------------------
      // Save cropped image to temporary directory
      // --------------------------------------------------------

      final fileName =
          'smart_address_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final outputPath =
          '${Directory.systemTemp.path}/$fileName';

      final outputFile = File(outputPath);

      await outputFile.writeAsBytes(
        img.encodeJpg(
          cropped,
          quality: 95,
        ),
        flush: true,
      );

      return outputPath;
    } catch (e) {
      debugPrint(
        'SMART OCR CROP ERROR: $e',
      );

      return null;
    }
  }

  // ============================================================
  // FALLBACK ADDRESS EXTRACTION
  //
  // Used when the label does not contain a clear
  // DELIVERY ADDRESS / ADDRESS / SHIP TO heading.
  // ============================================================

  String _extractAddressFromFullText(
      String text,
      ) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return '';
    }

    const headerWords = [
      'DELIVERY ADDRESS',
      'DELIVERY ADD',
      'DELIVER TO',
      'SHIP TO',
      'SHIPPING ADDRESS',
      'SHIPPING ADD',
      'ADDRESS',
      'DESTINATION',
      'DROP OFF',
      'DROP-OFF',
    ];

    const stopWords = [
      'CUSTOMER',
      'RECIPIENT',
      'PHONE',
      'MOBILE',
      'CONTACT',
      'ORDER',
      'ORDER ID',
      'REFERENCE',
      'REFERENCE ID',
      'TRACKING',
      'TRACKING ID',
      'TRACKING NUMBER',
      'AWB',
      'COD',
      'TOTAL',
      'AMOUNT',
      'PRICE',
      'PAYMENT',
      'ITEM',
      'PRODUCT',
      'QUANTITY',
      'QTY',
      'BARCODE',
      'QR CODE',
    ];

    int startIndex = -1;

    for (int i = 0; i < lines.length; i++) {
      final normalized =
      _normalizeOcrText(lines[i]);

      for (final header in headerWords) {
        if (_matchesHeader(
          normalized,
          header,
        )) {
          startIndex = i + 1;
          break;
        }
      }

      if (startIndex != -1) break;
    }

    // ----------------------------------------------------------
    // If address heading found, collect lines until a section
    // heading is reached.
    // ----------------------------------------------------------

    if (startIndex != -1 &&
        startIndex < lines.length) {
      final addressLines = <String>[];

      for (
      int i = startIndex;
      i < lines.length;
      i++
      ) {
        final line = lines[i];
        final normalized =
        _normalizeOcrText(line);

        if (normalized.isEmpty) continue;

        bool shouldStop = false;

        for (final stop in stopWords) {
          if (_matchesHeader(
            normalized,
            stop,
          )) {
            shouldStop = true;
            break;
          }
        }

        if (shouldStop) break;

        if (_looksLikePurePhone(line)) {
          continue;
        }

        if (_looksLikeTrackingCode(line)) {
          continue;
        }

        addressLines.add(line);
      }

      return addressLines.join('\n').trim();
    }

    // ----------------------------------------------------------
    // No header found:
    // Look for address-like lines.
    // ----------------------------------------------------------

    final candidates = <String>[];

    const addressHints = [
      'HOUSE',
      'H.NO',
      'H NO',
      'STREET',
      'ST',
      'ROAD',
      'RD',
      'LANE',
      'BLOCK',
      'SECTOR',
      'COLONY',
      'MOHALLA',
      'MOHALLAH',
      'TOWN',
      'VILLAGE',
      'BAZAAR',
      'BAZAR',
      'MARKET',
      'CITY',
      'DISTRICT',
      'TEHSIL',
      'TALUKA',
      'P.O',
      'POST',
      'POST OFFICE',
      'NEAR',
      'OPPOSITE',
      'CHOWK',
      'CHOWKI',
      'PHASE',
      'FLAT',
      'APARTMENT',
      'PLAZA',
      'BUILDING',
    ];

    for (final line in lines) {
      final normalized =
      _normalizeOcrText(line);

      if (normalized.isEmpty) continue;

      if (_looksLikePurePhone(line)) {
        continue;
      }

      if (_looksLikeTrackingCode(line)) {
        continue;
      }

      bool hasAddressHint = false;

      for (final hint in addressHints) {
        if (normalized.contains(hint)) {
          hasAddressHint = true;
          break;
        }
      }

      if (hasAddressHint) {
        candidates.add(line);
      }
    }

    return candidates.join('\n').trim();
  }

  // ============================================================
  // CLEAN OCR ADDRESS TEXT
  // ============================================================

  String _cleanAddressOcrText(
      String text,
      ) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return '';
    }

    const ignoredHeaders = [
      'DELIVERY ADDRESS',
      'DELIVERY ADD',
      'DELIVER TO',
      'SHIP TO',
      'SHIPPING ADDRESS',
      'SHIPPING ADD',
      'DESTINATION',
      'DROP OFF',
      'DROP-OFF',
    ];

    const stopHeaders = [
      'CUSTOMER',
      'RECIPIENT',
      'PHONE',
      'MOBILE',
      'CONTACT',
      'ORDER',
      'ORDER ID',
      'REFERENCE',
      'REFERENCE ID',
      'TRACKING',
      'TRACKING ID',
      'TRACKING NUMBER',
      'AWB',
      'COD',
      'TOTAL',
      'AMOUNT',
      'PRICE',
      'PAYMENT',
      'BARCODE',
      'QR CODE',
    ];

    final result = <String>[];

    for (final line in lines) {
      final normalized =
      _normalizeOcrText(line);

      if (normalized.isEmpty) continue;

      // Remove address headings.
      bool isIgnoredHeader = false;

      for (final header in ignoredHeaders) {
        if (_matchesHeader(
          normalized,
          header,
        )) {
          isIgnoredHeader = true;
          break;
        }
      }

      if (isIgnoredHeader) {
        continue;
      }

      // Do not include obvious section headings.
      bool isStopHeader = false;

      for (final header in stopHeaders) {
        if (_matchesHeader(
          normalized,
          header,
        )) {
          isStopHeader = true;
          break;
        }
      }

      if (isStopHeader) {
        continue;
      }

      // Remove standalone phone number lines.
      if (_looksLikePurePhone(line)) {
        continue;
      }

      // Remove tracking/order/barcode-like lines.
      if (_looksLikeTrackingCode(line)) {
        continue;
      }

      // Remove obvious price lines.
      if (_looksLikePrice(line)) {
        continue;
      }

      result.add(line);
    }

    return result.join('\n').trim();
  }

  // ============================================================
  // OCR NORMALIZATION
  // ============================================================

  String _normalizeOcrText(
      String value,
      ) {
    return value
        .toUpperCase()
        .replaceAll(
      RegExp(r'[^A-Z0-9\s\-\./#]'),
      ' ',
    )
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    )
        .trim();
  }

  // ============================================================
  // PHONE DETECTION
  // ============================================================

  bool _looksLikePurePhone(
      String value,
      ) {
    final compact =
    value.replaceAll(
      RegExp(r'[\s\-\(\)\+]'),
      '',
    );

    if (compact.length < 8) {
      return false;
    }

    return RegExp(
      r'^\d{8,15}$',
    ).hasMatch(compact);
  }

  // ============================================================
  // TRACKING / ORDER CODE DETECTION
  // ============================================================

  bool _looksLikeTrackingCode(
      String value,
      ) {
    final normalized =
    value.trim().toUpperCase();

    if (normalized.isEmpty) {
      return false;
    }

    if (normalized.startsWith('#ORD')) {
      return true;
    }

    if (normalized.startsWith('ORDER #')) {
      return true;
    }

    if (normalized.startsWith('TRACKING')) {
      return true;
    }

    if (normalized.startsWith('AWB')) {
      return true;
    }

    if (normalized.startsWith('WAYBILL')) {
      return true;
    }

    // Long compact codes are usually tracking/barcode IDs.
    final compact =
    normalized.replaceAll(
      RegExp(r'[\s\-]'),
      '',
    );

    if (compact.length >= 14 &&
        RegExp(r'^[A-Z0-9]+$').hasMatch(compact)) {
      return true;
    }

    return false;
  }

  // ============================================================
  // PRICE DETECTION
  // ============================================================

  bool _looksLikePrice(
      String value,
      ) {
    final normalized =
    value.trim().toUpperCase();

    return RegExp(
      r'^(RS|PKR|RPS|PRICE|TOTAL|AMOUNT)\s*[:.]?\s*\d+',
    ).hasMatch(normalized);
  }

  // ============================================================
  // MANUAL ENTRY DIALOG
  // ============================================================

  void _showManualEntryDialog(
      BuildContext context,
      ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.edit_location_alt,
              color: primaryColor,
            ),
            SizedBox(width: 8),
            Text(
              'Enter Address or Code',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'Type a delivery address '
                  '(e.g. House 12, Street 4, F-8, Islamabad) '
                  'or a package code:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 2,
              decoration: InputDecoration(
                hintText:
                'Enter destination address or #ORD-101',
                filled: true,
                fillColor:
                const Color(0xFFF2F5F3),
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final val =
              controller.text.trim();

              if (val.isEmpty) return;

              Navigator.pop(ctx);

              if (val.startsWith('#') ||
                  (val.length <= 10 &&
                      !val.contains(' '))) {
                _bloc.add(
                  ScanPackageQr(val),
                );
              } else {
                final geocoded =
                await RiderBatchService
                    .instance
                    .geocodeAddress(val);

                final stopId =
                    'STOP-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

                final currentStops =
                (_bloc.state
                is RiderBatchScanning)
                    ? (_bloc.state
                as RiderBatchScanning)
                    .stops
                    : <RouteStopModel>[];

                final currentRoute =
                (_bloc.state
                is RiderBatchScanning)
                    ? (_bloc.state
                as RiderBatchScanning)
                    .route
                    : widget.route;

                final manualStop =
                RouteStopModel(
                  id: stopId,
                  orderId: stopId,
                  routeId:
                  currentRoute?.id ?? '',
                  customerName: 'Customer',
                  customerPhone: '',
                  address: val,
                  latitude:
                  geocoded?.latitude,
                  longitude:
                  geocoded?.longitude,
                  status: 'pending',
                  sequence:
                  currentStops.length + 1,
                  originalSequence:
                  currentStops.length + 1,
                );

                if (!mounted) return;

                _showVerificationSheet(
                  this.context,
                  manualStop,
                  isOcrSource: false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(8),
              ),
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark =
        theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<
          RiderBatchBloc,
          RiderBatchState>(
        listener: (context, state) {
          if (state is RiderBatchRouteOverview) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RiderBatchRouteScreen(
                      bloc: _bloc,
                      overviewState: state,
                    ),
              ),
            );
          } else if (state
          is RiderBatchScanning) {
            if (state.pendingVerificationStop !=
                null &&
                !_isVerificationModalOpen) {
              _showVerificationSheet(
                context,
                state.pendingVerificationStop!,
              );
            }

            if (state.duplicateWarningMessage !=
                null &&
                state.duplicateWarningMessage!
                    .isNotEmpty) {
              _showDuplicateWarning(
                context,
                state,
              );

              _bloc.add(
                const ClearScanFeedback(),
              );
            } else if (state.scanErrorMessage !=
                null &&
                state.scanErrorMessage!
                    .isNotEmpty) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text(
                    state.scanErrorMessage!,
                  ),
                  backgroundColor:
                  Colors.red.shade700,
                  behavior:
                  SnackBarBehavior.floating,
                  duration:
                  const Duration(seconds: 3),
                ),
              );

              _bloc.add(
                const ClearScanFeedback(),
              );
            } else if (state.scanSuccessMessage !=
                null &&
                state.scanSuccessMessage!
                    .isNotEmpty) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                SnackBar(
                  content: Text(
                    state.scanSuccessMessage!,
                  ),
                  backgroundColor:
                  primaryColor,
                  behavior:
                  SnackBarBehavior.floating,
                  duration:
                  const Duration(seconds: 2),
                ),
              );

              _bloc.add(
                const ClearScanFeedback(),
              );
            }
          }
        },
        builder: (context, state) {
          final scanningState =
          state is RiderBatchScanning
              ? state
              : null;

          final int count =
              scanningState?.totalScanned ?? 0;

          final stops =
              scanningState?.stops ?? [];

          final lastOrder =
              scanningState?.lastScannedOrder;

          final isProcessing =
              scanningState?.isProcessing ??
                  false;

          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child:
                    _buildCameraFeed(context),
                  ),

                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter:
                        _currentScanMode ==
                            ScanMode.addressOcr
                            ? _ScannerAddressOverlayPainter()
                            : _ScannerBoxOverlayPainter(),
                      ),
                    ),
                  ),

                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child:
                        _buildScannerFrame(),
                      ),
                    ),
                  ),

                  if (_currentScanMode ==
                      ScanMode.addressOcr)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 140,
                      child: Center(
                        child:
                        _buildOcrShutterButton(),
                      ),
                    ),

                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildTopHeader(
                      context,
                      scanningState,
                    ),
                  ),

                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildBottomPanel(
                      context,
                      count: count,
                      lastOrder: lastOrder,
                      stops: stops,
                      isDark: isDark,
                      isOptimizing:
                      state
                      is RiderBatchOptimizing,
                    ),
                  ),

                  if (isProcessing ||
                      state
                      is RiderBatchOptimizing)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black
                            .withValues(alpha: 0.65),
                        child: Center(
                          child: Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 28,
                              vertical: 24,
                            ),
                            decoration:
                            BoxDecoration(
                              color: isDark
                                  ? const Color(
                                  0xFF131D18)
                                  : Colors.white,
                              borderRadius:
                              BorderRadius
                                  .circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color:
                                  Colors.black26,
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize:
                              MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color:
                                  primaryColor,
                                ),
                                const SizedBox(
                                    height: 18),
                                Text(
                                  state
                                  is RiderBatchOptimizing
                                      ? state.stepText
                                      : 'Looking up package details...',
                                  textAlign:
                                  TextAlign.center,
                                  style:
                                  const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                    FontWeight
                                        .w800,
                                  ),
                                ),
                                if (state
                                is RiderBatchOptimizing) ...[
                                  const SizedBox(
                                      height: 8),
                                  Text(
                                    'Organizing ${state.stops.length} stops for optimal travel',
                                    style:
                                    const TextStyle(
                                      fontSize: 12,
                                      color:
                                      Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
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
  // CAMERA FEED
  // ============================================================

  Widget _buildCameraFeed(
      BuildContext context,
      ) {
    if (_currentScanMode ==
        ScanMode.addressOcr) {
      if (_cameraErrorMessage != null) {
        return _buildCameraErrorView(
          context,
          _cameraErrorMessage!,
        );
      }

      if (!_isCameraInitialized ||
          _cameraController == null) {
        return const Center(
          child: CircularProgressIndicator(
            color: secondaryColor,
          ),
        );
      }

      return CameraPreview(
        _cameraController!,
      );
    } else {
      if (_scannerController == null) {
        return const Center(
          child: CircularProgressIndicator(
            color: secondaryColor,
          ),
        );
      }

      return MobileScanner(
        controller: _scannerController!,
        onDetect: _onBarcodeDetected,
        errorBuilder:
            (context, error) =>
            _buildScannerError(context),
      );
    }
  }

  // ============================================================
  // TOP HEADER
  // ============================================================

  Widget _buildTopHeader(
      BuildContext context,
      RiderBatchScanning? state,
      ) {
    final routeName =
        state?.route?.name ?? 'New Route';

    final pharmName =
        state?.pharmacyName ??
            widget.pharmacyName ??
            'Pharmacy Run';

    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black
                .withValues(alpha: 0.90),
            Colors.black
                .withValues(alpha: 0.50),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                Colors.black
                    .withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () =>
                      Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeName,
                      style:
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pharmName,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white
                            .withValues(
                            alpha: 0.75),
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor:
                Colors.black
                    .withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(
                    Icons.edit_note,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip:
                  'Manual Address / Code',
                  onPressed: () =>
                      _showManualEntryDialog(
                        context,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor:
                Colors.black
                    .withValues(alpha: 0.5),
                child: IconButton(
                  icon: Icon(
                    _torchEnabled
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: _torchEnabled
                        ? secondaryColor
                        : Colors.white,
                    size: 20,
                  ),
                  onPressed: _toggleTorch,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding:
            const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black
                  .withValues(alpha: 0.55),
              borderRadius:
              BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white24,
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _modeSegment(
                    title:
                    'Scan Address (OCR)',
                    icon: Icons
                        .text_snippet_outlined,
                    isSelected:
                    _currentScanMode ==
                        ScanMode.addressOcr,
                    onTap: () =>
                        _switchToMode(
                          ScanMode.addressOcr,
                        ),
                  ),
                ),
                Expanded(
                  child: _modeSegment(
                    title:
                    'QR / Barcode',
                    icon: Icons
                        .qr_code_scanner,
                    isSelected:
                    _currentScanMode ==
                        ScanMode.barcodeQr,
                    onTap: () =>
                        _switchToMode(
                          ScanMode.barcodeQr,
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

  Widget _modeSegment({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : Colors.transparent,
          borderRadius:
          BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: secondaryColor
                  .withValues(
                  alpha: 0.3),
              blurRadius: 6,
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SCANNER FRAME
  // ============================================================

  Widget _buildScannerFrame() {
    final isOcr =
        _currentScanMode ==
            ScanMode.addressOcr;

    final width =
    isOcr ? 320.0 : 260.0;

    final height =
    isOcr ? 190.0 : 260.0;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          _corner(
            top: true,
            left: true,
          ),
          _corner(
            top: true,
            left: false,
          ),
          _corner(
            top: false,
            left: true,
          ),
          _corner(
            top: false,
            left: false,
          ),
          Center(
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Icon(
                  isOcr
                      ? Icons
                      .document_scanner_outlined
                      : Icons.qr_code_scanner,
                  color: Colors.white
                      .withValues(alpha: 0.6),
                  size: isOcr ? 36 : 40,
                ),
                const SizedBox(height: 8),
                Text(
                  isOcr
                      ? 'Point at Printed Delivery Address'
                      : 'Point at Package QR / Barcode',
                  textAlign:
                  TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w800,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (isOcr) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Align address label inside frame',
                    style: TextStyle(
                      color: Colors.white
                          .withValues(
                          alpha: 0.8),
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w500,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({
    required bool top,
    required bool left,
  }) {
    return Positioned(
      top: top ? 0 : null,
      bottom: !top ? 0 : null,
      left: left ? 0 : null,
      right: !left ? 0 : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(
              color: secondaryColor,
              width: 4,
            )
                : BorderSide.none,
            bottom: !top
                ? const BorderSide(
              color: secondaryColor,
              width: 4,
            )
                : BorderSide.none,
            left: left
                ? const BorderSide(
              color: secondaryColor,
              width: 4,
            )
                : BorderSide.none,
            right: !left
                ? const BorderSide(
              color: secondaryColor,
              width: 4,
            )
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OCR SHUTTER
  // ============================================================

  Widget _buildOcrShutterButton() {
    return GestureDetector(
      onTap: _isOcrScanning
          ? null
          : _captureAndProcessAddress,
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 26,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          gradient:
          const LinearGradient(
            colors: [
              Color(0xFF0F7253),
              Color(0xFF1EA97C),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
          BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: secondaryColor
                  .withValues(alpha: 0.45),
              blurRadius: 18,
              spreadRadius: 2,
              offset:
              const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            if (_isOcrScanning)
              const SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            else
              const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 22,
              ),
            const SizedBox(width: 10),
            Text(
              _isOcrScanning
                  ? 'Reading Label...'
                  : 'Scan Package Address',
              style: const TextStyle(
                color: Colors.white,
                fontWeight:
                FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM PANEL
  // ============================================================

  Widget _buildBottomPanel(
      BuildContext context, {
        required int count,
        required dynamic lastOrder,
        required List<RouteStopModel> stops,
        required bool isDark,
        required bool isOptimizing,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF131D18)
            : Colors.white,
        borderRadius:
        const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.25),
            blurRadius: 16,
            offset:
            const Offset(0, -4),
          ),
        ],
      ),
      padding:
      const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        20,
      ),
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius:
              BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      padding:
                      const EdgeInsets.all(
                        8,
                      ),
                      decoration: BoxDecoration(
                        color: secondaryColor
                            .withValues(
                            alpha: 0.15),
                        shape:
                        BoxShape.circle,
                      ),
                      child:
                      const Icon(
                        Icons
                            .inventory_2_outlined,
                        color:
                        primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(
                        width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          const Text(
                            'Route Stops Added',
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            TextStyle(
                              fontSize: 12,
                              fontWeight:
                              FontWeight
                                  .w600,
                              color:
                              Colors.grey,
                            ),
                          ),
                          Text(
                            '$count ${count == 1 ? 'Stop' : 'Stops'} Ready',
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (stops.isNotEmpty)
                TextButton.icon(
                  onPressed: () =>
                      _showStopListDrawer(
                        context,
                        stops,
                      ),
                  icon: const Icon(
                    Icons
                        .format_list_numbered,
                    size: 18,
                  ),
                  label: const Text(
                    'View Stops & Map',
                  ),
                  style:
                  TextButton.styleFrom(
                    foregroundColor:
                    primaryColor,
                    textStyle:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
              count == 0 ||
                  isOptimizing
                  ? null
                  : () {
                _showStopListDrawer(
                  context,
                  stops,
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                primaryColor,
                foregroundColor:
                Colors.white,
                disabledBackgroundColor:
                Colors.grey.shade400,
                elevation: 0,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.checklist_rounded,
              ),
              label: Text(
                count == 0
                    ? (_currentScanMode ==
                    ScanMode.addressOcr
                    ? 'Scan Address to Add Stops'
                    : 'Scan Box to Add Stops')
                    : 'Finish Scanning ($count ${count == 1 ? 'Stop' : 'Stops'})',
                style:
                const TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VERIFICATION SHEET
  // ============================================================

  void _showVerificationSheet(
      BuildContext context,
      RouteStopModel stop, {
        bool isOcrSource = false,
      }) {
    _isVerificationModalOpen = true;

    final customerCtrl =
    TextEditingController(
      text: stop.customerName,
    );

    final phoneCtrl =
    TextEditingController(
      text: stop.customerPhone,
    );

    final addressCtrl =
    TextEditingController(
      text: stop.address,
    );

    final notesCtrl =
    TextEditingController(
      text: stop.notes ?? '',
    );

    LatLng? currentCoordinates =
        stop.latLng;

    bool isReGeocoding = false;
    bool isEditing = isOcrSource;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme =
            Theme.of(context);

            final isDark =
                theme.brightness ==
                    Brightness.dark;

            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context)
                    .viewInsets
                    .bottom +
                    24,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(
                    0xFF131D18)
                    : Colors.white,
                borderRadius:
                const BorderRadius
                    .vertical(
                  top: Radius.circular(24),
                ),
              ),
              child:
              SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration:
                        BoxDecoration(
                          color: Colors
                              .grey.shade400,
                          borderRadius:
                          BorderRadius
                              .circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(
                        height: 14),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              Container(
                                padding:
                                const EdgeInsets
                                    .all(8),
                                decoration:
                                BoxDecoration(
                                  color: secondaryColor
                                      .withValues(
                                      alpha:
                                      0.15),
                                  shape: BoxShape
                                      .circle,
                                ),
                                child:
                                const Icon(
                                  Icons.verified,
                                  color:
                                  primaryColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(
                                  width: 10),
                              Flexible(
                                child:
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    const Text(
                                      'Verify Delivery Information',
                                      maxLines:
                                      1,
                                      overflow:
                                      TextOverflow
                                          .ellipsis,
                                      style:
                                      TextStyle(
                                        fontSize:
                                        16,
                                        fontWeight:
                                        FontWeight
                                            .w800,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize:
                                      MainAxisSize
                                          .min,
                                      children: [
                                        if (isOcrSource)
                                          Container(
                                            padding:
                                            const EdgeInsets
                                                .symmetric(
                                              horizontal:
                                              6,
                                              vertical:
                                              2,
                                            ),
                                            decoration:
                                            BoxDecoration(
                                              color: primaryColor
                                                  .withValues(
                                                  alpha:
                                                  0.12),
                                              borderRadius:
                                              BorderRadius
                                                  .circular(
                                                4,
                                              ),
                                            ),
                                            child:
                                            const Text(
                                              'OCR SCANNED',
                                              style:
                                              TextStyle(
                                                fontSize:
                                                9,
                                                fontWeight:
                                                FontWeight
                                                    .w800,
                                                color:
                                                primaryColor,
                                              ),
                                            ),
                                          )
                                        else
                                          Flexible(
                                            child:
                                            Text(
                                              'Ref: #${stop.orderId}',
                                              maxLines:
                                              1,
                                              overflow:
                                              TextOverflow
                                                  .ellipsis,
                                              style:
                                              const TextStyle(
                                                fontSize:
                                                11,
                                                color:
                                                Colors.grey,
                                                fontWeight:
                                                FontWeight
                                                    .w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setSheetState(
                                  () {
                                isEditing =
                                !isEditing;
                              },
                            );
                          },
                          icon: Icon(
                            isEditing
                                ? Icons.check
                                : Icons.edit,
                            size: 16,
                            color:
                            primaryColor,
                          ),
                          label: Text(
                            isEditing
                                ? 'Done'
                                : 'Edit',
                            style:
                            const TextStyle(
                              color:
                              primaryColor,
                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                        height: 16),
                    const Text(
                      'CUSTOMER / RECIPIENT',
                      style:
                      TextStyle(
                        fontSize: 10,
                        fontWeight:
                        FontWeight.w800,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(
                        height: 4),
                    if (isEditing)
                      TextField(
                        controller:
                        customerCtrl,
                        decoration:
                        InputDecoration(
                          hintText:
                          'Recipient Name',
                          filled: true,
                          fillColor: isDark
                              ? const Color(
                              0xFF1C2A22)
                              : const Color(
                              0xFFF2F5F3),
                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              10,
                            ),
                            borderSide:
                            BorderSide
                                .none,
                          ),
                          contentPadding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      )
                    else
                      Text(
                        customerCtrl.text
                            .isNotEmpty
                            ? customerCtrl
                            .text
                            : 'Customer',
                        style:
                        const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                    const SizedBox(
                        height: 12),
                    const Text(
                      'PHONE NUMBER',
                      style:
                      TextStyle(
                        fontSize: 10,
                        fontWeight:
                        FontWeight.w800,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(
                        height: 4),
                    if (isEditing)
                      TextField(
                        controller:
                        phoneCtrl,
                        keyboardType:
                        TextInputType.phone,
                        decoration:
                        InputDecoration(
                          hintText:
                          'e.g. 0300-1234567 (optional)',
                          filled: true,
                          fillColor: isDark
                              ? const Color(
                              0xFF1C2A22)
                              : const Color(
                              0xFFF2F5F3),
                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              10,
                            ),
                            borderSide:
                            BorderSide
                                .none,
                          ),
                          contentPadding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      )
                    else
                      Text(
                        phoneCtrl.text
                            .isNotEmpty
                            ? phoneCtrl.text
                            : 'No phone specified',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                          FontWeight.w600,
                          color: phoneCtrl.text
                              .isNotEmpty
                              ? null
                              : Colors.grey,
                        ),
                      ),
                    const SizedBox(
                        height: 12),
                    const Text(
                      'DELIVERY ADDRESS',
                      style:
                      TextStyle(
                        fontSize: 10,
                        fontWeight:
                        FontWeight.w800,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(
                        height: 4),
                    if (isEditing)
                      TextField(
                        controller:
                        addressCtrl,
                        maxLines: 2,
                        decoration:
                        InputDecoration(
                          hintText:
                          'Full street address, sector, city',
                          filled: true,
                          fillColor: isDark
                              ? const Color(
                              0xFF1C2A22)
                              : const Color(
                              0xFFF2F5F3),
                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              10,
                            ),
                            borderSide:
                            BorderSide
                                .none,
                          ),
                          contentPadding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding:
                        const EdgeInsets
                            .all(10),
                        decoration:
                        BoxDecoration(
                          color: isDark
                              ? const Color(
                              0xFF1C2A22)
                              : const Color(
                              0xFFF2F5F3),
                          borderRadius:
                          BorderRadius
                              .circular(
                            10,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            const Icon(
                              Icons
                                  .location_on,
                              color:
                              primaryColor,
                              size: 16,
                            ),
                            const SizedBox(
                                width: 8),
                            Expanded(
                              child: Text(
                                addressCtrl.text
                                    .isNotEmpty
                                    ? addressCtrl
                                    .text
                                    : 'No address specified',
                                style:
                                const TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                  FontWeight
                                      .w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(
                        height: 10),
                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        currentCoordinates !=
                            null
                            ? const Color(
                            0xFFE8F5E9)
                            : const Color(
                            0xFFFFF8E1),
                        borderRadius:
                        BorderRadius
                            .circular(
                          10,
                        ),
                        border:
                        Border.all(
                          color:
                          currentCoordinates !=
                              null
                              ? const Color(
                              0xFFA5D6A7)
                              : const Color(
                              0xFFFFE082),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            currentCoordinates !=
                                null
                                ? Icons.pin_drop
                                : Icons
                                .location_off_outlined,
                            size: 18,
                            color:
                            currentCoordinates !=
                                null
                                ? primaryColor
                                : Colors.amber
                                .shade900,
                          ),
                          const SizedBox(
                              width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  currentCoordinates !=
                                      null
                                      ? 'Location Pinned on Map'
                                      : 'Coordinates Not Found',
                                  style:
                                  TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight
                                        .w700,
                                    color:
                                    currentCoordinates !=
                                        null
                                        ? primaryColor
                                        : Colors
                                        .amber
                                        .shade900,
                                  ),
                                ),
                                if (currentCoordinates !=
                                    null)
                                  Text(
                                    'Lat: ${currentCoordinates!.latitude.toStringAsFixed(4)}, Lng: ${currentCoordinates!.longitude.toStringAsFixed(4)}',
                                    style:
                                    TextStyle(
                                      fontSize:
                                      10,
                                      color: Colors
                                          .grey
                                          .shade700,
                                    ),
                                  )
                                else
                                  Text(
                                    'Edit address above and tap Re-locate',
                                    style:
                                    TextStyle(
                                      fontSize:
                                      10,
                                      color: Colors
                                          .amber
                                          .shade900,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed:
                            isReGeocoding
                                ? null
                                : () async {
                              final text =
                              addressCtrl
                                  .text
                                  .trim();

                              if (text
                                  .isEmpty) {
                                return;
                              }

                              setSheetState(
                                    () {
                                  isReGeocoding =
                                  true;
                                },
                              );

                              final loc =
                              await RiderBatchService
                                  .instance
                                  .geocodeAddress(
                                text,
                              );

                              setSheetState(
                                    () {
                                  currentCoordinates =
                                      loc;
                                  isReGeocoding =
                                  false;
                                },
                              );
                            },
                            icon:
                            isReGeocoding
                                ? const SizedBox(
                              width: 12,
                              height: 12,
                              child:
                              CircularProgressIndicator(
                                strokeWidth:
                                2,
                              ),
                            )
                                : const Icon(
                              Icons.refresh,
                              size: 14,
                            ),
                            label:
                            const Text(
                              'Re-locate',
                              style:
                              TextStyle(
                                fontSize: 11,
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                            style:
                            TextButton
                                .styleFrom(
                              foregroundColor:
                              primaryColor,
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                        height: 12),
                    if (stop.coldChain ||
                        stop.controlledDrug)
                      Row(
                        children: [
                          if (stop.coldChain) ...[
                            Container(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration:
                              BoxDecoration(
                                color: Colors.cyan
                                    .shade100,
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  6,
                                ),
                              ),
                              child: Text(
                                '❄ Cold-Chain (2-8°C)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                  FontWeight
                                      .w800,
                                  color: Colors
                                      .cyan
                                      .shade900,
                                ),
                              ),
                            ),
                            const SizedBox(
                                width: 8),
                          ],
                          if (stop.controlledDrug)
                            Container(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration:
                              BoxDecoration(
                                color: Colors.amber
                                    .shade100,
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  6,
                                ),
                              ),
                              child: Text(
                                '🛡 Controlled Drug',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                  FontWeight
                                      .w800,
                                  color: Colors
                                      .amber
                                      .shade900,
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(
                        height: 12),
                    const Text(
                      'NOTES FOR STOP',
                      style:
                      TextStyle(
                        fontSize: 10,
                        fontWeight:
                        FontWeight.w800,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(
                        height: 4),
                    TextField(
                      controller:
                      notesCtrl,
                      decoration:
                      InputDecoration(
                        hintText:
                        'e.g. Leave at back porch or ring bell 2x',
                        filled: true,
                        fillColor: isDark
                            ? const Color(
                            0xFF1C2A22)
                            : const Color(
                            0xFFF2F5F3),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            10,
                          ),
                          borderSide:
                          BorderSide.none,
                        ),
                        contentPadding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(
                        height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child:
                      ElevatedButton.icon(
                        onPressed: () {
                          final updatedStop =
                          stop.copyWith(
                            customerName:
                            customerCtrl
                                .text
                                .trim()
                                .isNotEmpty
                                ? customerCtrl
                                .text
                                .trim()
                                : 'Recipient',
                            customerPhone:
                            phoneCtrl.text
                                .trim(),
                            address:
                            addressCtrl.text
                                .trim(),
                            latitude:
                            currentCoordinates
                                ?.latitude,
                            longitude:
                            currentCoordinates
                                ?.longitude,
                            notes:
                            notesCtrl.text
                                .trim()
                                .isNotEmpty
                                ? notesCtrl
                                .text
                                .trim()
                                : null,
                          );

                          Navigator.pop(
                            sheetCtx,
                          );

                          _isVerificationModalOpen =
                          false;

                          _bloc.add(
                            ConfirmScannedDelivery(
                              updatedStop,
                            ),
                          );
                        },
                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          primaryColor,
                          foregroundColor:
                          Colors.white,
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              14,
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons
                              .add_circle_outline,
                        ),
                        label: const Text(
                          'Add Stop to Route',
                          style:
                          TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight
                                .w800,
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
      },
    ).then((_) {
      _isVerificationModalOpen = false;
    });
  }

  // ============================================================
  // DUPLICATE WARNING
  // ============================================================

  void _showDuplicateWarning(
      BuildContext context,
      RiderBatchScanning state,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber,
              size: 28,
            ),
            SizedBox(width: 8),
            Text(
              'Already Added',
              style: TextStyle(
                fontWeight:
                FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize:
          MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'This delivery has already been added to this route.',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (state.lastScannedOrder !=
                null)
              Text(
                'Order #${state.lastScannedOrder!.id} (${state.lastScannedOrder!.customerName})',
                style:
                const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx),
            child:
            const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);

              _showStopListDrawer(
                context,
                state.stops,
              );
            },
            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              primaryColor,
              foregroundColor:
              Colors.white,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  8,
                ),
              ),
            ),
            child:
            const Text('Review Stop'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STOP LIST & MAP
  // ============================================================

  void _showStopListDrawer(
      BuildContext context,
      List<RouteStopModel> stops,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
      Colors.transparent,
      builder: (drawerCtx) {
        return StatefulBuilder(
          builder:
              (ctx, setDrawerState) {
            final theme =
            Theme.of(context);

            final isDark =
                theme.brightness ==
                    Brightness.dark;

            final markers = <Marker>{};

            for (int i = 0;
            i < stops.length;
            i++) {
              final s = stops[i];

              if (s.latLng != null) {
                markers.add(
                  Marker(
                    markerId:
                    MarkerId(
                      'list_stop_${s.id}',
                    ),
                    position: s.latLng!,
                    icon:
                    BitmapDescriptor
                        .defaultMarkerWithHue(
                      BitmapDescriptor
                          .hueOrange,
                    ),
                    infoWindow:
                    InfoWindow(
                      title:
                      'Stop #${s.sequence}: ${s.customerName}',
                      snippet:
                      s.address,
                    ),
                  ),
                );
              }
            }

            return Container(
              height:
              MediaQuery.of(context)
                  .size
                  .height *
                  0.85,
              decoration:
              BoxDecoration(
                color: isDark
                    ? const Color(
                    0xFF131D18)
                    : Colors.white,
                borderRadius:
                const BorderRadius
                    .vertical(
                  top: Radius.circular(
                    24,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(
                      height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration:
                    BoxDecoration(
                      color: Colors
                          .grey.shade400,
                      borderRadius:
                      BorderRadius
                          .circular(2),
                    ),
                  ),
                  const SizedBox(
                      height: 12),
                  Padding(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 20,
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              const Text(
                                'Current Route Stops',
                                maxLines:
                                1,
                                overflow:
                                TextOverflow
                                    .ellipsis,
                                style:
                                TextStyle(
                                  fontSize:
                                  18,
                                  fontWeight:
                                  FontWeight
                                      .w800,
                                ),
                              ),
                              Text(
                                '${stops.length} packages scanned and confirmed',
                                maxLines:
                                1,
                                overflow:
                                TextOverflow
                                    .ellipsis,
                                style:
                                const TextStyle(
                                  fontSize:
                                  12,
                                  color:
                                  Colors
                                      .grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon:
                          const Icon(
                            Icons.close,
                          ),
                          onPressed: () =>
                              Navigator.pop(
                                drawerCtx,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 160,
                    margin:
                    const EdgeInsets
                        .fromLTRB(
                      16,
                      10,
                      16,
                      10,
                    ),
                    decoration:
                    BoxDecoration(
                      borderRadius:
                      BorderRadius
                          .circular(
                        16,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius:
                      BorderRadius
                          .circular(
                        16,
                      ),
                      child: GoogleMap(
                        initialCameraPosition:
                        CameraPosition(
                          target: stops
                              .first
                              .latLng ??
                              _riderLocation ??
                              const LatLng(
                                33.6844,
                                73.0479,
                              ),
                          zoom: 13,
                        ),
                        markers: markers,
                        myLocationEnabled:
                        true,
                        myLocationButtonEnabled:
                        false,
                        zoomControlsEnabled:
                        false,
                      ),
                    ),
                  ),
                  Expanded(
                    child:
                    ListView.separated(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount:
                      stops.length,
                      separatorBuilder:
                          (_, __) =>
                      const SizedBox(
                        height: 10,
                      ),
                      itemBuilder:
                          (context, index) {
                        final stop =
                        stops[index];

                        return _buildStopListCard(
                          drawerCtx,
                          stop,
                          isDark,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding:
                    const EdgeInsets
                        .fromLTRB(
                      16,
                      8,
                      16,
                      16,
                    ),
                    child: SizedBox(
                      width:
                      double.infinity,
                      height: 52,
                      child:
                      ElevatedButton
                          .icon(
                        onPressed:
                        stops.isEmpty
                            ? null
                            : () {
                          Navigator.pop(
                            drawerCtx,
                          );

                          _bloc.add(
                            OptimizeBatchRoute(
                              origin:
                              _riderLocation,
                            ),
                          );
                        },
                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          primaryColor,
                          foregroundColor:
                          Colors.white,
                          disabledBackgroundColor:
                          Colors.grey
                              .shade400,
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              14,
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons
                              .alt_route_rounded,
                        ),
                        label: Text(
                          'Optimize Route (${stops.length} ${stops.length == 1 ? 'Stop' : 'Stops'})',
                          style:
                          const TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight
                                .w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStopListCard(
      BuildContext context,
      RouteStopModel stop,
      bool isDark,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C2A22)
            : const Color(0xFFF2F5F3),
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration:
            const BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${stop.sequence}',
                style:
                const TextStyle(
                  color: Colors.white,
                  fontWeight:
                  FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        stop.customerName,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight
                              .w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(
                        width: 8),
                    Text(
                      '#${stop.orderId}',
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color:
                        primaryColor,
                        fontWeight:
                        FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                    height: 2),
                Text(
                  stop.address,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                ),
                if (stop.notes != null &&
                    stop.notes!
                        .isNotEmpty) ...[
                  const SizedBox(
                      height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons
                            .note_alt_outlined,
                        size: 12,
                        color:
                        primaryColor,
                      ),
                      const SizedBox(
                          width: 4),
                      Expanded(
                        child: Text(
                          stop.notes!,
                          style:
                          const TextStyle(
                            fontSize: 11,
                            fontStyle:
                            FontStyle
                                .italic,
                            color:
                            primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(
                    height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () =>
                          _showEditStopDialog(
                            context,
                            stop,
                          ),
                      child:
                      const Padding(
                        padding:
                        EdgeInsets
                            .symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 13,
                              color:
                              primaryColor,
                            ),
                            SizedBox(
                                width: 3),
                            Text(
                              'Edit',
                              style:
                              TextStyle(
                                fontSize:
                                11,
                                color:
                                primaryColor,
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                        width: 12),
                    InkWell(
                      onTap: () =>
                          _showAddNoteDialog(
                            context,
                            stop,
                          ),
                      child:
                      const Padding(
                        padding:
                        EdgeInsets
                            .symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .note_add_outlined,
                              size: 13,
                              color:
                              primaryColor,
                            ),
                            SizedBox(
                                width: 3),
                            Text(
                              'Notes',
                              style:
                              TextStyle(
                                fontSize:
                                11,
                                color:
                                primaryColor,
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon:
                      const Icon(
                        Icons
                            .delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      padding:
                      EdgeInsets.zero,
                      constraints:
                      const BoxConstraints(),
                      onPressed: () {
                        Navigator.pop(
                            context);

                        _bloc.add(
                          RemoveScannedPackage(
                            stop.orderId,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EDIT STOP
  // ============================================================

  void _showEditStopDialog(
      BuildContext context,
      RouteStopModel stop,
      ) {
    final customerCtrl =
    TextEditingController(
      text: stop.customerName,
    );

    final phoneCtrl =
    TextEditingController(
      text: stop.customerPhone,
    );

    final addressCtrl =
    TextEditingController(
      text: stop.address,
    );

    final notesCtrl =
    TextEditingController(
      text: stop.notes ?? '',
    );

    showDialog(
      context: context,
      builder: (dlgCtx) =>
          AlertDialog(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(16),
            ),
            title: const Text(
              'Edit Stop Details',
              style: TextStyle(
                fontWeight:
                FontWeight.w800,
                fontSize: 16,
              ),
            ),
            content:
            SingleChildScrollView(
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  const Text(
                    'RECIPIENT NAME',
                    style:
                    TextStyle(
                      fontSize: 10,
                      fontWeight:
                      FontWeight.w800,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(
                      height: 4),
                  TextField(
                    controller:
                    customerCtrl,
                    decoration:
                    InputDecoration(
                      filled: true,
                      fillColor:
                      const Color(
                        0xFFF2F5F3,
                      ),
                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          8,
                        ),
                        borderSide:
                        BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 10),
                  const Text(
                    'PHONE NUMBER',
                    style:
                    TextStyle(
                      fontSize: 10,
                      fontWeight:
                      FontWeight.w800,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(
                      height: 4),
                  TextField(
                    controller:
                    phoneCtrl,
                    decoration:
                    InputDecoration(
                      filled: true,
                      fillColor:
                      const Color(
                        0xFFF2F5F3,
                      ),
                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          8,
                        ),
                        borderSide:
                        BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 10),
                  const Text(
                    'DELIVERY ADDRESS',
                    style:
                    TextStyle(
                      fontSize: 10,
                      fontWeight:
                      FontWeight.w800,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(
                      height: 4),
                  TextField(
                    controller:
                    addressCtrl,
                    maxLines: 2,
                    decoration:
                    InputDecoration(
                      filled: true,
                      fillColor:
                      const Color(
                        0xFFF2F5F3,
                      ),
                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          8,
                        ),
                        borderSide:
                        BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 10),
                  const Text(
                    'NOTES',
                    style:
                    TextStyle(
                      fontSize: 10,
                      fontWeight:
                      FontWeight.w800,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(
                      height: 4),
                  TextField(
                    controller:
                    notesCtrl,
                    decoration:
                    InputDecoration(
                      filled: true,
                      fillColor:
                      const Color(
                        0xFFF2F5F3,
                      ),
                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          8,
                        ),
                        borderSide:
                        BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                      dlgCtx,
                    ),
                child:
                const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final updated =
                  stop.copyWith(
                    customerName:
                    customerCtrl.text
                        .trim(),
                    customerPhone:
                    phoneCtrl.text
                        .trim(),
                    address:
                    addressCtrl.text
                        .trim(),
                    notes: notesCtrl.text
                        .trim()
                        .isNotEmpty
                        ? notesCtrl.text
                        .trim()
                        : null,
                  );

                  Navigator.pop(
                    dlgCtx,
                  );

                  _bloc.add(
                    EditRouteStop(updated),
                  );
                },
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  primaryColor,
                  foregroundColor:
                  Colors.white,
                ),
                child:
                const Text('Save'),
              ),
            ],
          ),
    );
  }

  // ============================================================
  // ADD NOTE
  // ============================================================

  void _showAddNoteDialog(
      BuildContext context,
      RouteStopModel stop,
      ) {
    final noteCtrl =
    TextEditingController(
      text: stop.notes ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.note_alt_outlined,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notes for Stop #${stop.sequence}',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Recipient: ${stop.customerName}',
                  style:
                  const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(
                    height: 10),
                TextField(
                  controller:
                  noteCtrl,
                  maxLines: 3,
                  decoration:
                  InputDecoration(
                    hintText:
                    'Add delivery instructions or package notes...',
                    filled: true,
                    fillColor:
                    const Color(
                      0xFFF2F5F3,
                    ),
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                      borderSide:
                      BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(ctx),
                child:
                const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);

                  _bloc.add(
                    AddStopNote(
                      orderId: stop.orderId,
                      note: noteCtrl.text
                          .trim(),
                    ),
                  );
                },
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  primaryColor,
                  foregroundColor:
                  Colors.white,
                ),
                child:
                const Text('Save Note'),
              ),
            ],
          ),
    );
  }

  // ============================================================
  // SCANNER ERROR
  // ============================================================

  Widget _buildScannerError(
      BuildContext context,
      ) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding:
          const EdgeInsets.all(32),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(
                  height: 16),
              const Text(
                'Camera Access Required',
                style:
                TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                  height: 8),
              const Text(
                'Please enable camera permissions to scan delivery box codes.',
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  color:
                  Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(
                  height: 16),
              ElevatedButton(
                onPressed: () =>
                    _showManualEntryDialog(
                      context,
                    ),
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  primaryColor,
                  foregroundColor:
                  Colors.white,
                ),
                child:
                const Text(
                  'Enter Code Manually',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraErrorView(
      BuildContext context,
      String error,
      ) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding:
          const EdgeInsets.all(32),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(
                  height: 16),
              const Text(
                'Camera Access Issue',
                style:
                TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                  height: 8),
              Text(
                error,
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  color:
                  Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(
                  height: 16),
              ElevatedButton(
                onPressed:
                _initOcrCamera,
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  primaryColor,
                  foregroundColor:
                  Colors.white,
                ),
                child:
                const Text(
                  'Retry Camera',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ADDRESS OVERLAY
// ============================================================

class _ScannerAddressOverlayPainter
    extends CustomPainter {
  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    const boxWidth = 320.0;
    const boxHeight = 190.0;

    final left =
        (size.width - boxWidth) / 2;

    final top =
        (size.height - boxHeight) / 2;

    final overlayPaint = Paint()
      ..color = Colors.black
          .withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final backgroundPath =
    Path()
      ..addRect(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );

    final cutoutPath =
    Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            top,
            boxWidth,
            boxHeight,
          ),
          const Radius.circular(
            16,
          ),
        ),
      );

    final combined =
    Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(
      combined,
      overlayPaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter
      oldDelegate,
      ) =>
      false;
}

// ============================================================
// BARCODE OVERLAY
// ============================================================

class _ScannerBoxOverlayPainter
    extends CustomPainter {
  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    const boxSize = 260.0;

    final left =
        (size.width - boxSize) / 2;

    final top =
        (size.height - boxSize) / 2;

    final overlayPaint = Paint()
      ..color = Colors.black
          .withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final backgroundPath =
    Path()
      ..addRect(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );

    final cutoutPath =
    Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            top,
            boxSize,
            boxSize,
          ),
          const Radius.circular(
            16,
          ),
        ),
      );

    final combined =
    Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(
      combined,
      overlayPaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter
      oldDelegate,
      ) =>
      false;
}