import 'package:flutter/material.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedPeriod = 'This Week';

  final List<String> _periods = ['Today', 'This Week', 'All Time'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF08100C) : const Color(0xFFF2F5F3);
    final cardColor = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textPrimary),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildPeriodSelector(cardColor, primaryColor, borderColor, textPrimary, textSecondary, isDark),
          const SizedBox(height: 18),
          _buildMetricsGrid(cardColor, borderColor, primaryColor, textPrimary, textSecondary),
          const SizedBox(height: 18),
          _sectionTitle('Delivery Trend', textPrimary),
          const SizedBox(height: 12),
          _buildDeliveryTrend(cardColor, borderColor, primaryColor, textPrimary, textSecondary, isDark),
          const SizedBox(height: 18),
          _sectionTitle('Top Performing Riders', textPrimary),
          const SizedBox(height: 12),
          _buildTopRiders(cardColor, borderColor, primaryColor, textPrimary, textSecondary, isDark),
          const SizedBox(height: 18),
          _sectionTitle('Recent Activity', textPrimary),
          const SizedBox(height: 12),
          _buildRecentActivity(cardColor, borderColor, textPrimary, textSecondary, primaryColor, isDark),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color textPrimary) {
    return Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary));
  }

  Widget _buildPeriodSelector(Color cardColor, Color primaryColor, Color borderColor, Color textPrimary, Color textSecondary, bool isDark) {
    return Row(
      children: _periods.map((period) {
        final selected = period == _selectedPeriod;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? (isDark ? const Color(0xFF133327) : const Color(0xFFDCEFE6)) : cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? primaryColor : borderColor),
              ),
              child: Text(
                period,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selected ? primaryColor : textSecondary),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricsGrid(Color cardColor, Color borderColor, Color primaryColor, Color textPrimary, Color textSecondary) {
    final metrics = [
      {'icon': Icons.local_shipping_outlined, 'label': 'Total Deliveries', 'value': '156'},
      {'icon': Icons.access_time_filled_outlined, 'label': 'Avg Delivery Time', 'value': '18 min'},
      {'icon': Icons.two_wheeler_outlined, 'label': 'Active Riders', 'value': '8'},
      {'icon': Icons.storefront_outlined, 'label': 'Active Pharmacies', 'value': '12'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.3,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(m['icon'] as IconData, size: 22, color: primaryColor),
              const Spacer(),
              Text(m['label'] as String, style: TextStyle(fontSize: 11, color: textSecondary)),
              const SizedBox(height: 2),
              Text(m['value'] as String, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryTrend(Color cardColor, Color borderColor, Color primaryColor, Color textPrimary, Color textSecondary, bool isDark) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final heights = [0.4, 0.65, 0.55, 0.8, 0.7, 0.9, 0.3];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 100 * heights[i],
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(days[i], style: TextStyle(fontSize: 10, color: textSecondary)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTopRiders(Color cardColor, Color borderColor, Color primaryColor, Color textPrimary, Color textSecondary, bool isDark) {
    final riders = [
      {'name': 'Tom Reilly', 'deliveries': 42, 'maxDeliveries': 50},
      {'name': 'Maya Aslam', 'deliveries': 38, 'maxDeliveries': 50},
      {'name': 'Naveed Baloch', 'deliveries': 24, 'maxDeliveries': 50},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: riders.map((rider) {
          final progress = (rider['deliveries'] as int) / (rider['maxDeliveries'] as int);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18251F) : const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_outline, size: 18, color: primaryColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(rider['name'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary))),
                    Text('${rider['deliveries']} deliveries', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivity(Color cardColor, Color borderColor, Color textPrimary, Color textSecondary, Color primaryColor, bool isDark) {
    final activities = [
      {'icon': Icons.check_circle_outline, 'text': 'Order #MC-4815 delivered by Tom Reilly', 'time': '10 min ago', 'color': primaryColor},
      {'icon': Icons.storefront_outlined, 'text': 'New pharmacy MedCare approved', 'time': '25 min ago', 'color': const Color(0xFF7C4DFF)},
      {'icon': Icons.wifi, 'text': 'Rider Ali Ahmed went online', 'time': '32 min ago', 'color': primaryColor},
      {'icon': Icons.person_add_alt_1, 'text': 'New rider Usman Khan added', 'time': '1 hr ago', 'color': const Color(0xFF7C4DFF)},
      {'icon': Icons.local_shipping_outlined, 'text': 'Order #MC-4812 delivered by Maya Aslam', 'time': '2 hrs ago', 'color': primaryColor},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: activities.map((a) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: (a['color'] as Color).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(a['icon'] as IconData, size: 17, color: a['color'] as Color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a['text'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
                      const SizedBox(height: 2),
                      Text(a['time'] as String, style: TextStyle(fontSize: 10, color: textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
