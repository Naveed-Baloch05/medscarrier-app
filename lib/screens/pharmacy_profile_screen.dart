import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_event.dart';
import '../bloc/theme/theme_state.dart';

class PharmacyProfileScreen extends StatefulWidget {
  const PharmacyProfileScreen({
    super.key,
  });

  @override
  State<PharmacyProfileScreen> createState() =>
      _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState
    extends State<PharmacyProfileScreen> {
  // ============================================================
  // TEMPORARY PROFILE DATA
  // Backend will be connected later.
  // ============================================================

  String pharmacyName = 'MedCare Pharmacy';
  String pharmacistName = 'Naveed Baloch';
  String phone = '+92 300 1234567';
  String email = 'pharmacy@example.com';
  String address = 'Main Market, Pakistan';
  String licenseNumber = 'PH-2026-00125';
  String openingTime = '09:00 AM';
  String closingTime = '10:00 PM';

  bool notificationsEnabled = true;
  bool pharmacyOpen = true;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          children: [

            // ======================================================
            // PROFILE HEADER
            // ======================================================

            _buildProfileHeader(),

            const SizedBox(height: 20),

            // ======================================================
            // PHARMACY INFORMATION
            // ======================================================

            const Text(
              'Pharmacy Information',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            _buildInformationCard(),

            const SizedBox(height: 22),

            // ======================================================
            // BUSINESS DETAILS
            // ======================================================

            const Text(
              'Business Details',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            _buildBusinessCard(),

            const SizedBox(height: 22),

            // ======================================================
            // ACCOUNT
            // ======================================================

            const Text(
              'Account',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            _buildAccountCard(),

            const SizedBox(height: 22),

            // ======================================================
            // LOGOUT
            // ======================================================

            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        children: [
          // ------------------------------------------------------
          // PROFILE IMAGE
          // ------------------------------------------------------

          GestureDetector(
            onTap: _showImageOptions,
            child: Stack(
              children: [
                Container(
                  width: 78,
                  height: 78,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),

                  clipBehavior: Clip.antiAlias,

                  child: _profileImage != null
                      ? Image.file(
                          _profileImage!,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.local_pharmacy_outlined,
                          size: 38,
                          color: Colors.grey.shade700,
                        ),
                ),

                Positioned(
                  bottom: 0,
                  right: 0,

                  child: Container(
                    width: 28,
                    height: 28,

                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),

                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // PHARMACY NAME
          // ------------------------------------------------------

          Text(
            pharmacyName,
            textAlign: TextAlign.center,

            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          // ------------------------------------------------------
          // PHARMACIST
          // ------------------------------------------------------

          Text(
            pharmacistName,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // STATUS
          // ------------------------------------------------------

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),

            decoration: BoxDecoration(
              color: pharmacyOpen
                  ? Colors.green.shade50
                  : Colors.red.shade50,

              borderRadius: BorderRadius.circular(20),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,

              children: [
                Container(
                  width: 7,
                  height: 7,

                  decoration: BoxDecoration(
                    color: pharmacyOpen
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 7),

                Text(
                  pharmacyOpen
                      ? 'Pharmacy Open'
                      : 'Pharmacy Closed',

                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: pharmacyOpen
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ------------------------------------------------------
          // EDIT PROFILE
          // ------------------------------------------------------

          SizedBox(
            width: double.infinity,
            height: 46,

            child: OutlinedButton.icon(
              onPressed: () {
                _showEditProfile();
              },

              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
              ),

              label: const Text(
                'Edit Profile',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,

                side: BorderSide(
                  color: Colors.grey.shade300,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _buildInformationCard() {
    return _sectionCard(
      children: [
        _informationRow(
          icon: Icons.person_outline,
          title: 'Pharmacist',
          value: pharmacistName,
        ),

        _divider(),

        _informationRow(
          icon: Icons.phone_outlined,
          title: 'Phone',
          value: phone,
        ),

        _divider(),

        _informationRow(
          icon: Icons.email_outlined,
          title: 'Email',
          value: email,
        ),

        _divider(),

        _informationRow(
          icon: Icons.location_on_outlined,
          title: 'Address',
          value: address,
        ),
      ],
    );
  }

  // ============================================================
  // BUSINESS CARD
  // ============================================================

  Widget _buildBusinessCard() {
    return _sectionCard(
      children: [
        _informationRow(
          icon: Icons.badge_outlined,
          title: 'License Number',
          value: licenseNumber,
        ),

        _divider(),

        _informationRow(
          icon: Icons.access_time_outlined,
          title: 'Opening Time',
          value: openingTime,
        ),

        _divider(),

        _informationRow(
          icon: Icons.access_time_filled_outlined,
          title: 'Closing Time',
          value: closingTime,
        ),

        _divider(),

        // ------------------------------------------------------
        // OPEN / CLOSED SWITCH
        // ------------------------------------------------------

        SwitchListTile(
          contentPadding: EdgeInsets.zero,

          secondary: Icon(
            Icons.storefront_outlined,
            color: Colors.grey.shade700,
          ),

          title: const Text(
            'Pharmacy Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          subtitle: Text(
            pharmacyOpen
                ? 'Currently open'
                : 'Currently closed',

            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),

          value: pharmacyOpen,

          activeThumbColor: Colors.black,

          onChanged: (value) {
            setState(() {
              pharmacyOpen = value;
            });
          },
        ),
      ],
    );
  }

  // ============================================================
  // ACCOUNT CARD
  // ============================================================

  Widget _buildAccountCard() {
    return _sectionCard(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,

          leading: Icon(
            Icons.lock_outline,
            color: Colors.grey.shade700,
          ),

          title: const Text(
            'Change Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          subtitle: Text(
            'Update your account password',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),

          trailing: const Icon(
            Icons.chevron_right_rounded,
          ),

          onTap: () {
            _showChangePassword();
          },
        ),

        _divider(),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,

          secondary: Icon(
            Icons.notifications_none_outlined,
            color: Colors.grey.shade700,
          ),

          title: const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          subtitle: Text(
            notificationsEnabled
                ? 'Notifications are enabled'
                : 'Notifications are disabled',

            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),

          value: notificationsEnabled,

          activeThumbColor: Colors.black,

          onChanged: (value) {
            setState(() {
              notificationsEnabled = value;
            });
          },
        ),

        _divider(),

        // ------------------------------------------------------
        // THEME TOGGLE
        // ------------------------------------------------------

        BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final isDark = themeState is ThemeDark;

            return SwitchListTile(
              contentPadding: EdgeInsets.zero,

              secondary: Icon(
                isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                color: Colors.grey.shade700,
              ),

              title: const Text(
                'Dark Mode',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              subtitle: Text(
                isDark ? 'Dark theme active' : 'Light theme active',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),

              value: isDark,

              activeThumbColor: Colors.black,

              onChanged: (_) {
                context.read<ThemeBloc>().add(ThemeToggled());
              },
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        children: children,
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _informationRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
              BorderRadius.circular(11),
            ),

            child: Icon(
              icon,
              size: 19,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _divider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
    );
  }

  // ============================================================
  // LOGOUT BUTTON
  // ============================================================

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,

      child: OutlinedButton.icon(
        onPressed: () {
          _showLogoutConfirmation();
        },

        icon: Icon(
          Icons.logout_rounded,
          color: Colors.red.shade600,
        ),

        label: Text(
          'Logout',
          style: TextStyle(
            color: Colors.red.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),

        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Colors.red.shade200,
          ),

          backgroundColor: Colors.red.shade50,

          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  void _showEditProfile() {
    final pharmacyCtrl =
    TextEditingController(text: pharmacyName);

    final pharmacistCtrl =
    TextEditingController(text: pharmacistName);

    final phoneCtrl =
    TextEditingController(text: phone);

    final emailCtrl =
    TextEditingController(text: email);

    final addressCtrl =
    TextEditingController(text: address);

    final licenseCtrl =
    TextEditingController(text: licenseNumber);

    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.white,

      isScrollControlled: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(ctx)
                  .viewInsets
                  .bottom +
                  24,
            ),

            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,

                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _profileField(
                    controller: pharmacyCtrl,
                    label: 'Pharmacy Name',
                    icon: Icons.local_pharmacy_outlined,
                  ),

                  const SizedBox(height: 13),

                  _profileField(
                    controller: pharmacistCtrl,
                    label: 'Pharmacist Name',
                    icon: Icons.person_outline,
                  ),

                  const SizedBox(height: 13),

                  _profileField(
                    controller: phoneCtrl,
                    label: 'Phone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 13),

                  _profileField(
                    controller: emailCtrl,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 13),

                  _profileField(
                    controller: addressCtrl,
                    label: 'Address',
                    icon: Icons.location_on_outlined,
                  ),

                  const SizedBox(height: 13),

                  _profileField(
                    controller: licenseCtrl,
                    label: 'License Number',
                    icon: Icons.badge_outlined,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          pharmacyName =
                              pharmacyCtrl.text.trim();

                          pharmacistName =
                              pharmacistCtrl.text.trim();

                          phone =
                              phoneCtrl.text.trim();

                          email =
                              emailCtrl.text.trim();

                          address =
                              addressCtrl.text.trim();

                          licenseNumber =
                              licenseCtrl.text.trim();
                        });

                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Profile updated.',
                            ),
                          ),
                        );
                      },

                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,

                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                      ),

                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PROFILE FIELD
  // ============================================================

  Widget _profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,

      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(
          icon,
          color: Colors.grey.shade600,
        ),

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  void _showChangePassword() {
    final currentCtrl =
    TextEditingController();

    final newCtrl =
    TextEditingController();

    final confirmCtrl =
    TextEditingController();

    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.white,

      isScrollControlled: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(ctx)
                  .viewInsets
                  .bottom +
                  24,
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 20),

                _passwordField(
                  controller: currentCtrl,
                  hint: 'Current password',
                ),

                const SizedBox(height: 13),

                _passwordField(
                  controller: newCtrl,
                  hint: 'New password',
                ),

                const SizedBox(height: 13),

                _passwordField(
                  controller: confirmCtrl,
                  hint: 'Confirm new password',
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton(
                    onPressed: () {
                      if (newCtrl.text.isEmpty ||
                          confirmCtrl.text.isEmpty) {
                        return;
                      }

                      if (newCtrl.text !=
                          confirmCtrl.text) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Passwords do not match.',
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(ctx);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password updated.',
                          ),
                        ),
                      );
                    },

                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),

                    child: const Text(
                      'Update Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PASSWORD FIELD
  // ============================================================

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,

      decoration: InputDecoration(
        hintText: hint,

        prefixIcon: const Icon(
          Icons.lock_outline,
        ),

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT CONFIRMATION
  // ============================================================

  void _showLogoutConfirmation() {
    showDialog(
      context: context,

      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),

          content: const Text(
            'Are you sure you want to logout?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },

              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(ctx);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Logout functionality will be connected later.',
                    ),
                  ),
                );
              },

              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // IMAGE OPTIONS
  // ============================================================

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24,
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,

                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,

                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius:
                      BorderRadius.circular(12),
                    ),

                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.blue.shade600,
                    ),
                  ),

                  title: const Text(
                    'Take Photo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  subtitle: Text(
                    'Capture using camera',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),

                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),

                const SizedBox(height: 8),

                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,

                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius:
                      BorderRadius.circular(12),
                    ),

                    child: Icon(
                      Icons.photo_library_outlined,
                      color: Colors.green.shade600,
                    ),
                  ),

                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  subtitle: Text(
                    'Select from device',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),

                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),

                if (_profileImage != null) ...[
                  const SizedBox(height: 8),

                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,

                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius:
                        BorderRadius.circular(12),
                      ),

                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade600,
                      ),
                    ),

                    title: Text(
                      'Remove Photo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
                    ),

                    subtitle: Text(
                      'Delete profile photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _profileImage = null;
                      });

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Profile photo removed.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated.'),
          ),
        );
      }
    }
  }
}