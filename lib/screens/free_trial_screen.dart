import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/subscription/subscription_bloc.dart';
import '../bloc/subscription/subscription_event.dart';
import '../bloc/subscription/subscription_state.dart';
import 'home_screen.dart';

class FreeTrialScreen extends StatelessWidget {
  const FreeTrialScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  final String userId;
  final String email;

  static const Color primaryTeal = Color(0xFF00897B);
  static const Color darkTeal = Color(0xFF004D40);
  static const Color accentTeal = Color(0xFF26A69A);
  static const Color lightMint = Color(0xFFE0F2F1);
  static const Color background = Color(0xFFF4F8F7);

  static const List<String> benefits = [
    'Route Optimization',
    'Multiple Stops',
    'GPS Navigation',
    'ETA',
    'Delivery Time Windows',
    'Stop Priority',
    'Breaks',
    'Package Details',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubscriptionBloc(),
      child: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state is SubscriptionSuccess) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
          if (state is SubscriptionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final bool isLoading = state is SubscriptionLoading;

          return Scaffold(
            backgroundColor: background,
            body: Column(
              children: [
                _buildGradientHeader(context),
                Expanded(
                  child: _buildWhiteContent(context, isLoading),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // GRADIENT HEADER
  // ================================================================

  Widget _buildGradientHeader(BuildContext context) {
    final scale = _scale(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPadding + 20, 24, 36 * scale),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [darkTeal, primaryTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            width: 72 * scale,
            height: 72 * scale,
            padding: EdgeInsets.all(14 * scale),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.card_giftcard_rounded,
                size: 34,
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: 16 * scale),

          // Title
          Text(
            'Try Premium Free',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28 * scale,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),

          SizedBox(height: 10 * scale),

          // 14 Days badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            child: const Text(
              '14 DAYS FREE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),

          SizedBox(height: 10 * scale),

          // Subtitle
          Text(
            'Start your free trial today.\nNo charges until it ends.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // WHITE CONTENT CARD
  // ================================================================

  Widget _buildWhiteContent(BuildContext context, bool isLoading) {
    final scale = _scale(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 26 * scale, 20, 32 * scale),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBenefitsSection(context),
                SizedBox(height: 26 * scale),
                _buildPlansSection(context),
                SizedBox(height: 28 * scale),
                _buildActionButton(context, isLoading),
                SizedBox(height: 12 * scale),
                _buildMaybeLater(context, isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // RESPONSIVE SCALE
  // ================================================================

  double _scale(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return (shortestSide / 420).clamp(0.85, 1.1);
  }

  // ================================================================
  // BENEFITS
  // ================================================================

  Widget _buildBenefitsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: primaryTeal,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: const Text(
                "What you'll get",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const double gap = 12;
            final double itemWidth = (constraints.maxWidth - gap) / 2;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: benefits
                  .map(
                    (benefit) => SizedBox(
                      width: itemWidth,
                      child: _BenefitChip(text: benefit),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  // ================================================================
  // PLANS
  // ================================================================

  Widget _buildPlansSection(BuildContext context) {
    final scale = _scale(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: darkTeal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pick the plan that fits your needs.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
          ),
        ),
        SizedBox(height: 14 * scale),
        _buildPlanCard(
          title: 'Free',
          label: 'FREE',
          features: const [
            'Unlimited Routes',
            'Up to 10 Stops / Route',
          ],
          buttonText: 'Continue Free',
          highlighted: false,
        ),
        SizedBox(height: 12 * scale),
        _buildPlanCard(
          title: 'Lite',
          label: 'LITE',
          features: const [
            'Unlimited Routes',
            'Unlimited Stops',
            'Some features restricted',
          ],
          buttonText: 'Choose Lite',
          highlighted: false,
        ),
        SizedBox(height: 12 * scale),
        _buildRecommendedPlanCard(
          title: 'Standard',
          label: 'STANDARD',
          features: const [
            'Unlimited Routes',
            'Unlimited Stops',
            'Full Features',
          ],
          buttonText: 'Choose Standard',
        ),
      ],
    );
  }

  // ================================================================
  // PLAN CARD (Free / Lite)
  // ================================================================

  Widget _buildPlanCard({
    required String title,
    required String label,
    required List<String> features,
    required String buttonText,
    required bool highlighted,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryTeal.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: darkTeal.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: darkTeal,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: primaryTeal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: primaryTeal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryTeal,
                side: BorderSide(
                  color: primaryTeal.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // RECOMMENDED PLAN CARD (Standard)
  // ================================================================

  Widget _buildRecommendedPlanCard({
    required String title,
    required String label,
    required List<String> features,
    required String buttonText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryTeal, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: darkTeal,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: primaryTeal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: primaryTeal,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [darkTeal, primaryTeal],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: primaryTeal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ACTION BUTTON
  // ================================================================

  Widget _buildActionButton(BuildContext context, bool isLoading) {
    final scale = _scale(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkTeal, primaryTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        height: 54 * scale,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  context.read<SubscriptionBloc>().add(
                        StartTrialEvent(userId: userId, email: email),
                      );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'START FREE TRIAL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }

  // ================================================================
  // MAYBE LATER
  // ================================================================

  Widget _buildMaybeLater(BuildContext context, bool isLoading) {
    return TextButton(
      onPressed: isLoading
          ? null
          : () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
      child: const Text(
        'Maybe Later',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ================================================================
// BENEFIT CHIP
// ================================================================

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: FreeTrialScreen.lightMint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_rounded,
            color: FreeTrialScreen.primaryTeal,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
