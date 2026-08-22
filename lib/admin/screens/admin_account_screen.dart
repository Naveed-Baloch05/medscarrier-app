import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_event.dart';
import '../../bloc/theme/theme_state.dart';

class AdminAccountScreen extends StatefulWidget {
  const AdminAccountScreen({super.key});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  String adminName = 'Admin User';
  String phone = '+92 300 1234567';
  String email = 'admin@medscarrier.com';

  bool notificationsEnabled = true;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark
        ? const Color(0xFF08100C)
        : const Color(0xFFF2F5F3);

    final cardColor = isDark
        ? const Color(0xFF0E1A14)
        : Colors.white;

    final textPrimary = isDark
        ? Colors.white
        : const Color(0xFF191C1B);

    final textSecondary = isDark
        ? const Color(0xFF8B9B94)
        : const Color(0xFF6E7A75);

    final primaryColor = isDark
        ? const Color(0xFF32C787)
        : const Color(0xFF0F7253);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Account',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textPrimary),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _buildProfileHeader(cardColor, borderColor, textPrimary, textSecondary, primaryColor, isDark),
            const SizedBox(height: 22),
            _sectionTitle('Personal Information', textPrimary),
            const SizedBox(height: 12),
            _buildInformationCard(cardColor, borderColor, textPrimary, textSecondary, primaryColor, isDark),
            const SizedBox(height: 22),
            _sectionTitle('Account', textPrimary),
            const SizedBox(height: 12),
            _buildAccountCard(cardColor, borderColor, textPrimary, textSecondary, primaryColor, isDark),
            const SizedBox(height: 22),
            _sectionTitle('Support', textPrimary),
            const SizedBox(height: 12),
            _buildSupportCard(cardColor, borderColor, textPrimary, textSecondary, primaryColor, isDark),
            const SizedBox(height: 22),
            _buildLogoutButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color textPrimary) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    );
  }

  Widget _buildProfileHeader(Color cardColor, Color borderColor, Color textPrimary, Color textSecondary, Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
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
                    color: isDark
                        ? const Color(0xFF18251F)
                        : const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _profileImage != null
                      ? Image.file(_profileImage!, fit: BoxFit.cover)
                      : Icon(Icons.admin_panel_settings_outlined, size: 38, color: primaryColor),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: cardColor, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(adminName, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 5),
          Text(email, style: TextStyle(fontSize: 13, color: textSecondary)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF15301D)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
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
                foregroundColor: textPrimary,
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard(Color cardColor, Color borderColor, Color textPrimary, Color textSecondary, Color primaryColor, bool isDark) {
    return _sectionCard(cardColor, borderColor, [
      _informationRow(icon: Icons.person_outline, title: 'Full Name', value: adminName, textPrimary: textPrimary, textSecondary: textSecondary, primaryColor: primaryColor, isDark: isDark),
      _divider(borderColor),
      _informationRow(icon: Icons.phone_outlined, title: 'Phone', value: phone, textPrimary: textPrimary, textSecondary: textSecondary, primaryColor: primaryColor, isDark: isDark),
      _divider(borderColor),
      _informationRow(icon: Icons.email_outlined, title: 'Email', value: email, textPrimary: textPrimary, textSecondary: textSecondary, primaryColor: primaryColor, isDark: isDark),
      _divider(borderColor),
      _informationRow(icon: Icons.admin_panel_settings_outlined, title: 'Role', value: 'Administrator', textPrimary: textPrimary, textSecondary: textSecondary, primaryColor: primaryColor, isDark: isDark),
    ]);
  }

  Widget _buildAccountCard(Color cardColor, Color borderColor, Color textPrimary, Color textSecondary, Color primaryColor, bool isDark) {
    return _sectionCard(cardColor, borderColor, [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.lock_outline, color: textSecondary),
        title: Text('Change Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
        subtitle: Text('Update your account password', style: TextStyle(fontSize: 12, color: textSecondary)),
        trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
        onTap: _showChangePassword,
      ),
      _divider(borderColor),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(Icons.notifications_none_outlined, color: textSecondary),
        title: Text('Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
        subtitle: Text(
          notificationsEnabled ? 'Notifications are enabled' : 'Notifications are disabled',
          style: TextStyle(fontSize: 12, color: textSecondary),
        ),
        value: notificationsEnabled,
        activeThumbColor: primaryColor,
        onChanged: (value) => setState(() => notificationsEnabled = value),
      ),
      _divider(borderColor),
      BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final isDarkMode = themeState is ThemeDark;
          return SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: textSecondary,
            ),
            title: Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
            subtitle: Text(
              isDarkMode ? 'Dark theme active' : 'Light theme active',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            value: isDarkMode,
            activeThumbColor: primaryColor,
            onChanged: (_) => context.read<ThemeBloc>().add(ThemeToggled()),
          );
        },
      ),
    ]);
  }

  Widget _buildSupportCard(Color cardColor, Color borderColor, Color textPrimary, Color textSecondary, Color primaryColor, bool isDark) {
    return _sectionCard(cardColor, borderColor, [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.help_outline, color: textSecondary),
        title: Text('Help & Support', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
        subtitle: Text('Get help with the admin panel', style: TextStyle(fontSize: 12, color: textSecondary)),
        trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help & Support will be connected later.')));
        },
      ),
      _divider(borderColor),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.info_outline, color: textSecondary),
        title: Text('About MedsCarrier', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
        subtitle: Text('App information', style: TextStyle(fontSize: 12, color: textSecondary)),
        trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
        onTap: _showAboutDialog,
      ),
    ]);
  }

  Widget _sectionCard(Color cardColor, Color borderColor, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _informationRow({required IconData icon, required String title, required String value, required Color textPrimary, required Color textSecondary, required Color primaryColor, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF18251F)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: textSecondary)),
                const SizedBox(height: 3),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(Color borderColor) {
    return Divider(height: 1, color: borderColor);
  }

  Widget _buildLogoutButton(bool isDark) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);

    final nameCtrl = TextEditingController(text: adminName);
    final phoneCtrl = TextEditingController(text: phone);
    final emailCtrl = TextEditingController(text: email);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
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
                        color: textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
                  const SizedBox(height: 20),
                  _profileField(controller: nameCtrl, label: 'Full Name', icon: Icons.person_outline, textPrimary: textPrimary, textSecondary: textSecondary, primaryColor: primaryColor, borderColor: borderColor),
                  const SizedBox(height: 13),
                  _profileField(controller: phoneCtrl, label: 'Phone', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, textPrimary: textPrimary, textSecondary: textSecondary, primaryColor: primaryColor, borderColor: borderColor),
                  const SizedBox(height: 13),
                  _profileField(controller: emailCtrl, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, textPrimary: textPrimary, textSecondary: textSecondary, primaryColor: primaryColor, borderColor: borderColor),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          adminName = nameCtrl.text.trim();
                          phone = phoneCtrl.text.trim();
                          email = emailCtrl.text.trim();
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
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

  Widget _profileField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text, required Color textPrimary, required Color textSecondary, required Color primaryColor, required Color borderColor}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textSecondary),
        prefixIcon: Icon(icon, color: textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor)),
      ),
    );
  }

  void _showChangePassword() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);

    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
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
                Text('Change Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 20),
                _passwordField(controller: currentCtrl, hint: 'Current password', textPrimary: textPrimary, primaryColor: primaryColor, borderColor: borderColor),
                const SizedBox(height: 13),
                _passwordField(controller: newCtrl, hint: 'New password', textPrimary: textPrimary, primaryColor: primaryColor, borderColor: borderColor),
                const SizedBox(height: 13),
                _passwordField(controller: confirmCtrl, hint: 'Confirm new password', textPrimary: textPrimary, primaryColor: primaryColor, borderColor: borderColor),
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
                      backgroundColor: primaryColor,
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

  Widget _passwordField({required TextEditingController controller, required String hint, required Color textPrimary, required Color primaryColor, required Color borderColor}) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: TextStyle(color: textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textPrimary.withValues(alpha: 0.4)),
        prefixIcon: Icon(Icons.lock_outline, color: textPrimary.withValues(alpha: 0.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor)),
      ),
    );
  }

  void _showLogoutConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text('Logout', style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
          content: Text('Are you sure you want to logout?', style: TextStyle(color: textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: textSecondary)),
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

  void _showAboutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);

    showAboutDialog(
      context: context,
      applicationName: 'MedsCarrier',
      applicationVersion: '1.0.0',
      applicationLegalese: '\u00a9 2026 MedsCarrier',
      children: [
        const SizedBox(height: 12),
        Text('MedsCarrier Admin Panel for managing pharmacies, riders, and orders.', style: TextStyle(color: textSecondary)),
      ],
    );
  }

  void _showImageOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF0E1A14) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF191C1B);
    final textSecondary = isDark ? const Color(0xFF8B9B94) : const Color(0xFF6E7A75);
    final primaryColor = isDark ? const Color(0xFF32C787) : const Color(0xFF0F7253);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
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
                      color: textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Profile Photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF18251F) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.camera_alt_outlined, color: primaryColor),
                  ),
                  title: Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: Text('Capture using camera', style: TextStyle(fontSize: 12, color: textSecondary)),
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
                      color: isDark ? const Color(0xFF18251F) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.photo_library_outlined, color: primaryColor),
                  ),
                  title: Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)),
                  subtitle: Text('Select from device', style: TextStyle(fontSize: 12, color: textSecondary)),
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
                    subtitle: Text('Delete profile photo', style: TextStyle(fontSize: 12, color: textSecondary)),
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
