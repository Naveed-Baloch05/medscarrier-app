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
  String _selectedVehicle = 'Bike';
  bool _agreeToTerms = false;
  bool _obscurePassword = true;

  File? _profilePhoto;
  File? _drivingLicenceFront;
  File? _drivingLicenceBack;

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

    if (_drivingLicenceFront == null || _drivingLicenceBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both front and back of your driving licence'),
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
          profilePhoto: _profilePhoto,
          drivingLicenceFront: _drivingLicenceFront,
          drivingLicenceBack: _drivingLicenceBack,
        ));
  }

  Future<void> _pickProfilePhoto() async {
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
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() => _profilePhoto = File(picked.path));
    }
  }

  Future<void> _pickDrivingLicence({required bool isFront}) async {
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
          _drivingLicenceFront = File(picked.path);
        } else {
          _drivingLicenceBack = File(picked.path);
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
          surface: isDark ? const Color(0xFF151E1A) : const Color(0xFFFFFFFF),
          onSurface: isDark ? const Color(0xFFD1DDD7) : const Color(0xFF191C1B),
          onSurfaceVariant:
              isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75),
          outline: isDark ? const Color(0xFF1D322A) : const Color(0xFFE2E8E5),
          error: const Color(0xFFBA1A1A),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor:
            isDark ? const Color(0xFF0B120E) : const Color(0xFFF2F5F3),
      );

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;

    return BlocProvider(
      create: (_) => RiderSignupBloc(),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Theme(
            data: scaledTheme(isDark: isDark),
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final cs = theme.colorScheme;
                final isDark = theme.brightness == Brightness.dark;

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
                                'Application submitted successfully. Your account is waiting for admin approval.',
                              ),
                              backgroundColor: Color(0xFF0F7253),
                              duration: Duration(seconds: 4),
                            ),
                          );
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const RiderLoginScreen(),
                            ),
                            (route) => route.isFirst,
                          );
                        } else if (state is RiderSignupFailure) {
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
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildTopBar(context, cs, isDark),

                                  SizedBox(height: 20 * scale),

                                  _buildProfilePhotoPicker(scale, isDark, cs),

                                  SizedBox(height: 16 * scale),

                                  Text(
                                    'Become a rider',
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
                                    'Set up your account to start delivering.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  SizedBox(height: 24 * scale),

                                  _buildCustomTextField(
                                    controller: _fullNameController,
                                    hintText: 'Full name',
                                    icon: Icons.person_outline_rounded,
                                    isDark: isDark,
                                    cs: cs,
                                    validator: (v) => (v == null || v.trim().isEmpty)
                                        ? 'Full name is required'
                                        : null,
                                  ),
                                  SizedBox(height: 12 * scale),
                                  _buildCustomTextField(
                                    controller: _emailController,
                                    hintText: 'you@email.co.uk',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    isDark: isDark,
                                    cs: cs,
                                    validator: _validateEmail,
                                  ),
                                  SizedBox(height: 12 * scale),
                                  _buildCustomTextField(
                                    controller: _phoneController,
                                    hintText: '07xxx xxx xxx',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    isDark: isDark,
                                    cs: cs,
                                    validator: (v) => (v == null || v.trim().isEmpty)
                                        ? 'Phone number is required'
                                        : null,
                                  ),

                                  SizedBox(height: 20 * scale),

                                  _buildVehicleTypeSelector(scale, isDark, cs),

                                  SizedBox(height: 12 * scale),

                                  _buildCustomTextField(
                                    controller: _vehicleRegController,
                                    hintText: 'Vehicle registration number',
                                    icon: Icons.payment_rounded,
                                    isDark: isDark,
                                    cs: cs,
                                    validator: (v) => (v == null || v.trim().isEmpty)
                                        ? 'Vehicle registration is required'
                                        : null,
                                  ),

                                  SizedBox(height: 20 * scale),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Driving licence',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.shield_outlined,
                                              size: 14, color: Color(0xFF0F7253)),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Reviewed by admin',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0F7253),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10 * scale),

                                  _buildUploadLicenceSection(isDark, cs, scale, isFront: true),

                                  SizedBox(height: 10 * scale),

                                  _buildUploadLicenceSection(isDark, cs, scale, isFront: false),

                                  SizedBox(height: 12 * scale),

                                  _buildCustomTextField(
                                    controller: _passwordController,
                                    hintText: 'Create a password',
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true,
                                    isDark: isDark,
                                    cs: cs,
                                    validator: _validatePassword,
                                  ),

                                  SizedBox(height: 16 * scale),

                                  _buildTermsCheckbox(scale, cs),

                                  SizedBox(height: 24 * scale),

                                  BlocBuilder<RiderSignupBloc, RiderSignupState>(
                                    builder: (context, state) {
                                      final isLoading =
                                          state is RiderSignupLoading;
                                      return InkWell(
                                        onTap: isLoading ? null : () => _submit(context),
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isLoading
                                                ? (isDark
                                                    ? const Color(0xFF1A3D2E)
                                                    : const Color(0xFF8DCDB1))
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
                                                    'Submit for review',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16 * scale,
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

                                  _buildVerificationCard(isDark),

                                  SizedBox(height: 24 * scale),

                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
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

  Widget _buildProfilePhotoPicker(double scale, bool isDark, ColorScheme cs) {
    return GestureDetector(
      onTap: _pickProfilePhoto,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 84 * scale,
                height: 84 * scale,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF151E1A)
                      : Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1D322A) : Colors.white,
                    width: 2,
                  ),
                  image: _profilePhoto != null
                      ? DecorationImage(
                          image: FileImage(_profilePhoto!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _profilePhoto == null
                    ? Icon(
                        Icons.person_outline_rounded,
                        size: 42 * scale,
                        color: isDark
                            ? const Color(0xFF6E9585)
                            : const Color(0xFF6E7A75),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F7253),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _profilePhoto == null ? 'Add a profile photo' : 'Change photo',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? const Color(0xFF8B9B94)
                  : const Color(0xFF6E7A75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    required ColorScheme cs,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: cs.onSurface, fontSize: 15),
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
          borderSide: BorderSide(
            color:
                isDark ? const Color(0xFF1D322A) : const Color(0xFFE2E8E5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
                isDark ? const Color(0xFF1D322A) : const Color(0xFFE2E8E5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF0F7253), width: 1.5),
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
        suffixIcon: isPassword
            ? GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: isDark
                      ? const Color(0xFF6E9585)
                      : const Color(0xFF6E7A75),
                  size: 22,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildVehicleTypeSelector(
      double scale, bool isDark, ColorScheme cs) {
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
            color: cs.onSurface,
          ),
        ),
        SizedBox(height: 8 * scale),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151E1A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1D322A)
                  : const Color(0xFFE2E8E5),
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
                                  : const Color(0xFF6E7A75)),
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
                                    : const Color(0xFF6E7A75)),
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

  Widget _buildUploadLicenceSection(
      bool isDark, ColorScheme cs, double scale, {required bool isFront}) {
    final hasFile = isFront ? _drivingLicenceFront != null : _drivingLicenceBack != null;
    final label = isFront ? 'Front of licence' : 'Back of licence';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickDrivingLicence(isFront: isFront),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF151E1A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasFile
                    ? const Color(0xFF0F7253)
                    : (isDark
                        ? const Color(0xFF1D322A)
                        : const Color(0xFFE2E8E5)),
                style: BorderStyle.solid,
              ),
            ),
            child: hasFile
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
                              '${isFront ? "Front" : "Back"} uploaded',
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
                          color:
                              const Color(0xFF0F7253).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.file_upload_outlined,
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
                              'Upload ${isFront ? "front" : "back"}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Clear photo, max 10MB',
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
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox(double scale, ColorScheme cs) {
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
                color: cs.onSurface,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                const TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: Color(0xFF0F7253),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
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

  Widget _buildVerificationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF151E1A)
            : const Color(0xFFE6F5ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1D322A) : const Color(0xFF0F7253)
              .withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 18,
            color:
                isDark ? const Color(0xFF8B9B94) : const Color(0xFF0F7253),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "We'll verify your documents before you can go online for deliveries.",
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF8B9B94)
                    : const Color(0xFF191C1B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
