import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/rider_signup/rider_signup_bloc.dart';
import '../bloc/rider_signup/rider_signup_event.dart';
import '../bloc/rider_signup/rider_signup_state.dart';
import 'rider_login_screen.dart';

class RiderSignupScreen extends StatefulWidget {
  const RiderSignupScreen({super.key});

  @override
  State<RiderSignupScreen> createState() => _RiderSignupScreenState();
}

class _RiderSignupScreenState extends State<RiderSignupScreen> {
  bool _agreeToTerms = false;
  bool _obscurePassword = true;

  String _selectedVehicle = 'Bike';
  File? _licenseFront;
  File? _licenseBack;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleRegController = TextEditingController();
  final _passwordController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehicleRegController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms of Service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_licenseFront == null || _licenseBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both the front and back of your driving licence'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<RiderSignupBloc>().add(RiderSignupSubmitted(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          vehicleType: _selectedVehicle,
          vehicleReg: _vehicleRegController.text.trim(),
          password: _passwordController.text,
          licenseFront: _licenseFront,
          licenseBack: _licenseBack,
        ));
  }

  Future<void> _pickLicenseDocument({required bool isFront}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
    );

    if (picked != null) {
      setState(() {
        if (isFront) {
          _licenseFront = File(picked.path);
        } else {
          _licenseBack = File(picked.path);
        }
      });
    }
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
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final cs = theme.colorScheme;
          final isDark = theme.brightness == Brightness.dark;

          return BlocProvider(
            create: (_) => RiderSignupBloc(),
            child: Builder(
              builder: (context) {
                return Scaffold(
                  backgroundColor: isDark
                      ? const Color(0xFF0C1310)
                      : theme.scaffoldBackgroundColor,
                  body: SafeArea(
                    child: BlocListener<RiderSignupBloc, RiderSignupState>(
                      listener: (context, state) {
                        if (state is RiderSignupSuccess) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Your request for approval sent successfully to admin.',
                              ),
                              backgroundColor: Color(0xFF0F7253),
                              duration: Duration(seconds: 4),
                            ),
                          );
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: isDark
                                  ? const Color(0xFF151E1A)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 12),
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F7253)
                                          .withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_outline,
                                      color: Color(0xFF0F7253),
                                      size: 38,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Approval Request Sent',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Your request for approval sent successfully to admin. Once approved, you will receive an email and can log into your account.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFF8B9B94)
                                          : const Color(0xFF6E7A75),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF0F7253),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        Navigator.of(context)
                                            .pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RiderLoginScreen(),
                                          ),
                                          (route) => route.isFirst,
                                        );
                                      },
                                      child: const Text(
                                        'Back to Login',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (state is RiderSignupFailure) {
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
                            constraints:
                                const BoxConstraints(maxWidth: 480),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildTopBar(context, cs, isDark),

                                  SizedBox(height: 16 * scale),

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
                                    'Become a rider',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 26 * scale,
                                      fontWeight: FontWeight.w800,
                                      color: cs.onSurface,
                                      height: 1.15,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 8 * scale),
                                  Text(
                                    'Set up your account to start\ndelivering prescriptions.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: cs.onSurfaceVariant,
                                      height: 1.3,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  SizedBox(height: 24 * scale),

                                  _buildCustomTextField(
                                    controller: _fullNameController,
                                    hintText: 'Full name',
                                    icon: Icons.person_outline_rounded,
                                    isDark: isDark,
                                    validator: (v) => _validateRequired(v, 'Full name'),
                                  ),
                                  SizedBox(height: 12 * scale),
                                  _buildCustomTextField(
                                    controller: _emailController,
                                    hintText: 'you@email.co.uk',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    isDark: isDark,
                                    validator: _validateEmail,
                                  ),
                                  SizedBox(height: 12 * scale),
                                  _buildCustomTextField(
                                    controller: _phoneController,
                                    hintText: '07xxx xxx xxx',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    isDark: isDark,
                                    validator: (v) => _validateRequired(v, 'Phone number'),
                                  ),

                                  SizedBox(height: 20 * scale),

                                  _buildVehicleTypeSelector(scale, isDark),

                                  SizedBox(height: 12 * scale),

                                  _buildCustomTextField(
                                    controller: _vehicleRegController,
                                    hintText: 'Vehicle registration number',
                                    icon: Icons.directions_car_outlined,
                                    isDark: isDark,
                                    validator: (v) => _validateRequired(v, 'Vehicle registration'),
                                  ),

                                  SizedBox(height: 20 * scale),

                                  _buildAdminReviewedField(
                                    label: 'Driving licence — Front',
                                    isDark: isDark,
                                    child: _buildLicenceUploadCard(
                                      file: _licenseFront,
                                      isDark: isDark,
                                      cs: cs,
                                      label: 'Front of licence',
                                      sublabel: 'Photo, max 10MB',
                                      isFront: true,
                                    ),
                                  ),

                                  SizedBox(height: 12 * scale),

                                  _buildAdminReviewedField(
                                    label: 'Driving licence — Back',
                                    isDark: isDark,
                                    child: _buildLicenceUploadCard(
                                      file: _licenseBack,
                                      isDark: isDark,
                                      cs: cs,
                                      label: 'Back of licence',
                                      sublabel: 'Photo, max 10MB',
                                      isFront: false,
                                    ),
                                  ),

                                  SizedBox(height: 12 * scale),

                                  _buildCustomTextField(
                                    controller: _passwordController,
                                    hintText: 'Create a password',
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true,
                                    isDark: isDark,
                                    validator: _validatePassword,
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                      child: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: isDark
                                            ? const Color(0xFF6E9585)
                                            : const Color(0xFF6E7A75),
                                        size: 22,
                                      ),
                                    ),
                                    obscureText: _obscurePassword,
                                  ),

                                  SizedBox(height: 12 * scale),

                                  _buildTermsCheckbox(scale, isDark, cs),

                                  SizedBox(height: 24 * scale),

                                  BlocBuilder<RiderSignupBloc,
                                      RiderSignupState>(
                                    builder: (context, state) {
                                      final isLoading =
                                          state is RiderSignupLoading;
                                      return InkWell(
                                        onTap: isLoading
                                            ? null
                                            : () => _submit(context),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets
                                              .symmetric(vertical: 16),
                                          decoration: BoxDecoration(
                                            color: isLoading
                                                ? (isDark
                                                    ? const Color(
                                                        0xFF1A3D2E)
                                                    : const Color(
                                                        0xFF8DCDB1))
                                                : const Color(0xFF0F7253),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Center(
                                            child: isLoading
                                                ? const SizedBox(
                                                    height: 22,
                                                    width: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                                  )
                                                : Text(
                                                    'Submit for approval',
                                                    style: TextStyle(
                                                      fontSize: 16 * scale,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  SizedBox(height: 16 * scale),

                                  _buildReviewNoticeCard(isDark),

                                  SizedBox(height: 20 * scale),

                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account? ',
                                        style: TextStyle(
                                          color: cs.onSurfaceVariant,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: const Text(
                                          'Log in',
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
                  ),
                );
              },
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

  Widget _buildAdminReviewedField({
    required String label,
    required Widget child,
    required bool isDark,
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFFD1DDD7) : const Color(0xFF191C1B),
                height: 1.2,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F7253).withValues(alpha: 0.18)
                    : const Color(0xFFE6F5ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined,
                      size: 13,
                      color: isDark
                          ? const Color(0xFF32C787)
                          : const Color(0xFF0F7253)),
                  const SizedBox(width: 4),
                  Text(
                    'Reviewed by admin',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF32C787)
                          : const Color(0xFF0F7253),
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
    required bool isDark,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    final side = BorderSide(
      color: isDark ? const Color(0xFF1D322A) : const Color(0xFFE2E8E5),
    );
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      keyboardType: keyboardType,
      validator: validator,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(
          icon,
          color: isDark ? const Color(0xFF6E9585) : const Color(0xFF6E7A75),
          size: 22,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildVehicleTypeSelector(double scale, bool isDark) {
    final types = [
      {'name': 'Bike', 'icon': Icons.directions_bike_rounded},
      {'name': 'Car', 'icon': Icons.directions_car_rounded},
      {'name': 'Scooter', 'icon': Icons.moped_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFD1DDD7) : const Color(0xFF191C1B),
          ),
        ),
        SizedBox(height: 8 * scale),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A2520) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF1D322A) : const Color(0xFFE2E8E5),
            ),
          ),
          child: Row(
            children: types.map((type) {
              final isSelected = _selectedVehicle == type['name'];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedVehicle = type['name'] as String;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 10 * scale),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0F7253)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          type['icon'] as IconData,
                          size: 20 * scale,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? const Color(0xFF8B9B94)
                                  : Colors.grey.shade600),
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          type['name'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? const Color(0xFF8B9B94)
                                    : Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLicenceUploadCard({
    required File? file,
    required bool isDark,
    required ColorScheme cs,
    required String label,
    required String sublabel,
    required bool isFront,
  }) {
    return InkWell(
      onTap: () => _pickLicenseDocument(isFront: isFront),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151E1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: file != null
                ? const Color(0xFF0F7253)
                : (isDark
                    ? const Color(0xFF1D322A)
                    : const Color(0xFFE2E8E5)),
          ),
        ),
        child: file != null
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F7253).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF0F7253),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$label uploaded',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to change',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF8B9B94)
                                : const Color(0xFF6E7A75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? const Color(0xFF8B9B94)
                        : const Color(0xFF6E7A75),
                    size: 22,
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F7253).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.file_upload_outlined,
                      color: isDark
                          ? const Color(0xFF32C787)
                          : const Color(0xFF0F7253),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sublabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF8B9B94)
                                : const Color(0xFF6E7A75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTermsCheckbox(double scale, bool isDark, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeToTerms,
            activeColor: const Color(0xFF0F7253),
            checkColor: Colors.white,
            side: BorderSide(
              color: isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
            ),
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
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFFD1DDD7) : const Color(0xFF191C1B),
                height: 1.4,
              ),
              children: const [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: Color(0xFF0F7253),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text:
                      ' and consent to a right-to-work and background check.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewNoticeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151E1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded,
              size: 18,
              color:
                  isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75)),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color:
                      isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(
                    text:
                        'Our team reviews new riders within 1 business day. Once approved, you\'ll receive an email with instructions to log in.',
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
