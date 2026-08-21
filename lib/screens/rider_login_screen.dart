import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/rider_login/rider_login_bloc.dart';
import '../bloc/rider_login/rider_login_event.dart';
import '../bloc/rider_login/rider_login_state.dart';
import 'rider_home_screen.dart';

class RiderLoginScreen extends StatefulWidget {
  const RiderLoginScreen({super.key});

  @override
  State<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends State<RiderLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    context.read<RiderLoginBloc>().add(RiderLoginSubmitted(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    ));

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
    );
  }

  double _scale(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return (shortestSide / 420).clamp(0.85, 1.1);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;

    return BlocProvider(
      create: (_) => RiderLoginBloc(),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final cs = theme.colorScheme;
          final isDark = theme.brightness == Brightness.dark;

          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0C1310) : theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: BlocListener<RiderLoginBloc, RiderLoginState>(
                listener: (context, state) {
                  if (state is RiderLoginSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Welcome back, ${state.rider.fullName}!'),
                        backgroundColor: cs.primary,
                      ),
                    );
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
                    );
                  } else if (state is RiderLoginFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: cs.error,
                      ),
                    );
                  }
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 40 : 24,
                    vertical: 16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildTopBar(context, cs, isDark),
                          SizedBox(height: 20 * scale),

                          Container(
                            width: 60 * scale,
                            height: 60 * scale,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delivery_dining_rounded,
                              color: cs.primary,
                              size: 30 * scale,
                            ),
                          ),
                          SizedBox(height: 16 * scale),

                          Text(
                            'Rider Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26 * scale,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 6 * scale),
                          Text(
                            'Welcome back! Sign in to start delivering.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          SizedBox(height: 32 * scale),

                          _buildCustomTextField(
                            context: context,
                            controller: _emailController,
                            hintText: 'you@email.co.uk',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            isDark: isDark,
                            cs: cs,
                          ),
                          SizedBox(height: 14 * scale),
                          _buildCustomTextField(
                            context: context,
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            isDark: isDark,
                            cs: cs,
                          ),

                          SizedBox(height: 8 * scale),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: cs.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 16 * scale),

                          BlocBuilder<RiderLoginBloc, RiderLoginState>(
                            builder: (context, state) {
                              final isLoading = state is RiderLoginLoading;
                              return SizedBox(
                                width: double.infinity,
                                height: 54 * scale,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : () => _submit(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: cs.primary,
                                    foregroundColor: isDark ? const Color(0xFF0C1310) : Colors.white,
                                    disabledBackgroundColor: cs.primary.withValues(alpha: 0.5),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: isLoading
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: (isDark ? Colors.white : Colors.white).withValues(alpha: 0.9),
                                          ),
                                        )
                                      : Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 16 * scale,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: 24 * scale),

                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Sign up',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12 * scale),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ColorScheme cs, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D322A) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: cs.onSurface,
              size: 22,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1D322A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Rider account',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    required ColorScheme cs,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D322A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: TextStyle(color: cs.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
