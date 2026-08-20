import 'package:flutter/material.dart';

import 'pharmacy_home_screen.dart';

class PharmacyLoginScreen extends StatefulWidget {
  const PharmacyLoginScreen({super.key});

  @override
  State<PharmacyLoginScreen> createState() => _PharmacyLoginScreenState();
}

class _PharmacyLoginScreenState extends State<PharmacyLoginScreen> {
  static const Color primaryAccent = Color(0xFFE05333);
  static const Color lightBackground = Color(0xFFEFF3F2);
  static const Color darkText = Color(0xFF0F231F);
  static const Color textMuted = Color(0xFF6B7280);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const PharmacyHomeScreen(),
      ),
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

    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 40 : 24,
            vertical: 16,
          ),
          child: Center(
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 480,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTopBar(context),

                  SizedBox(height: 16 * scale),

                  // ------------------------------------------------
                  // PILL ICON
                  // ------------------------------------------------

                  Container(
                    width: 60 * scale,
                    height: 60 * scale,
                    decoration: BoxDecoration(
                      color: primaryAccent.withValues(
                        alpha: 0.1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medication_rounded,
                      color: primaryAccent,
                      size: 30 * scale,
                    ),
                  ),

                  SizedBox(height: 16 * scale),

                  // ------------------------------------------------
                  // TITLE
                  // ------------------------------------------------

                  Text(
                    'Pharmacy Login',
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
                    'Welcome back! Sign in to manage your pharmacy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 32 * scale),

                  // ------------------------------------------------
                  // EMAIL
                  // ------------------------------------------------

                  _buildCustomTextField(
                    controller: _emailController,
                    hintText: 'pharmacy@email.co.uk',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 14 * scale),

                  // ------------------------------------------------
                  // PASSWORD
                  // ------------------------------------------------

                  _buildCustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 8 * scale),

                  // ------------------------------------------------
                  // FORGOT PASSWORD
                  // ------------------------------------------------

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Forgot password screen will be added later.
                      },
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

                  // ------------------------------------------------
                  // LOGIN BUTTON
                  // ------------------------------------------------

                  SizedBox(
                    width: double.infinity,
                    height: 54 * scale,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: primaryAccent.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 24 * scale),

                  // ------------------------------------------------
                  // SIGN UP
                  // ------------------------------------------------

                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment:
                    WrapCrossAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 13.5,
                        ),
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
  }

  // --------------------------------------------------------------
  // TOP BAR
  // --------------------------------------------------------------

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
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Pharmacy account',
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

  // --------------------------------------------------------------
  // CUSTOM TEXT FIELD
  // --------------------------------------------------------------

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.grey.shade500,
            size: 20,
          ),
          errorStyle: const TextStyle(
            fontSize: 12,
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