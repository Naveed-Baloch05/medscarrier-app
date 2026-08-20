import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pharmacy_signup/pharmacy_signup_bloc.dart';
import '../bloc/pharmacy_signup/pharmacy_signup_event.dart';
import '../bloc/pharmacy_signup/pharmacy_signup_state.dart';

class PharmacySignupScreen extends StatefulWidget {
  const PharmacySignupScreen({super.key});

  @override
  State<PharmacySignupScreen> createState() => _PharmacySignupScreenState();
}

class _PharmacySignupScreenState extends State<PharmacySignupScreen> {
  static const Color primaryAccent = Color(0xFFE05333);
  static const Color lightBackground = Color(0xFFEFF3F2);
  static const Color darkText = Color(0xFF0F231F);
  static const Color textMuted = Color(0xFF6B7280);

  bool _agreeToTerms = true;

  final _pharmacyNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _gphcController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _pharmacyNameController.dispose();
    _contactNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gphcController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms of Service')),
      );
      return;
    }

    context.read<PharmacySignupBloc>().add(PharmacySignupSubmitted(
          pharmacyName: _pharmacyNameController.text.trim(),
          contactName: _contactNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          businessAddress: _addressController.text.trim(),
          gphcNumber: _gphcController.text.trim(),
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
      create: (_) => PharmacySignupBloc(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: lightBackground,
            body: SafeArea(
              child: BlocListener<PharmacySignupBloc, PharmacySignupState>(
                listener: (context, state) {
                  if (state is PharmacySignupSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${state.pharmacy.pharmacyName} registered! We\'ll review your details within 1 business day.',
                        ),
                        backgroundColor: Colors.teal,
                      ),
                    );
                    Navigator.of(context).pop();
                  } else if (state is PharmacySignupFailure) {
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

                          SizedBox(height: 16 * scale),

                          // Pill Icon Header
                          Container(
                            width: 54 * scale,
                            height: 54 * scale,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.medication_rounded,
                                color: primaryAccent,
                                size: 28 * scale,
                              ),
                            ),
                          ),

                          SizedBox(height: 16 * scale),

                          // Title & Subtitle
                          Text(
                            'Register your pharmacy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26 * scale,
                              fontWeight: FontWeight.w800,
                              color: darkText,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 8 * scale),
                          const Text(
                            'Tell us about your pharmacy so we\ncan get you set up.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: textMuted,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          SizedBox(height: 24 * scale),

                          _buildCustomTextField(
                            controller: _pharmacyNameController,
                            hintText: 'Pharmacy / business name',
                            icon: Icons.storefront_outlined,
                          ),
                          SizedBox(height: 12 * scale),
                          _buildCustomTextField(
                            controller: _contactNameController,
                            hintText: 'Contact person name',
                            icon: Icons.person_outline_rounded,
                          ),
                          SizedBox(height: 12 * scale),
                          _buildCustomTextField(
                            controller: _emailController,
                            hintText: 'pharmacy@email.co.uk',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 12 * scale),
                          _buildCustomTextField(
                            controller: _phoneController,
                            hintText: '07xxx xxx xxx',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          SizedBox(height: 12 * scale),
                          _buildCustomTextField(
                            controller: _addressController,
                            hintText: 'Business address',
                            icon: Icons.location_on_outlined,
                          ),

                          SizedBox(height: 20 * scale),

                          // GPhC Registration Field
                          _buildAdminReviewedField(
                            label: 'GPhC registration\nnumber',
                            child: _buildCustomTextField(
                              controller: _gphcController,
                              hintText: 'e.g. 1234567',
                              icon: Icons.check_circle_outline_rounded,
                              isHighlighted: true,
                            ),
                          ),

                          SizedBox(height: 20 * scale),

                          // License Upload Section
                          _buildAdminReviewedField(
                            label: 'License or\ncertificate',
                            child: InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: lightBackground,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.file_upload_outlined,
                                        color: darkText,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Upload document',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: darkText,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'PDF or photo, max 10MB',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 12 * scale),

                          _buildCustomTextField(
                            controller: _passwordController,
                            hintText: 'Create a password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),

                          SizedBox(height: 16 * scale),

                          _buildTermsCheckbox(scale),

                          SizedBox(height: 24 * scale),

                          // Submit Button
                          BlocBuilder<PharmacySignupBloc, PharmacySignupState>(
                            builder: (context, state) {
                              final isLoading =
                                  state is PharmacySignupLoading;
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
                                          'Submit for review',
                                          style: TextStyle(
                                            fontSize: 16 * scale,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: 16 * scale),

                          _buildReviewNoticeCard(),

                          SizedBox(height: 20 * scale),
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

  Widget _buildAdminReviewedField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: darkText,
                height: 1.2,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD3EBE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined,
                      size: 13, color: Colors.teal.shade800),
                  const SizedBox(width: 4),
                  Text(
                    'Reviewed by admin',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool isHighlighted = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isHighlighted
            ? Border.all(
                color: primaryAccent.withValues(alpha: 0.6), width: 1.5)
            : null,
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

  Widget _buildTermsCheckbox(double scale) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeToTerms,
            activeColor: primaryAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            onChanged: (val) {
              if (val != null) setState(() => _agreeToTerms = val);
            },
          ),
        ),
        SizedBox(width: 10 * scale),
        Expanded(
          child: RichText(
            text: TextSpan(
              style:
                  const TextStyle(fontSize: 12, color: darkText, height: 1.4),
              children: const [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: primaryAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text:
                      ' and confirm the details above are accurate.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, size: 18, color: textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text:
                        'Our team reviews new pharmacies within 1 business day. You\'ll get an email ',
                  ),
                  TextSpan(
                    text: 'once approved.',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: darkText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
