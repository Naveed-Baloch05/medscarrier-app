import 'package:flutter/material.dart';

class PharmacyOrderStatusBadge extends StatelessWidget {
  const PharmacyOrderStatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final statusData = _getStatusData(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: statusData.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: statusData.foregroundColor,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 6),

          Text(
            status,
            style: TextStyle(
              color: statusData.foregroundColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _StatusData _getStatusData(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return const _StatusData(
          backgroundColor: Color(0xFFE8F1FF),
          foregroundColor: Color(0xFF2563EB),
        );

      case 'preparing':
        return const _StatusData(
          backgroundColor: Color(0xFFFFF4E5),
          foregroundColor: Color(0xFFD97706),
        );

      case 'ready':
        return const _StatusData(
          backgroundColor: Color(0xFFE8F8EF),
          foregroundColor: Color(0xFF16A34A),
        );

      case 'delivered':
        return const _StatusData(
          backgroundColor: Color(0xFFEAF7F0),
          foregroundColor: Color(0xFF15803D),
        );

      default:
        return const _StatusData(
          backgroundColor: Color(0xFFF1F5F9),
          foregroundColor: Color(0xFF64748B),
        );
    }
  }
}

class _StatusData {
  const _StatusData({
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
}
