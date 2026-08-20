import 'package:flutter/material.dart';

class PharmacyHomeHeader extends StatelessWidget {
  const PharmacyHomeHeader({
    super.key,
    required this.pharmacyName,
    required this.onNotificationTap,
  });

  final String pharmacyName;
  final VoidCallback onNotificationTap;

  static const Color darkTeal = Color(0xFF004D40);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pharmacyName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: darkTeal,
                ),
              ),

            ],
          ),
        ),
        GestureDetector(
          onTap: onNotificationTap,
          child: Container(
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
              color: darkTeal,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}
