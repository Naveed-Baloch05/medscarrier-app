import 'package:flutter/material.dart';
import '../screens/pharmacy_signup_screen.dart';
import '../screens/rider_signup_screen.dart';
import '../screens/pharmacy_login_screen.dart';
import '../screens/rider_login_screen.dart';

void showAccountTypeSelector(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _AccountTypeSheet(
      title: 'How would you like to\nuse MedsCarrier?',
      subtitle: 'Choose an account type to continue.',
      pharmacyLabel: 'Pharmacy',
      pharmacySubtitle: 'Manage and deliver prescriptions',
      riderLabel: 'Rider',
      riderSubtitle: 'Deliver medicines to customers',
      isLogin: false,
    ),
  );
}

void showLoginTypeSelector(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _AccountTypeSheet(
      title: 'Which account do you\nwant to sign in to?',
      subtitle: 'Choose your account type.',
      pharmacyLabel: 'Pharmacy',
      pharmacySubtitle: 'Sign in to your pharmacy account',
      riderLabel: 'Rider',
      riderSubtitle: 'Sign in to your rider account',
      isLogin: true,
    ),
  );
}

class _AccountTypeSheet extends StatelessWidget {
  const _AccountTypeSheet({
    required this.title,
    required this.subtitle,
    required this.pharmacyLabel,
    required this.pharmacySubtitle,
    required this.riderLabel,
    required this.riderSubtitle,
    required this.isLogin,
  });

  final String title;
  final String subtitle;
  final String pharmacyLabel;
  final String pharmacySubtitle;
  final String riderLabel;
  final String riderSubtitle;
  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F231F),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          _AccountOption(
            icon: Icons.medication_rounded,
            title: pharmacyLabel,
            subtitle: pharmacySubtitle,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => isLogin
                      ? const PharmacyLoginScreen()
                      : const PharmacySignupScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AccountOption(
            icon: Icons.delivery_dining_rounded,
            title: riderLabel,
            subtitle: riderSubtitle,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => isLogin
                      ? const RiderLoginScreen()
                      : const RiderSignupScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AccountOption extends StatelessWidget {
  const _AccountOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00897B).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF00897B), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF00897B)),
          ],
        ),
      ),
    );
  }
}
