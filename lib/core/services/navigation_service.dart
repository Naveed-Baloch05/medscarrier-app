import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for launching external turn-by-turn navigation applications (Google Maps / Apple Maps / default GPS).
class NavigationService {
  NavigationService._();

  /// Launches turn-by-turn navigation to the destination.
  /// Prefers exact latitude/longitude coordinates; falls back to formatted address string.
  static Future<bool> openNavigation({
    double? latitude,
    double? longitude,
    String? address,
    String? label,
  }) async {
    // 1. Try launching Google Maps navigation by coordinates
    if (latitude != null && longitude != null) {
      // Native Android Google Maps turn-by-turn intent
      if (!kIsWeb && Platform.isAndroid) {
        final googleNavUri = Uri.parse('google.navigation:q=$latitude,$longitude&mode=d');
        try {
          if (await canLaunchUrl(googleNavUri)) {
            final launched = await launchUrl(
              googleNavUri,
              mode: LaunchMode.externalNonBrowserApplication,
            );
            if (launched) return true;
          }
        } catch (_) {}
      }

      // Geo URI scheme (works on Android and many map handlers)
      final cleanLabel = Uri.encodeComponent(label ?? address ?? 'Stop');
      final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude($cleanLabel)');
      try {
        if (await canLaunchUrl(geoUri)) {
          final launched = await launchUrl(
            geoUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      } catch (_) {}

      // Universal Google Maps Web/App directions link (works on iOS, Android, and Web)
      final gmapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
      );
      try {
        if (await canLaunchUrl(gmapsUrl)) {
          final launched = await launchUrl(
            gmapsUrl,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      } catch (_) {}
    }

    // 2. Fallback: Search by address string if coordinates are not available
    if (address != null && address.trim().isNotEmpty) {
      final encodedAddress = Uri.encodeComponent(address.trim());

      // Geo query with address
      final geoAddressUri = Uri.parse('geo:0,0?q=$encodedAddress');
      try {
        if (await canLaunchUrl(geoAddressUri)) {
          final launched = await launchUrl(
            geoAddressUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      } catch (_) {}

      // Universal directions URL with address
      final gmapsAddressUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress&travelmode=driving',
      );
      try {
        if (await canLaunchUrl(gmapsAddressUrl)) {
          final launched = await launchUrl(
            gmapsAddressUrl,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        }
      } catch (_) {}
    }

    return false;
  }

  /// One-touch phone dialer for customer / pharmacy contact.
  static Future<bool> makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return false;

    final telUri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(telUri)) {
        return await launchUrl(telUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
