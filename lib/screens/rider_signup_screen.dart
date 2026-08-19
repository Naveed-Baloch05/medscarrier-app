import 'package:flutter/material.dart';

class RiderSignupScreen extends StatefulWidget {
  const RiderSignupScreen({super.key});

  @override
  State<RiderSignupScreen> createState() => _RiderSignupScreenState();
}

class _RiderSignupScreenState extends State<RiderSignupScreen> {
  static const Color primaryAccent = Color(0xFFE05333);
  static const Color lightBackground = Color(0xFFEFF3F2);
  static const Color darkText = Color(0xFF0F231F);
  static const Color textMuted = Color(0xFF6B7280);

  String _selectedVehicle = 'Bike';
  bool _agreeToTerms = true;

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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTopBar(context),

                  SizedBox(height: 20 * scale),

                  _buildProfilePhotoPicker(scale),

                  SizedBox(height: 16 * scale),

                  Text(
                    'Become a rider',
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
                    'Set up your account to start delivering.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 24 * scale),

                  _buildCustomTextField(
                    hintText: 'Full name',
                    icon: Icons.person_outline_rounded,
                  ),
                  SizedBox(height: 12 * scale),
                  _buildCustomTextField(
                    hintText: 'you@email.co.uk',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 12 * scale),
                  _buildCustomTextField(
                    hintText: '07xxx xxx xxx',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  SizedBox(height: 20 * scale),

                  _buildVehicleTypeSelector(scale),

                  SizedBox(height: 12 * scale),

                  _buildCustomTextField(
                    hintText: 'Vehicle registration number',
                    icon: Icons.payment_rounded,
                  ),

                  SizedBox(height: 20 * scale),

                  _buildUploadLicenceSection(),

                  SizedBox(height: 12 * scale),

                  _buildCustomTextField(
                    hintText: 'Create a password',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                  ),

                  SizedBox(height: 16 * scale),

                  _buildTermsCheckbox(scale),

                  SizedBox(height: 24 * scale),

                  SizedBox(
                    width: double.infinity,
                    height: 54 * scale,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: primaryAccent.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'Submit for review',
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16 * scale),

                  _buildVerificationCard(),

                  SizedBox(height: 24 * scale),

                  // Bottom Login Navigation
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: textMuted, fontSize: 13.5),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Log in',
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
    );
  }

  // --- TOP BAR ---
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

  // --- PROFILE PHOTO PICKER ---
  Widget _buildProfilePhotoPicker(double scale) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 84 * scale,
              height: 84 * scale,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 42 * scale,
                color: Colors.black26,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: primaryAccent,
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
        const Text(
          'Add a profile photo',
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
      ],
    );
  }

  // --- TEXT INPUT FIELD ---
  Widget _buildCustomTextField({
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

  // --- VEHICLE SELECTOR ---
  Widget _buildVehicleTypeSelector(double scale) {
    final types = [
      {'name': 'Bike', 'icon': Icons.directions_bike_rounded},
      {'name': 'Car', 'icon': Icons.directions_car_rounded},
      {'name': 'Scooter', 'icon': Icons.moped_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
        SizedBox(height: 8 * scale),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
                      color: isSelected ? primaryAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          type['icon'] as IconData,
                          size: 20 * scale,
                          color:
                              isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          type['name'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
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

  // --- LICENCE UPLOAD FIELD ---
  Widget _buildUploadLicenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Driving licence',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 14, color: Colors.teal.shade700),
                const SizedBox(width: 4),
                Text(
                  'Reviewed by admin',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade800,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
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
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: lightBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.file_upload_outlined,
                    color: darkText,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload licence',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Front and back, max 10MB',
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
      ],
    );
  }

  // --- TERMS CHECKBOX ---
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
              style: TextStyle(
                fontSize: 12,
                color: darkText,
                height: 1.4,
              ),
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
                      ' and consent to a right-to-work and background check.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- VERIFICATION NOTICE CARD ---
  Widget _buildVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.access_time_rounded, size: 18, color: textMuted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "We'll verify your documents before you can go online for deliveries.",
              style: TextStyle(
                fontSize: 12,
                color: textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
