import 'package:flutter/material.dart';

class PharmacyOrderStatusBadge extends StatelessWidget {
  const PharmacyOrderStatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = _getStatusData(status, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: data.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: data.fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: data.fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _StatusData _getStatusData(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'new':
        return _StatusData(
          bg: isDark ? const Color(0xFF1A2744) : const Color(0xFFE8F1FF),
          fg: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        );
      case 'preparing':
        return _StatusData(
          bg: isDark ? const Color(0xFF2D2418) : const Color(0xFFFFF4E5),
          fg: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
        );
      case 'ready':
        return _StatusData(
          bg: isDark ? const Color(0xFF15301D) : const Color(0xFFE8F8EF),
          fg: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
        );
      case 'delivered':
        return _StatusData(
          bg: isDark ? const Color(0xFF15301D) : const Color(0xFFEAF7F0),
          fg: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
        );
      default:
        return _StatusData(
          bg: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          fg: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        );
    }
  }
}

class _StatusData {
  const _StatusData({required this.bg, required this.fg});
  final Color bg;
  final Color fg;
}
