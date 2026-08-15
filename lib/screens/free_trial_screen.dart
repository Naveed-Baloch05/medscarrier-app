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
            body: Stack(
              children: [
                _buildBackgroundDecorations(),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: _horizontalPadding(context),
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(context),
                            SizedBox(height: 26 * _scale(context)),
                            _buildHeroBanner(context),
                            SizedBox(height: 26 * _scale(context)),
                            _buildBenefitsSection(context),
                            SizedBox(height: 28 * _scale(context)),
                            _buildActionButton(context, isLoading),
                            SizedBox(height: 12 * _scale(context)),
                            _buildMaybeLater(context, isLoading),
                            SizedBox(height: 8 * _scale(context)),
                            const Text(
                              'You can start your free trial anytime.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _scale(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return (shortestSide / 420).clamp(0.85, 1.1);
  }

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > 600 ? 40 : 24;
  }

  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        Positioned(
          top: -110,
          right: -110,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryTeal.withValues(alpha: 0.10),
            ),
          ),
        ),
        Positioned(
          bottom: -90,
          left: -90,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentTeal.withValues(alpha: 0.10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scale = _scale(context);

    return Column(
      children: [
        Container(
          width: 92 * scale,
          height: 92 * scale,
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [darkTeal, primaryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryTeal.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.card_giftcard_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 18 * scale),
        Text(
          'Start Your Free Trial',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 27 * scale,
            fontWeight: FontWeight.w800,
            color: darkTeal,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    final scale = _scale(context);

    return Container(
      padding: EdgeInsets.all(24 * scale),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkTeal, primaryTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: darkTeal.withValues(alpha: 0.3),
            blurRadius: 24,
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
              '14 DAYS FREE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          SizedBox(height: 14 * scale),
          Text(
            'Try route planning features free for 14 days.\nNo charges until the trial ends.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What you get',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: darkTeal,
          ),
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

  Widget _buildActionButton(BuildContext context, bool isLoading) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                context.read<SubscriptionBloc>().add(
                      StartTrialEvent(userId: userId, email: email),
                    );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          disabledBackgroundColor: primaryTeal.withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: primaryTeal.withValues(alpha: 0.4),
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
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildMaybeLater(BuildContext context, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: isLoading
            ? null
            : () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: BorderSide(color: primaryTeal.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Maybe Later',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: FreeTrialScreen.primaryTeal.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: FreeTrialScreen.darkTeal.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
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
