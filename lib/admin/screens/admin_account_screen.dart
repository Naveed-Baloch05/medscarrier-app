import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../bloc/admin_profile/admin_profile_bloc.dart';
import '../../bloc/admin_profile/admin_profile_event.dart';
import '../../bloc/admin_profile/admin_profile_state.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_event.dart';
import '../../bloc/theme/theme_state.dart';
import '../../models/user_model.dart';
import '../../screens/welcome_screen.dart';
import 'admin_support_screen.dart';

class AdminAccountScreen extends StatefulWidget {
  const AdminAccountScreen({super.key});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  bool notificationsEnabled = true;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  late final AdminProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    _profileBloc = AdminProfileBloc()..add(const AdminProfileLoadRequested());
  }

  @override
  void dispose() {
    _profileBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminProfileBloc>.value(
      value: _profileBloc,
      child: BlocConsumer<AdminProfileBloc, AdminProfileState>(
      listener: (context, state) {
        if (state is AdminProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
            ),
          );
        }

        if (state is AdminProfileUnauthorized) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You are not authorized to access the admin account.',
              ),
            ),
          );
        }

        if (state is AdminProfileLoaded) {
          // Profile successfully loaded.
        }

        if (state is AdminProfileClearedState) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const WelcomeScreen(),
            ),
            (route) => false,
          );
        }
      },
      builder: (context, state) {

        if (state is AdminProfileUnauthorized) {
          return _buildMessageScreen(
            context,
            title: 'Access Denied',
            message:
            'Your account does not have administrator permissions.',
            icon: Icons.lock_outline,
          );
        }

        if (state is AdminProfileError) {
          return _buildMessageScreen(
            context,
            title: 'Unable to Load Account',
            message: state.message,
            icon: Icons.error_outline,
            showRetry: true,
          );
        }

        if (state is AdminProfileLoaded) {
          return _buildAccountScreen(
            context,
            state.admin,
          );
        }

        if (state is AdminProfileUpdating) {
          return _buildAccountScreen(
            context,
            state.admin,
            isUpdating: true,
          );
        }

        // Show account screen with placeholder data during loading
        // (same pattern as rider and pharmacy screens)
        return _buildAccountScreen(
          context,
          const UserModel(email: '', role: 'admin'),
        );
      },
    ),
    );
  }

  Widget _buildAccountScreen(
      BuildContext context,
      UserModel admin, {
        bool isUpdating = false,
      }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final adminName =
    admin.name?.trim().isNotEmpty == true
        ? admin.name!.trim()
        : 'Admin User';

    final phone =
    admin.phone?.trim().isNotEmpty == true
        ? admin.phone!.trim()
        : 'Not provided';

    final email =
    admin.email.trim().isNotEmpty
        ? admin.email.trim()
        : 'Not provided';

    final role =
    admin.role?.trim().isNotEmpty == true
        ? admin.role!.trim()
        : 'admin';

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0C1310)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF0C1310)
            : theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Account',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                30,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        _buildProfileHeader(
                          context,
                          adminName,
                          phone,
                          email,
                          role,
                          cs,
                          isDark,
                        ),
                        const SizedBox(height: 22),

                        _sectionTitle(
                          'Personal Information',
                          cs,
                        ),
                        const SizedBox(height: 12),

                        _buildInformationCard(
                          context,
                          adminName,
                          phone,
                          email,
                          role,
                          cs,
                          isDark,
                        ),

                        const SizedBox(height: 22),

                        _sectionTitle(
                          'Account',
                          cs,
                        ),
                        const SizedBox(height: 12),

                        _buildAccountCard(
                          context,
                          cs,
                          isDark,
                        ),

                        const SizedBox(height: 22),

                        _sectionTitle(
                          'Support',
                          cs,
                        ),
                        const SizedBox(height: 12),

                        _buildSupportCard(
                          context,
                          cs,
                          isDark,
                        ),

                        const SizedBox(height: 22),

                        _buildLogoutButton(
                          context,
                          cs,
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isUpdating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageScreen(
      BuildContext context, {
        required String title,
        required String message,
        required IconData icon,
        bool showRetry = false,
      }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0C1310)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF0C1310)
            : theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Account',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 55,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (showRetry) ...[
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: () {
                      _profileBloc.add(
                        const AdminProfileLoadRequested(),
                      );
                    },
                    child: const Text('Try Again'),
                  ),
                ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _sectionTitle(
      String title,
      ColorScheme cs,
      ) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context,
      String adminName,
      String phone,
      String email,
      String role,
      ColorScheme cs,
      bool isDark,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1D322A)
              : Colors.grey.shade200,
        ),
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
                        ? const Color(0xFF1D322A)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _profileImage != null
                      ? Image.file(
                    _profileImage!,
                    fit: BoxFit.cover,
                  )
                      : Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 38,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).cardColor,
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
          Text(
            adminName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1D322A)
                  : Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  role == 'admin'
                      ? 'Admin'
                      : role,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
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
              onPressed: () {
                _showEditProfile(
                  context,
                  adminName,
                  phone,
                );
              },
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
              ),
              label: const Text(
                'Edit Profile',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurface,
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF2A3A33)
                      : Colors.grey.shade300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard(
      BuildContext context,
      String adminName,
      String phone,
      String email,
      String role,
      ColorScheme cs,
      bool isDark,
      ) {
    return _sectionCard(
      context,
      cs,
      isDark,
      children: [
        _informationRow(
          icon: Icons.person_outline,
          title: 'Full Name',
          value: adminName,
          cs: cs,
          isDark: isDark,
        ),
        _divider(isDark),
        _informationRow(
          icon: Icons.phone_outlined,
          title: 'Phone',
          value: phone,
          cs: cs,
          isDark: isDark,
        ),
        _divider(isDark),
        _informationRow(
          icon: Icons.email_outlined,
          title: 'Email',
          value: email,
          cs: cs,
          isDark: isDark,
        ),
        _divider(isDark),
        _informationRow(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Role',
          value: role == 'admin'
              ? 'Administrator'
              : role,
          cs: cs,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildAccountCard(
      BuildContext context,
      ColorScheme cs,
      bool isDark,
      ) {
    return _sectionCard(
      context,
      cs,
      isDark,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.lock_outline,
            color: cs.onSurfaceVariant,
          ),
          title: Text(
            'Change Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          subtitle: Text(
            'Update your account password',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurfaceVariant,
          ),
          onTap: _showChangePassword,
        ),
        _divider(isDark),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            Icons.notifications_none_outlined,
            color: cs.onSurfaceVariant,
          ),
          title: Text(
            'Notifications',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          subtitle: Text(
            notificationsEnabled
                ? 'Notifications are enabled'
                : 'Notifications are disabled',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
          value: notificationsEnabled,
          activeThumbColor: cs.primary,
          onChanged: (value) {
            setState(() {
              notificationsEnabled = value;
            });
          },
        ),
        _divider(isDark),
        BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final isDarkMode =
            themeState is ThemeDark;

            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(
                isDarkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                color: cs.onSurfaceVariant,
              ),
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              subtitle: Text(
                isDarkMode
                    ? 'Dark theme active'
                    : 'Light theme active',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
              value: isDarkMode,
              activeThumbColor: cs.primary,
              onChanged: (_) {
                context.read<ThemeBloc>().add(
                  ThemeToggled(),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSupportCard(
      BuildContext context,
      ColorScheme cs,
      bool isDark,
      ) {
    return _sectionCard(
      context,
      cs,
      isDark,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.help_outline,
            color: cs.onSurfaceVariant,
          ),
          title: Text(
            'Help & Support',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          subtitle: Text(
            'Get help with the admin panel',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurfaceVariant,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminSupportScreen(),
              ),
            );
          },
        ),
        _divider(isDark),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.info_outline,
            color: cs.onSurfaceVariant,
          ),
          title: Text(
            'About MedsCarrier',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          subtitle: Text(
            'App information',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurfaceVariant,
          ),
          onTap: _showAboutDialog,
        ),
      ],
    );
  }

  Widget _sectionCard(
      BuildContext context,
      ColorScheme cs,
      bool isDark, {
        required List<Widget> children,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1D322A)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: children,
      ),
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
              color: isDark
                  ? const Color(0xFF1D322A)
                  : Colors.grey.shade100,
              borderRadius:
              BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 19,
              color: cs.onSurfaceVariant,
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
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark
          ? const Color(0xFF1D322A)
          : Colors.grey.shade200,
    );
  }

  Widget _buildLogoutButton(
      BuildContext context,
      ColorScheme cs,
      bool isDark,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _showLogoutConfirmation,
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
            color: isDark
                ? const Color(0xFF2D1B1B)
                : Colors.red.shade200,
          ),
          backgroundColor: isDark
              ? const Color(0xFF2D1B1B)
              : Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _showEditProfile(
      BuildContext context,
      String currentName,
      String currentPhone,
      ) {
    final cs = Theme.of(context).colorScheme;

    final nameCtrl =
    TextEditingController(text: currentName);

    final phoneCtrl =
    TextEditingController(text: currentPhone);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
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
              MediaQuery.of(ctx).viewInsets.bottom +
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
                        color: cs.onSurfaceVariant
                            .withValues(alpha: 0.3),
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _profileField(
                    controller: nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    context: context,
                  ),

                  const SizedBox(height: 13),

                  _profileField(
                    controller: phoneCtrl,
                    label: 'Phone',
                    icon: Icons.phone_outlined,
                    keyboardType:
                    TextInputType.phone,
                    context: context,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final name =
                        nameCtrl.text.trim();
                        final phone =
                        phoneCtrl.text.trim();

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter your name.',
                              ),
                            ),
                          );
                          return;
                        }

                        _profileBloc
                            .add(
                          AdminProfileUpdateRequested(
                            name: name,
                            phone: phone,
                          ),
                        );

                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
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

  Widget _profileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required BuildContext context,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        color: cs.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: cs.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          icon,
          color: cs.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2A3A33)
                : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2A3A33)
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: cs.primary,
          ),
        ),
      ),
    );
  }

  void _showChangePassword() {
    final cs = Theme.of(context).colorScheme;

    final currentCtrl =
    TextEditingController();
    final newCtrl =
    TextEditingController();
    final confirmCtrl =
    TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
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
              MediaQuery.of(ctx).viewInsets.bottom +
                  24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                const SizedBox(height: 20),

                _passwordField(
                  controller: currentCtrl,
                  hint: 'Current password',
                  context: context,
                ),

                const SizedBox(height: 13),

                _passwordField(
                  controller: newCtrl,
                  hint: 'New password',
                  context: context,
                ),

                const SizedBox(height: 13),

                _passwordField(
                  controller: confirmCtrl,
                  hint: 'Confirm new password',
                  context: context,
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (newCtrl.text.isEmpty ||
                          confirmCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter the new password.',
                            ),
                          ),
                        );
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

                      // Password backend will be connected
                      // through AuthBloc in the next step.
                      Navigator.pop(ctx);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Password update will be connected next.',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
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
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return TextField(
      controller: controller,
      obscureText: true,
      style: TextStyle(
        color: cs.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: cs.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: cs.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0xFF2A3A33)
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: cs.primary,
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: cs.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);

                _profileBloc.add(const AdminProfileCleared());
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

  void _showAboutDialog() {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0E1A14) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'MedsCarrier',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Admin Panel for managing pharmacies, riders, and orders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\u00a9 2026 MedsCarrier',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageOptions() {
    final cs = Theme.of(context).colorScheme;
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor:
      Theme.of(context).cardColor,
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
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant
                          .withValues(alpha: 0.3),
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 20),

                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1D322A)
                          : Colors.blue.shade50,
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  title: Text(
                    'Take Photo',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Capture using camera',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(
                      ImageSource.camera,
                    );
                  },
                ),

                const SizedBox(height: 8),

                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1D322A)
                          : Colors.green.shade50,
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: Colors.green.shade600,
                    ),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Select from device',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(
                      ImageSource.gallery,
                    );
                  },
                ),

                if (_profileImage != null) ...[
                  const SizedBox(height: 8),

                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2D1B1B)
                            : Colors.red.shade50,
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
                        color: cs.onSurfaceVariant,
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
          ),
        );
      },
    );
  }

  Future<void> _pickImage(
      ImageSource source,
      ) async {
    final picked =
    await _picker.pickImage(
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
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Profile photo updated.',
            ),
          ),
        );
      }
    }
  }
}