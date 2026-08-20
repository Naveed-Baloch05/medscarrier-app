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
  static const Color primaryAccent = Color(0xFFE05333);
  static const Color lightBackground = Color(0xFFEFF3F2);
  static const Color darkText = Color(0xFF0F231F);
  static const Color textMuted = Color(0xFF6B7280);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<RiderLoginBloc>().add(RiderLoginSubmitted(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ));
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
          return Scaffold(
            backgroundColor: lightBackground,
            body: SafeArea(
              child: BlocListener<RiderLoginBloc, RiderLoginState>(
                listener: (context, state) {
                  if (state is RiderLoginSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Welcome back, ${state.rider.fullName}!'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const RiderHomeScreen()),
                      (route) => false,
                    );
                  } else if (state is RiderLoginFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
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
                          _buildTopBar(context),

                          SizedBox(height: 20 * scale),

                          // Rider Icon
                          Container(
                            width: 60 * scale,
                            height: 60 * scale,
                            decoration: BoxDecoration(
                              color: primaryAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delivery_dining_rounded,
                              color: primaryAccent,
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
                              color: darkText,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 6 * scale),
                          const Text(
                            'Welcome back! Sign in to start delivering.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          SizedBox(height: 32 * scale),

                          _buildCustomTextField(
                            controller: _emailController,
                            hintText: 'you@email.co.uk',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 14 * scale),
                          _buildCustomTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),

                          SizedBox(height: 8 * scale),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: primaryAccent,
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
                                  onPressed: isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryAccent,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        primaryAccent.withValues(alpha: 0.5),
                                    elevation: 4,
                                    shadowColor:
                                        primaryAccent.withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: isLoading
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
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
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                    color: textMuted, fontSize: 13.5),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Sign up',
                                  style: TextStyle(
                                    color: primaryAccent,
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

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: darkText,
              size: 22,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Rider account',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
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
