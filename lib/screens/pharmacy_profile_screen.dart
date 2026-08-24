import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_event.dart';
import '../bloc/theme/theme_state.dart';

class PharmacyProfileScreen extends StatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  State<PharmacyProfileScreen> createState() => _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState extends State<PharmacyProfileScreen> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C1310) : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0C1310) : theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: cs.onSurface),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _buildProfileHeader(context, cs, isDark),
            const SizedBox(height: 20),
            _sectionTitle('Pharmacy Information', cs),
            const SizedBox(height: 12),
            _buildInformationCard(context, cs, isDark),
            const SizedBox(height: 22),
            _sectionTitle('Business Details', cs),
            const SizedBox(height: 12),
            _buildBusinessCard(context, cs, isDark),
            const SizedBox(height: 22),
            _sectionTitle('Account', cs),
            const SizedBox(height: 12),
            _buildAccountCard(context, cs, isDark),
            const SizedBox(height: 22),
            _buildLogoutButton(cs, isDark),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, ColorScheme cs) {
    return Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface));
  }

  Widget _buildProfileHeader(BuildContext context, ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showImageOptions,
            child: Stack(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _profileImage != null
                      ? Image.file(_profileImage!, fit: BoxFit.cover)
                      : Icon(Icons.local_pharmacy_outlined, size: 38, color: cs.onSurfaceVariant),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F7253),
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).cardColor, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(pharmacyName, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 5),
          Text(pharmacistName, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: pharmacyOpen
                  ? (isDark ? const Color(0xFF15301D) : Colors.green.shade50)
                  : (isDark ? const Color(0xFF2D1B1B) : Colors.red.shade50),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: pharmacyOpen ? Colors.green.shade600 : Colors.red.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  pharmacyOpen ? 'Pharmacy Open' : 'Pharmacy Closed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: pharmacyOpen ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _showEditProfile,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurface,
                side: BorderSide(color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard(BuildContext context, ColorScheme cs, bool isDark) {
    return _sectionCard(context, cs, isDark, children: [
      _informationRow(icon: Icons.person_outline, title: 'Pharmacist', value: pharmacistName, cs: cs, isDark: isDark),
      _divider(isDark),
      _informationRow(icon: Icons.phone_outlined, title: 'Phone', value: phone, cs: cs, isDark: isDark),
      _divider(isDark),
      _informationRow(icon: Icons.email_outlined, title: 'Email', value: email, cs: cs, isDark: isDark),
      _divider(isDark),
      _informationRow(icon: Icons.location_on_outlined, title: 'Address', value: address, cs: cs, isDark: isDark),
    ]);
  }

  Widget _buildBusinessCard(BuildContext context, ColorScheme cs, bool isDark) {
    return _sectionCard(context, cs, isDark, children: [
      _informationRow(icon: Icons.badge_outlined, title: 'License Number', value: licenseNumber, cs: cs, isDark: isDark),
      _divider(isDark),
      _informationRow(icon: Icons.access_time_outlined, title: 'Opening Time', value: openingTime, cs: cs, isDark: isDark),
      _divider(isDark),
      _informationRow(icon: Icons.access_time_filled_outlined, title: 'Closing Time', value: closingTime, cs: cs, isDark: isDark),
      _divider(isDark),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(Icons.storefront_outlined, color: cs.onSurfaceVariant),
        title: Text('Pharmacy Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
        subtitle: Text(
          pharmacyOpen ? 'Currently open' : 'Currently closed',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        value: pharmacyOpen,
        activeThumbColor: const Color(0xFF0F7253),
        onChanged: (value) => setState(() => pharmacyOpen = value),
      ),
    ]);
  }

  Widget _buildAccountCard(BuildContext context, ColorScheme cs, bool isDark) {
    return _sectionCard(context, cs, isDark, children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.lock_outline, color: cs.onSurfaceVariant),
        title: Text('Change Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
        subtitle: Text('Update your account password', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        onTap: _showChangePassword,
      ),
      _divider(isDark),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(Icons.notifications_none_outlined, color: cs.onSurfaceVariant),
        title: Text('Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
        subtitle: Text(
          notificationsEnabled ? 'Notifications are enabled' : 'Notifications are disabled',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        value: notificationsEnabled,
        activeThumbColor: const Color(0xFF0F7253),
        onChanged: (value) => setState(() => notificationsEnabled = value),
      ),
      _divider(isDark),
      BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final isDarkMode = themeState is ThemeDark;
          return SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: cs.onSurfaceVariant,
            ),
            title: Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
            subtitle: Text(
              isDarkMode ? 'Dark theme active' : 'Light theme active',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            value: isDarkMode,
            activeThumbColor: const Color(0xFF0F7253),
            onChanged: (_) => context.read<ThemeBloc>().add(ThemeToggled()),
          );
        },
      ),
    ]);
  }

  Widget _sectionCard(BuildContext context, ColorScheme cs, bool isDark, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _informationRow({
    required IconData icon,
    required String title,
    required String value,
    required ColorScheme cs,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                const SizedBox(height: 3),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(height: 1, color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200);
  }

  Widget _buildLogoutButton(ColorScheme cs, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _showLogoutConfirmation,
        icon: Icon(Icons.logout_rounded, color: Colors.red.shade600),
        label: Text('Logout', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isDark ? const Color(0xFF2D1B1B) : Colors.red.shade200),
          backgroundColor: isDark ? const Color(0xFF2D1B1B) : Colors.red.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  void _showEditProfile() {
    final cs = Theme.of(context).colorScheme;
    final pharmacyCtrl = TextEditingController(text: pharmacyName);
    final pharmacistCtrl = TextEditingController(text: pharmacistName);
    final phoneCtrl = TextEditingController(text: phone);
    final emailCtrl = TextEditingController(text: email);
    final addressCtrl = TextEditingController(text: address);
    final licenseCtrl = TextEditingController(text: licenseNumber);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const SizedBox(height: 20),
                  _profileField(controller: pharmacyCtrl, label: 'Pharmacy Name', icon: Icons.local_pharmacy_outlined, context: context),
                  const SizedBox(height: 13),
                  _profileField(controller: pharmacistCtrl, label: 'Pharmacist Name', icon: Icons.person_outline, context: context),
                  const SizedBox(height: 13),
                  _profileField(controller: phoneCtrl, label: 'Phone', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, context: context),
                  const SizedBox(height: 13),
                  _profileField(controller: emailCtrl, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, context: context),
                  const SizedBox(height: 13),
                  _profileField(controller: addressCtrl, label: 'Address', icon: Icons.location_on_outlined, context: context),
                  const SizedBox(height: 13),
                  _profileField(controller: licenseCtrl, label: 'License Number', icon: Icons.badge_outlined, context: context),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          pharmacyName = pharmacyCtrl.text.trim();
                          pharmacistName = pharmacistCtrl.text.trim();
                          phone = phoneCtrl.text.trim();
                          email = emailCtrl.text.trim();
                          address = addressCtrl.text.trim();
                          licenseNumber = licenseCtrl.text.trim();
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F7253),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required BuildContext context,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        prefixIcon: Icon(icon, color: cs.onSurfaceVariant),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: const Color(0xFF0F7253))),
      ),
    );
  }

  void _showChangePassword() {
    final cs = Theme.of(context).colorScheme;
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 20),
                _passwordField(controller: currentCtrl, hint: 'Current password', context: context),
                const SizedBox(height: 13),
                _passwordField(controller: newCtrl, hint: 'New password', context: context),
                const SizedBox(height: 13),
                _passwordField(controller: confirmCtrl, hint: 'Confirm new password', context: context),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (newCtrl.text.isEmpty || confirmCtrl.text.isEmpty) return;
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
                        return;
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F7253),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required BuildContext context,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      obscureText: true,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
        prefixIcon: Icon(Icons.lock_outline, color: cs.onSurfaceVariant),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: const Color(0xFF0F7253))),
      ),
    );
  }

  void _showLogoutConfirmation() {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Logout', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface)),
          content: Text('Are you sure you want to logout?', style: TextStyle(color: cs.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logout functionality will be connected later.')),
                );
              },
              child: Text('Logout', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _showImageOptions() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Profile Photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2744) : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.camera_alt_outlined, color: Colors.blue.shade600),
                  ),
                  title: Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                  subtitle: Text('Capture using camera', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF15301D) : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.photo_library_outlined, color: Colors.green.shade600),
                  ),
                  title: Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                  subtitle: Text('Select from device', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_profileImage != null) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2D1B1B) : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.delete_outline, color: Colors.red.shade600),
                    ),
                    title: Text('Remove Photo', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade600)),
                    subtitle: Text('Delete profile photo', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _profileImage = null);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo removed.')));
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

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
      }
    }
  }
}
