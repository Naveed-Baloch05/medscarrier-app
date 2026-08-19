import 'package:flutter/material.dart';
import '../screens/pharmacy_signup_screen.dart';
import '../screens/rider_signup_screen.dart';

void showAccountTypeSelector(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _AccountTypeSheet(),
  );
}

class _AccountTypeSheet extends StatelessWidget {
  const _AccountTypeSheet();

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
          const Text(
            'How would you like to\nuse MedsCarrier?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F231F),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose an account type to continue.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          _AccountOption(
            icon: Icons.medication_rounded,
            title: 'Pharmacy',
            subtitle: 'Manage and deliver prescriptions',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PharmacySignupScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AccountOption(
            icon: Icons.delivery_dining_rounded,
            title: 'Rider',
            subtitle: 'Deliver medicines to customers',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RiderSignupScreen(),
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
