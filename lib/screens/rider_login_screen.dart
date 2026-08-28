import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/rider_login/rider_login_bloc.dart';
import '../bloc/rider_login/rider_login_event.dart';
import '../bloc/rider_login/rider_login_state.dart';
import '../core/services/rider_login_service.dart';
import 'rider_home_screen.dart';

class RiderLoginScreen extends StatefulWidget {
  const RiderLoginScreen({super.key});

  @override
  State<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends State<RiderLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    context.read<RiderLoginBloc>().add(RiderLoginSubmitted(
      email: email,
      password: password,
    ));
  }

  double _scale(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return (shortestSide / 420).clamp(0.85, 1.1);
  }

  ThemeData scaledTheme({bool isDark = false}) => ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme(
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: const Color(0xFF0F7253),
          onPrimary: Colors.white,
          secondary: const Color(0xFF0F7253),
          onSecondary: Colors.white,
          error: const Color(0xFFBA1A1A),
          onError: Colors.white,
          surface: isDark ? const Color(0xFF151E1A) : const Color(0xFFFFFFFF),
          onSurface: isDark ? const Color(0xFFD1DDD7) : const Color(0xFF191C1B),
          onSurfaceVariant:
              isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
        ),
        scaffoldBackgroundColor:
            isDark ? const Color(0xFF0B120E) : const Color(0xFFF2F5F3),
      );

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;
    final parentIsDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: scaledTheme(isDark: parentIsDark),
      child: BlocProvider(
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
                      MaterialPageRoute(builder: (_) => RiderHomeScreen(riderId: state.rider.id)),
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
                              color: const Color(0xFF0F7253)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delivery_dining_rounded,
                              color: const Color(0xFF0F7253),
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
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            isDark: isDark,
                            cs: cs,
                          ),

                          SizedBox(height: 8 * scale),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _showForgotPasswordDialog(context, isDark, cs),
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: const Color(0xFF0F7253),
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
                                    backgroundColor: const Color(0xFF0F7253),
                                    foregroundColor: isDark ? const Color(0xFF0C1310) : Colors.white,
                                    disabledBackgroundColor: const Color(0xFF0F7253).withValues(alpha: 0.5),
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
                                child: const Text(
                                  'Sign up',
                                  style: TextStyle(
                                    color: Color(0xFF0F7253),
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
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final side = BorderSide(
      color: isDark ? const Color(0xFF1D322A) : const Color(0xFFE2E8E5),
    );
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDark ? const Color(0xFFD1DDD7) : const Color(0xFF191C1B),
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
          fontSize: 15,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A2520) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: side,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: side,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F7253), width: 1.5),
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? const Color(0xFF6E9585) : const Color(0xFF6E7A75),
          size: 22,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  void _showForgotPasswordDialog(
    BuildContext context,
    bool isDark,
    ColorScheme cs,
  ) {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF151E1A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Reset Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your registered email address and we will send you a link to reset your password.',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'you@email.co.uk',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F7253),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your email.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await RiderLoginService.instance.sendPasswordResetEmail(email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset link sent to $email.'),
                      backgroundColor: const Color(0xFF0F7253),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: cs.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }
}
