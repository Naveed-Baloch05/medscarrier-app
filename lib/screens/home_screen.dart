import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/home_content.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color primaryTeal = HomeContent.primaryTeal;
  static const Color darkTeal = HomeContent.darkTeal;
  static const Color background = HomeContent.background;

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
              return const HomeContent(expired: true);
            }

            return HomeContent(remainingDays: remainingDays);
          },
        ),
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
