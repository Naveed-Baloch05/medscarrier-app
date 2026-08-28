import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/rider_profile/rider_profile_bloc.dart';
import '../bloc/rider_profile/rider_profile_event.dart';
import '../bloc/rider_profile/rider_profile_state.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/theme/theme_event.dart';
import '../bloc/theme/theme_state.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({
    super.key,
    required this.riderId,
    this.bloc,
    this.initialData,
  });

  final String riderId;
  final RiderProfileBloc? bloc;
  final Map<String, dynamic>? initialData;

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  late final RiderProfileBloc _bloc;
  bool _internalBloc = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.bloc != null) {
      _bloc = widget.bloc!;
    } else {
      _internalBloc = true;
      _bloc = RiderProfileBloc(
        initialData: widget.initialData,
      )..add(LoadRiderProfile(widget.riderId));
    }
  }

  @override
  void dispose() {
    if (_internalBloc) {
      _bloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RiderProfileBloc>.value(
      value: _bloc,
      child: BlocBuilder<RiderProfileBloc, RiderProfileState>(
        builder: (context, state) => _buildContent(context, state),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RiderProfileState state) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0C1310) : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF0C1310) : theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Profile',
          style:
              TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: cs.onSurface),
            onPressed: () =>
                _bloc.add(LoadRiderProfile(widget.riderId)),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (state is RiderProfileLoading ||
                (state is RiderProfileInitial))
              const Center(child: CircularProgressIndicator())
            else if (state is RiderProfileError)
              _buildError(context, cs, state.message)
            else
              _buildLoaded(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, ColorScheme cs, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _bloc.add(LoadRiderProfile(widget.riderId)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F7253),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, RiderProfileState state) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final loading = state is RiderProfileUpdating;
    final data = state is RiderProfileLoaded
        ? state.data
        : (state is RiderProfileOperationSuccess
            ? state.data
            : <String, dynamic>{});
    final riderId = (data['id'] as String?) ??
        (data['uid'] as String?) ??
        widget.riderId;
    final riderName = (data['fullName'] as String?) ??
        (data['name'] as String?) ??
        'Rider';
    final phone = (data['phone'] as String?) ?? '';
    final email = (data['email'] as String?) ?? '';
    final vehicleType = (data['vehicleType'] as String?) ?? '';
    final vehicleReg = (data['vehicleReg'] as String?) ??
        (data['vehicleRegistrationNumber'] as String?) ??
        '';
    final deliveries = (data['deliveries'] as int?) ?? 0;
    final rating = (data['rating'] as num?)?.toDouble() ?? 0;
    final isOnline = (data['online'] as bool?) ?? false;
    final notificationsEnabled =
        (data['notificationsEnabled'] as bool?) ?? true;
    final profilePhotoUrl = (data['profilePhotoUrl'] as String?);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      children: [
        _buildProfileHeader(context, isDark, loading, riderName, riderId, isOnline,
            profilePhotoUrl),
        const SizedBox(height: 18),
        _buildStatistics(context, cs, isDark, deliveries, rating, isOnline),
        const SizedBox(height: 22),
        _sectionTitle('Personal Information', cs),
        const SizedBox(height: 12),
        _buildInformationCard(context, cs, isDark, riderName, riderId, phone,
            email, vehicleType, vehicleReg),
        const SizedBox(height: 22),
        _sectionTitle('Account', cs),
        const SizedBox(height: 12),
        _buildAccountCard(context, cs, isDark, isOnline, notificationsEnabled,
            loading),
        const SizedBox(height: 22),
        _buildLogoutButton(cs, isDark),
      ],
    );
  }

  Widget _sectionTitle(String title, ColorScheme cs) {
    return Text(title,
        style:
            TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface));
  }

  Widget _buildProfileHeader(BuildContext context, bool isDark, bool loading,
      String riderName, String riderId, bool isOnline, String? profilePhotoUrl) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
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
                      child: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                          ? Image.network(profilePhotoUrl, fit: BoxFit.cover)
                          : Icon(Icons.person_rounded, size: 38, color: cs.onSurfaceVariant),
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
                          border: Border.all(color: Theme.of(context).cardColor, width: 2),
                        ),
                        child:
                            const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black26,
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(riderName,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
          const SizedBox(height: 5),
          Text('Rider ID: $riderId',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isOnline
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
                    color: isOnline ? Colors.green.shade600 : Colors.red.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  isOnline ? 'Active Rider' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOnline ? Colors.green.shade700 : Colors.red.shade700,
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
              onPressed: () => _showEditProfile(_profileData(context)),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurface,
                side: BorderSide(
                    color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _profileData(BuildContext context) {
    final state = context.read<RiderProfileBloc>().state;
    if (state is RiderProfileLoaded) return state.data;
    if (state is RiderProfileOperationSuccess) return state.data;
    return <String, dynamic>{};
  }

  Widget _buildStatistics(BuildContext context, ColorScheme cs, bool isDark,
      int deliveries, double rating, bool isOnline) {
    return Row(
      children: [
        Expanded(
            child: _statCard(
                icon: Icons.local_shipping_outlined,
                value: '$deliveries',
                label: 'Total',
                cs: cs,
                isDark: isDark)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(
                icon: Icons.check_circle_outline_rounded,
                value: rating.toStringAsFixed(1),
                label: 'Rating',
                cs: cs,
                isDark: isDark)),
        const SizedBox(width: 10),
        Expanded(
            child: _statCard(
                icon: Icons.storefront_outlined,
                value: isOnline ? 'Online' : 'Offline',
                label: 'Status',
                cs: cs,
                isDark: isDark)),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required ColorScheme cs,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
            color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 21, color: cs.onSurfaceVariant),
          const SizedBox(height: 7),
          Text(value,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.onSurface)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildInformationCard(BuildContext context, ColorScheme cs, bool isDark,
      String riderName, String riderId, String phone, String email,
      String vehicleType, String vehicleReg) {
    final fields = [
      {'icon': Icons.person_outline, 'title': 'Full Name', 'value': riderName},
      {'icon': Icons.badge_outlined, 'title': 'Rider ID', 'value': riderId},
      {'icon': Icons.phone_outlined, 'title': 'Phone', 'value': phone},
      {'icon': Icons.email_outlined, 'title': 'Email', 'value': email},
      {'icon': Icons.local_shipping_outlined, 'title': 'Vehicle Type', 'value': vehicleType},
      {'icon': Icons.directions_car_filled_outlined, 'title': 'Vehicle Reg', 'value': vehicleReg},
    ];
    return _sectionCard(context, cs, isDark,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) _divider(isDark),
            _informationRow(
                icon: fields[i]['icon'] as IconData,
                title: fields[i]['title'] as String,
                value: fields[i]['value'] as String,
                cs: cs,
                isDark: isDark),
          ],
        ]);
  }

  Widget _buildAccountCard(BuildContext context, ColorScheme cs, bool isDark,
      bool isOnline, bool notificationsEnabled, bool loading) {
    return _sectionCard(context, cs, isDark,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              isOnline ? Icons.circle : Icons.circle_outlined,
              color: isOnline ? cs.primary : cs.onSurfaceVariant,
            ),
            title: Text('Online / Offline',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
            subtitle: Text(
              isOnline
                  ? 'You are online and receiving orders'
                  : 'You are offline and not receiving orders',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            value: isOnline,
            activeThumbColor: cs.primary,
            onChanged: loading
                ? null
                : (value) {
                    _bloc.add(RiderAvailabilityToggled(value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value
                            ? 'You are now online.'
                            : 'You are now offline.'),
                        backgroundColor: const Color(0xFF0F7253),
                      ),
                    );
                  },
          ),
          _divider(isDark),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.lock_outline, color: cs.onSurfaceVariant),
            title: Text('Change Password',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
            subtitle: Text('Update your account password',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            onTap: _showChangePassword,
          ),
          _divider(isDark),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary:
                Icon(Icons.notifications_none_outlined, color: cs.onSurfaceVariant),
            title: Text('Notifications',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
            subtitle: Text(
              notificationsEnabled
                  ? 'Notifications are enabled'
                  : 'Notifications are disabled',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            value: notificationsEnabled,
            activeThumbColor: cs.primary,
            onChanged: loading
                ? null
                : (value) {
                    _bloc.add(RiderProfileUpdated(
                      fullName: '',
                      phone: '',
                      email: '',
                      vehicleType: '',
                      vehicleReg: '',
                      notificationsEnabled: value,
                    ));
                  },
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
                title: Text('Dark Mode',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                subtitle: Text(
                  isDarkMode ? 'Dark theme active' : 'Light theme active',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                value: isDarkMode,
                activeThumbColor: cs.primary,
                onChanged: (_) => context.read<ThemeBloc>().add(ThemeToggled()),
              );
            },
          ),
        ]);
  }

  Widget _sectionCard(BuildContext context, ColorScheme cs, bool isDark,
      {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _informationRow(
      {required IconData icon,
      required String title,
      required String value,
      required ColorScheme cs,
      required bool isDark}) {
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
                Text(value,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(height: 1,
        color: isDark ? const Color(0xFF1D322A) : Colors.grey.shade200);
  }

  Widget _buildLogoutButton(ColorScheme cs, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _showLogoutConfirmation,
        icon: Icon(Icons.logout_rounded, color: Colors.red.shade600),
        label: Text('Logout',
            style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
              color: isDark ? const Color(0xFF2D1B1B) : Colors.red.shade200),
          backgroundColor: isDark ? const Color(0xFF2D1B1B) : Colors.red.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  void _showEditProfile(Map<String, dynamic> data) {
    final cs = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(
        text: (data['fullName'] as String?) ??
            (data['name'] as String?) ??
            '');
    final phoneCtrl =
        TextEditingController(text: (data['phone'] as String?) ?? '');
    final emailCtrl =
        TextEditingController(text: (data['email'] as String?) ?? '');
    final vehicleTypeCtrl =
        TextEditingController(text: (data['vehicleType'] as String?) ?? '');
    final vehicleRegCtrl = TextEditingController(
        text: (data['vehicleReg'] as String?) ??
            (data['vehicleRegistrationNumber'] as String?) ??
            '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Edit Profile',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 20),
                  _profileField(
                      controller: nameCtrl,
                      label: 'Full Name',
                      icon: Icons.person_outline),
                  const SizedBox(height: 13),
                  _profileField(
                      controller: phoneCtrl,
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 13),
                  _profileField(
                      controller: emailCtrl,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 13),
                  _profileField(
                      controller: vehicleTypeCtrl,
                      label: 'Vehicle Type',
                      icon: Icons.local_shipping_outlined),
                  const SizedBox(height: 13),
                  _profileField(
                      controller: vehicleRegCtrl,
                      label: 'Vehicle Registration',
                      icon: Icons.directions_car_filled_outlined),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _bloc.add(RiderProfileUpdated(
                          fullName: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          vehicleType: vehicleTypeCtrl.text.trim(),
                          vehicleReg: vehicleRegCtrl.text.trim(),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _profileField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      TextInputType keyboardType = TextInputType.text}) {
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.primary)),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change Password',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const SizedBox(height: 20),
                _passwordField(controller: currentCtrl, hint: 'Current password'),
                const SizedBox(height: 13),
                _passwordField(controller: newCtrl, hint: 'New password'),
                const SizedBox(height: 13),
                _passwordField(controller: confirmCtrl, hint: 'Confirm new password'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (newCtrl.text.isEmpty || confirmCtrl.text.isEmpty) return;
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Passwords do not match.')));
                        return;
                      }
                      Navigator.pop(ctx);
                      _bloc.add(RiderPasswordChanged(
                        currentPassword: currentCtrl.text,
                        newPassword: newCtrl.text,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Update Password',
                        style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _passwordField(
      {required TextEditingController controller, required String hint}) {
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
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.primary)),
      ),
    );
  }

  void _showLogoutConfirmation() {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Logout',
              style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface)),
          content: Text('Are you sure you want to logout?',
              style: TextStyle(color: cs.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: cs.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  }
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Logout failed. Please try again.')),
                    );
                  }
                }
              },
              child: Text('Logout',
                  style: TextStyle(
                      color: Colors.red.shade600, fontWeight: FontWeight.w600)),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Profile Photo',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2744) : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.camera_alt_outlined, color: Colors.blue.shade600),
                  ),
                  title: Text('Take Photo',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                  subtitle: Text('Capture using camera',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
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
                      color: isDark ? const Color(0xFF15301D) : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.photo_library_outlined, color: Colors.green.shade600),
                  ),
                  title: Text('Choose from Gallery',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                  subtitle: Text('Select from device',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D1B1B) : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.delete_outline, color: Colors.red.shade600),
                  ),
                  title: Text('Remove Photo',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade600)),
                  subtitle: Text('Delete profile photo',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _bloc.add(const RiderProfilePhotoRemoved());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (picked != null) {
      _bloc.add(RiderProfilePhotoChanged(File(picked.path)));
    }
  }
}
