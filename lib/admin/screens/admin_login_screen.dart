import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/admin_login/admin_login_bloc.dart';
import '../../bloc/admin_login/admin_login_event.dart';
import '../../bloc/admin_login/admin_login_state.dart';
import '../../bloc/admin_dashboard/admin_dashboard_bloc.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _keepMeSignedIn = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Please enter email and password.'),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    context.read<AdminLoginBloc>().add(
          AdminLoginSubmitted(
            email: email,
            password: password,
            keepSignedIn: _keepMeSignedIn,
          ),
        );
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Please enter your email first.'),
            ],
          ),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    context.read<AdminLoginBloc>().add(
          AdminLoginPasswordResetRequested(email: email),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor =
        isDark ? const Color(0xFF08100C) : const Color(0xFFF3F7F5);
    final inputBgColor =
        isDark ? const Color(0xFF0B1410) : Colors.white;
    final primaryColor =
        isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);
    final textPrimaryColor =
        isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondaryColor =
        isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final borderColor =
        isDark ? const Color(0xFF1D322A) : const Color(0xFF0F7253);

    return BlocListener<AdminLoginBloc, AdminLoginState>(
      listener: (context, state) {
        if (state is AdminLoginSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (_) => AdminDashboardBloc(),
                child: const AdminDashboardScreen(),
              ),
            ),
          );
        } else if (state is AdminLoginPasswordResetSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.mark_email_read, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Password reset email sent. Check your inbox.'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0F7253),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else if (state is AdminLoginError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon Badge
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title & Console Badge
                  Text(
                    'MedsCarrier',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textPrimaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ADMIN CONSOLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Section Heading
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage pharmacies, riders and deliveries.',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style:
                        TextStyle(color: textPrimaryColor, fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBgColor,
                      hintText: 'admin@medcareer.com',
                      hintStyle: TextStyle(
                          color: textSecondaryColor
                              .withValues(alpha: 0.5)),
                      prefixIcon: Icon(Icons.mail_rounded,
                          color: primaryColor, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: borderColor, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Password Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style:
                        TextStyle(color: textPrimaryColor, fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputBgColor,
                      hintText: '••••••••',
                      hintStyle: TextStyle(
                          color: textSecondaryColor
                              .withValues(alpha: 0.5)),
                      prefixIcon: Icon(Icons.lock_rounded,
                          color: textSecondaryColor, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: textSecondaryColor,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: borderColor, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Checkbox & Forgot Password
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _keepMeSignedIn,
                              activeColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _keepMeSignedIn = val ?? true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Keep me signed in',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _handleForgotPassword,
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign In Button
                  BlocBuilder<AdminLoginBloc, AdminLoginState>(
                    builder: (context, state) {
                      final isSubmitting =
                          state is AdminLoginSubmitting;

                      return SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor:
                                isDark ? Colors.black : Colors.white,
                            disabledBackgroundColor:
                                primaryColor.withValues(alpha: 0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                          ),
                          onPressed:
                              isSubmitting ? null : _handleSignIn,
                          child: isSubmitting
                              ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: isDark
                                        ? const Color(0xFF08100C)
                                        : Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sign in',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? const Color(0xFF08100C)
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 18,
                                      color: isDark
                                          ? const Color(0xFF08100C)
                                          : Colors.white,
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Security Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 14,
                        color: textSecondaryColor
                            .withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Secured with 2-step verification',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondaryColor
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Pharmacy Registration Link
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'Pharmacy looking to join? ',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondaryColor,
                      ),
                      children: [
                        TextSpan(
                          text: 'Register your\npharmacy',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Version
                  Text(
                    'MedsCarrier · v1.0.0',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: textSecondaryColor
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
