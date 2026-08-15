import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color primaryTeal = Color(0xFF00897B);
  static const Color darkTeal = Color(0xFF004D40);
  static const Color accentTeal = Color(0xFF26A69A);
  static const Color lightMint = Color(0xFFE0F2F1);
  static const Color background = Color(0xFFF4F8F7);

  static const int trialDays = 14;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const _CenteredMessage(
        icon: Icons.person_off_rounded,
        title: 'User is not logged in.',
        subtitle: 'Please sign in to continue.',
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'MedsCarrier',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
        ),
        backgroundColor: darkTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _CenteredMessage(
                icon: Icons.hourglass_top_rounded,
                title: 'Loading your trial...',
                subtitle: 'Please wait a moment.',
                isLoading: true,
              );
            }

            if (snapshot.hasError) {
              return const _CenteredMessage(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load trial information.',
                subtitle: 'Please check your connection and try again.',
              );
            }

            if (!snapshot.hasData ||
                !snapshot.data!.exists ||
                snapshot.data!.data() == null) {
              return const _CenteredMessage(
                icon: Icons.info_outline_rounded,
                title: 'Trial information not found.',
                subtitle: 'No active trial was found for this account.',
              );
            }

            final data = snapshot.data!.data()!;
            final dynamic trialEndValue = data['trialEndDate'];

            DateTime? trialEndDate;

            if (trialEndValue is Timestamp) {
              trialEndDate = trialEndValue.toDate();
            }

            if (trialEndDate == null) {
              return const _CenteredMessage(
                icon: Icons.info_outline_rounded,
                title: 'Trial information not available.',
                subtitle: 'No end date was saved for this trial.',
              );
            }

            // Compare dates without the current time.
            final now = DateTime.now();

            final today = DateTime(
              now.year,
              now.month,
              now.day,
            );

            final endDate = DateTime(
              trialEndDate.year,
              trialEndDate.month,
              trialEndDate.day,
            );

            final remainingDays = endDate.difference(today).inDays;

            if (remainingDays <= 0) {
              return _buildBody(context, _ExpiredContent());
            }

            return _buildBody(context, _ActiveContent(remainingDays: remainingDays));
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Widget content) {
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
              content,
              SizedBox(height: 24 * scale),
              const _QuickActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveContent extends StatelessWidget {
  const _ActiveContent({required this.remainingDays});

  final int remainingDays;

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.of(context).size.shortestSide / 420)
        .clamp(0.85, 1.1);
    final progress = (remainingDays / HomeScreen.trialDays).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(26 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [HomeScreen.darkTeal, HomeScreen.primaryTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: HomeScreen.darkTeal.withValues(alpha: 0.3),
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

class _ExpiredContent extends StatelessWidget {
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
            color: HomeScreen.darkTeal.withValues(alpha: 0.06),
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
              color: HomeScreen.darkTeal,
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

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeScreen.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      color: HomeScreen.primaryTeal,
                    ),
                  )
                else
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: HomeScreen.primaryTeal.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: HomeScreen.primaryTeal,
                      size: 40,
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: HomeScreen.darkTeal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
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
          color: HomeScreen.primaryTeal.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: HomeScreen.darkTeal.withValues(alpha: 0.05),
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
              color: HomeScreen.primaryTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: HomeScreen.primaryTeal, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: HomeScreen.darkTeal,
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
