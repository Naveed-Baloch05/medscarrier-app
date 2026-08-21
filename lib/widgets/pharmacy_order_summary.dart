import 'package:flutter/material.dart';

class PharmacyOrderSummary extends StatelessWidget {
  const PharmacyOrderSummary({
    super.key,
    required this.isAcceptingOrders,
    required this.onToggleAccepting,
    required this.newCount,
    required this.preparingCount,
    required this.readyCount,
    required this.deliveredCount,
    required this.selectedTab,
    required this.onTabTap,
  });

  final bool isAcceptingOrders;
  final ValueChanged<bool> onToggleAccepting;
  final int newCount;
  final int preparingCount;
  final int readyCount;
  final int deliveredCount;
  final int selectedTab;
  final ValueChanged<int> onTabTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Accepting Orders Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF11261E) : const Color(0xFFDDECE5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF32C787),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Accepting orders',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : cs.primary,
                ),
              ),
              const Spacer(),
              Switch(
                value: isAcceptingOrders,
                activeThumbColor: isDark ? Colors.white : cs.primary,
                activeTrackColor:
                    isDark ? const Color(0xFF32C787) : const Color(0xFFA5D6A7),
                onChanged: onToggleAccepting,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Filter Tabs
        Row(
          children: [
            _buildFilterTab(
              context,
              count: '$newCount',
              label: 'New',
              index: 0,
              isSelected: selectedTab == 0,
              onTap: () => onTabTap(0),
            ),
            const SizedBox(width: 8),
            _buildFilterTab(
              context,
              count: '$preparingCount',
              label: 'Preparing',
              index: 1,
              isSelected: selectedTab == 1,
              onTap: () => onTabTap(1),
            ),
            const SizedBox(width: 8),
            _buildFilterTab(
              context,
              count: '$readyCount',
              label: 'Ready',
              index: 2,
              isSelected: selectedTab == 2,
              onTap: () => onTabTap(2),
            ),
            const SizedBox(width: 8),
            _buildFilterTab(
              context,
              count: '$deliveredCount',
              label: 'Delivered',
              index: 3,
              isSelected: selectedTab == 3,
              onTap: () => onTabTap(3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterTab(
    BuildContext context, {
    required String count,
    required String label,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF1D2F28) : Colors.white)
                : (isDark
                    ? const Color(0xFF131D19)
                    : Colors.white.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: isDark ? const Color(0xFF32C787) : Colors.transparent,
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
