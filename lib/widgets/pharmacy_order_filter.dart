import 'package:flutter/material.dart';

class PharmacyOrderFilter extends StatelessWidget {
  const PharmacyOrderFilter({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;

  static const List<String> filters = [
    'All',
    'New',
    'Preparing',
    'Ready',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedStatus;

          return GestureDetector(
            onTap: () => onStatusSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0F7253)
                    : (isDark ? const Color(0xFF131D19) : Colors.white),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0F7253)
                      : (isDark ? const Color(0xFF2A3A33) : Colors.grey.shade200),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
