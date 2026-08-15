import 'package:flutter/material.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    this.expired = false,
    this.remainingDays = 0,
  });

  final bool expired;
  final int remainingDays;

  static const int trialDays = 14;

  static const Color primaryTeal = Color(0xFF00897B);
  static const Color darkTeal = Color(0xFF004D40);
  static const Color accentTeal = Color(0xFF26A69A);
  static const Color lightMint = Color(0xFFE0F2F1);
  static const Color background = Color(0xFFF4F8F7);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = (size.shortestSide / 420).clamp(0.85, 1.1);
    final isWide = size.width > 600;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 32 : 20,
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (expired)
                const _ExpiredCard()
              else
                _ActiveCard(remainingDays: remainingDays, scale: scale),
              SizedBox(height: 24 * scale),
              const _QuickActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.remainingDays, required this.scale});

  final int remainingDays;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final progress = (remainingDays / HomeContent.trialDays).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(26 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HomeContent.darkTeal, HomeContent.primaryTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: HomeContent.darkTeal.withValues(alpha: 0.3),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            child: const Text(
              'FREE TRIAL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            '$remainingDays ${remainingDays == 1 ? 'day' : 'days'} remaining',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34 * scale,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 6 * scale),
          const Text(
            'Your free trial is active.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 18 * scale),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiredCard extends StatelessWidget {
  const _ExpiredCard();

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.of(context).size.shortestSide / 420)
        .clamp(0.85, 1.1);

    return Container(
      padding: EdgeInsets.all(26 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: HomeContent.darkTeal.withValues(alpha: 0.06),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72 * scale,
            height: 72 * scale,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_off_rounded,
              color: Colors.orange.shade700,
              size: 38,
            ),
          ),
          SizedBox(height: 16 * scale),
          const Text(
            'Your free trial has expired.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: HomeContent.darkTeal,
            ),
          ),
          SizedBox(height: 6 * scale),
          const Text(
            'Upgrade to a plan to keep using all features.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double gap = 14;
        final double itemWidth = (constraints.maxWidth - gap) / 2;

        const actions = <({IconData icon, String title, String subtitle})>[
          (
            icon: Icons.medical_services_rounded,
            title: 'Order Medicines',
            subtitle: 'Upload prescription & order',
          ),
          (
            icon: Icons.local_shipping_rounded,
            title: 'Track Delivery',
            subtitle: 'Follow your order live',
          ),
          (
            icon: Icons.notifications_active_rounded,
            title: 'Refill Reminders',
            subtitle: 'Never miss a refill',
          ),
          (
            icon: Icons.support_agent_rounded,
            title: 'Support',
            subtitle: 'Talk to a pharmacist',
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: actions
              .map(
                (action) => SizedBox(
                  width: itemWidth,
                  child: _QuickAction(
                    icon: action.icon,
                    title: action.title,
                    subtitle: action.subtitle,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: HomeContent.primaryTeal.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: HomeContent.darkTeal.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: HomeContent.primaryTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: HomeContent.primaryTeal, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: HomeContent.darkTeal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.3,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
