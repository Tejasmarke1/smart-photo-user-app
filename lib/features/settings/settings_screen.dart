import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _privacyExpanded = false;
  bool _helpExpanded = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: LuminaTokens.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: LuminaTokens.fontWeightSemibold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationServiceProvider).revokeToken();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.outfit(
                color: LuminaTokens.darkTextMuted,
                fontWeight: LuminaTokens.fontWeightMedium,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Card ──
            _buildProfileCard(authState),

            // ── Add Profiles ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LuminaTokens.spacingLg,
                vertical: LuminaTokens.spacingSm,
              ),
              child: GestureDetector(
                onTap: () {
                  // TODO: Implement add profiles
                },
                child: Row(
                  children: [
                    Text(
                      'Add Profiles',
                      style: GoogleFonts.outfit(
                        fontSize: LuminaTokens.textSm,
                        fontWeight: LuminaTokens.fontWeightSemibold,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded, size: 12, color: Color(0xFF38BDF8)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: LuminaTokens.spacingXs),

            // ── Storage Utilization ──
            _buildStorageSection(),

            // ── Subscription ──
            _buildSubscriptionSection(),

            const SizedBox(height: LuminaTokens.spacingSm),

            // ── Menu Items ──
            _buildSwitchMenuItem(
              icon: Icons.notifications_rounded,
              label: 'Push Notifications',
              value: _pushNotifications,
              onChanged: (val) => setState(() => _pushNotifications = val),
            ),
            _buildMenuItem(
              icon: Icons.favorite_rounded,
              label: 'Close Friends',
              onTap: () => context.push('/close-friends'),
            ),
            _buildMenuItem(
              icon: Icons.download_rounded,
              label: 'Auto-download',
              onTap: () => context.push('/auto-downloads'),
            ),
            _buildMenuItem(
              icon: Icons.settings_rounded,
              label: 'App Settings',
              onTap: () => context.push('/app-settings'),
            ),

            // ── Privacy and Security (Expandable) ──
            _buildExpandableMenuItem(
              icon: Icons.lock_rounded,
              label: 'Privacy and Security',
              isExpanded: _privacyExpanded,
              onTap: () => setState(() => _privacyExpanded = !_privacyExpanded),
              children: [
                _buildSubMenuItem('Face Data Management', onTap: () => context.push('/face-data-management')),
                _buildSubMenuItem('Download Permissions', onTap: () => context.push('/download-permissions')),
                _buildSubMenuItem('Blocked Users', onTap: () => context.push('/blocked-users')),
              ],
            ),

            // ── Help and Support (Expandable) ──
            _buildExpandableMenuItem(
              icon: Icons.help_outline_rounded,
              label: 'Help and Support',
              isExpanded: _helpExpanded,
              onTap: () => setState(() => _helpExpanded = !_helpExpanded),
              children: [
                _buildSubMenuItem('FAQ', onTap: () => context.push('/faq')),
                _buildSubMenuItem('Contact Support', onTap: () => context.push('/contact-support')),
                _buildSubMenuItem('Report a Problem', onTap: () => context.push('/report-problem')),
              ],
            ),

            const SizedBox(height: LuminaTokens.spacingLg),

            // ── Version ──
            Center(
              child: Text(
                'Version 1.0',
                style: GoogleFonts.inter(
                  fontSize: LuminaTokens.textXs,
                  color: LuminaTokens.darkTextMuted.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: LuminaTokens.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(AuthState authState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: LuminaTokens.spacingLg),
      padding: const EdgeInsets.all(LuminaTokens.spacingMd),
      decoration: BoxDecoration(
        color: LuminaTokens.darkSurface,
        borderRadius: BorderRadius.circular(LuminaTokens.radiusLg),
        border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LuminaTokens.primaryGradient,
              border: Border.all(color: LuminaTokens.darkBorder, width: 2),
            ),
            child: ClipOval(
              child: authState.userName != null
                  ? Center(
                      child: Text(
                        authState.userName!.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: LuminaTokens.fontWeightBold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.person_rounded, size: 32, color: Colors.white70),
            ),
          ),
          const SizedBox(width: LuminaTokens.spacingMd),
          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authState.userName ?? 'Guest User',
                  style: GoogleFonts.outfit(
                    fontSize: LuminaTokens.textLg,
                    fontWeight: LuminaTokens.fontWeightBold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  authState.userEmail ?? 'No email associated',
                  style: GoogleFonts.inter(
                    fontSize: LuminaTokens.textSm,
                    color: LuminaTokens.darkTextMuted,
                  ),
                ),
              ],
            ),
          ),
          // Edit button
          GestureDetector(
            onTap: () {
              _showEditProfileDialog(authState);
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withOpacity(0.15),
              ),
              child: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF38BDF8)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildStorageSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: LuminaTokens.spacingLg),
      padding: const EdgeInsets.all(LuminaTokens.spacingMd),
      decoration: BoxDecoration(
        color: LuminaTokens.darkSurface,
        borderRadius: BorderRadius.circular(LuminaTokens.radiusLg),
        border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Storage Utilization',
                style: GoogleFonts.outfit(
                  fontSize: LuminaTokens.textMd,
                  fontWeight: LuminaTokens.fontWeightSemibold,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: LuminaTokens.darkTextMuted, size: 22),
            ],
          ),
          const SizedBox(height: LuminaTokens.spacingMd),

          // Photo storage row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library_rounded, size: 16, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '0',
                            style: GoogleFonts.outfit(
                              fontSize: LuminaTokens.textMd,
                              fontWeight: LuminaTokens.fontWeightBold,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: ' of 1,000',
                            style: GoogleFonts.inter(
                              fontSize: LuminaTokens.textSm,
                              color: LuminaTokens.darkTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0,
                        backgroundColor: LuminaTokens.darkSurfaceSecondary,
                        color: const Color(0xFF38BDF8),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LuminaTokens.spacingSm),

          // Video storage row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: LuminaTokens.primaryLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.videocam_rounded, size: 16, color: LuminaTokens.primaryLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '0',
                            style: GoogleFonts.outfit(
                              fontSize: LuminaTokens.textMd,
                              fontWeight: LuminaTokens.fontWeightBold,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: ' of 300 MB',
                            style: GoogleFonts.inter(
                              fontSize: LuminaTokens.textSm,
                              color: LuminaTokens.darkTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0,
                        backgroundColor: LuminaTokens.darkSurfaceSecondary,
                        color: LuminaTokens.primaryLight,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    return Container(
      margin: const EdgeInsets.only(
        left: LuminaTokens.spacingLg,
        right: LuminaTokens.spacingLg,
        top: LuminaTokens.spacingMd,
      ),
      padding: const EdgeInsets.all(LuminaTokens.spacingMd),
      decoration: BoxDecoration(
        color: LuminaTokens.darkSurface,
        borderRadius: BorderRadius.circular(LuminaTokens.radiusLg),
        border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription',
            style: GoogleFonts.outfit(
              fontSize: LuminaTokens.textMd,
              fontWeight: LuminaTokens.fontWeightSemibold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Free - Active',
            style: GoogleFonts.inter(
              fontSize: LuminaTokens.textSm,
              color: LuminaTokens.successLight,
              fontWeight: LuminaTokens.fontWeightMedium,
            ),
          ),
          const SizedBox(height: LuminaTokens.spacingMd),

          // Upgrade button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/subscription');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E6091),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.workspace_premium_rounded, size: 20),
              label: Text(
                'Upgrade',
                style: GoogleFonts.outfit(
                  fontWeight: LuminaTokens.fontWeightSemibold,
                  fontSize: LuminaTokens.textMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LuminaTokens.spacingLg,
          vertical: LuminaTokens.spacingMd,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: LuminaTokens.darkSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: LuminaTokens.darkTextMuted, size: 18),
            ),
            const SizedBox(width: LuminaTokens.spacingSm),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: LuminaTokens.textMd,
                  color: Colors.white,
                  fontWeight: LuminaTokens.fontWeightMedium,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: LuminaTokens.darkTextMuted, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchMenuItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuminaTokens.spacingLg,
        vertical: LuminaTokens.spacingSm,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: LuminaTokens.darkSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: LuminaTokens.darkTextMuted, size: 18),
          ),
          const SizedBox(width: LuminaTokens.spacingSm),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: LuminaTokens.textMd,
                color: Colors.white,
                fontWeight: LuminaTokens.fontWeightMedium,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF38BDF8),
            activeTrackColor: const Color(0xFF1E6091),
            inactiveThumbColor: LuminaTokens.darkTextMuted,
            inactiveTrackColor: LuminaTokens.darkSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableMenuItem({
    required IconData icon,
    required String label,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LuminaTokens.spacingLg,
              vertical: LuminaTokens.spacingMd,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: LuminaTokens.darkSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: LuminaTokens.darkTextMuted, size: 18),
                ),
                const SizedBox(width: LuminaTokens.spacingSm),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: LuminaTokens.textMd,
                      color: Colors.white,
                      fontWeight: LuminaTokens.fontWeightMedium,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded,
                    color: LuminaTokens.darkTextMuted,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(left: 72, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildSubMenuItem(String label, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: LuminaTokens.textSm,
                color: LuminaTokens.darkTextMuted,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: LuminaTokens.darkTextMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(AuthState authState) {
    final nameController = TextEditingController(text: authState.userName);
    final emailController = TextEditingController(text: authState.userEmail);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: LuminaTokens.darkSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: LuminaTokens.spacingLg,
          right: LuminaTokens.spacingLg,
          top: LuminaTokens.spacingMd,
          bottom: MediaQuery.of(context).viewInsets.bottom + LuminaTokens.spacingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: LuminaTokens.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: LuminaTokens.spacingLg),
            Text(
              'Edit Profile',
              style: GoogleFonts.outfit(
                fontSize: LuminaTokens.textXl,
                fontWeight: LuminaTokens.fontWeightBold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: LuminaTokens.spacingLg),
            TextField(
              controller: nameController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: GoogleFonts.inter(color: LuminaTokens.darkTextMuted),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: LuminaTokens.darkBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: LuminaTokens.darkBg,
              ),
            ),
            const SizedBox(height: LuminaTokens.spacingMd),
            TextField(
              controller: emailController,
              style: GoogleFonts.inter(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: GoogleFonts.inter(color: LuminaTokens.darkTextMuted),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: LuminaTokens.darkBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: LuminaTokens.darkBg,
              ),
            ),
            const SizedBox(height: LuminaTokens.spacingLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LuminaTokens.darkTextMuted,
                      side: BorderSide(color: LuminaTokens.darkBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: LuminaTokens.spacingSm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(authProvider.notifier).updateProfile(
                            name: nameController.text,
                            email: emailController.text,
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Profile updated', style: GoogleFonts.inter()),
                          backgroundColor: LuminaTokens.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6091),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
