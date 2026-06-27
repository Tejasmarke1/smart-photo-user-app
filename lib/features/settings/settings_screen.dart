import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: LuminaTokens.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Preferences & Settings", style: GoogleFonts.outfit(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LuminaTokens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(LuminaTokens.spacingLg),
              decoration: BoxDecoration(
                color: LuminaTokens.darkSurface,
                borderRadius: LuminaTokens.borderRadiusXl,
                border: Border.all(color: LuminaTokens.darkBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: LuminaTokens.primary.withOpacity(0.2),
                    child: const Icon(Icons.person_rounded, size: 36, color: LuminaTokens.primaryLight),
                  ),
                  const SizedBox(width: LuminaTokens.spacingMd),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.userName ?? "Guest User",
                        style: GoogleFonts.outfit(
                          fontSize: LuminaTokens.textLg,
                          fontWeight: LuminaTokens.fontWeightBold,
                          color: LuminaTokens.darkText,
                        ),
                      ),
                      Text(
                        authState.userEmail ?? "No email associated",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: LuminaTokens.spacingXxl),

            Text(
              "App Preferences",
              style: GoogleFonts.outfit(
                fontSize: LuminaTokens.textLg,
                fontWeight: LuminaTokens.fontWeightBold,
                color: LuminaTokens.darkText,
              ),
            ),
            const SizedBox(height: LuminaTokens.spacingMd),

            // Push Notification Toggle
            Card(
              child: SwitchListTile(
                value: true,
                onChanged: (val) {
                  // Toggle FCM notifications state
                },
                title: Text("Push Notifications", style: GoogleFonts.outfit(fontWeight: LuminaTokens.fontWeightMedium)),
                subtitle: Text("Receive alerts when photographers upload photos containing your face", style: GoogleFonts.inter(fontSize: LuminaTokens.textXs)),
                activeColor: LuminaTokens.primaryLight,
              ),
            ),

            const SizedBox(height: LuminaTokens.spacingSm),

            // Dark mode indicator (obsidian is default)
            Card(
              child: SwitchListTile(
                value: true,
                onChanged: (val) {},
                title: Text("Dark Mode first (Obsidian)", style: GoogleFonts.outfit(fontWeight: LuminaTokens.fontWeightMedium)),
                subtitle: Text("Optimized high-contrast premium layout theme", style: GoogleFonts.inter(fontSize: LuminaTokens.textXs)),
                activeColor: LuminaTokens.primaryLight,
              ),
            ),

            const SizedBox(height: LuminaTokens.spacingXxl),

            // Logout Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // 1. Revoke notification device token from backend
                  await ref.read(notificationServiceProvider).revokeToken();
                  
                  // 2. Clear JWT credentials and sign out
                  await ref.read(authProvider.notifier).logout();
                  
                  // 3. Redirect back to login gate
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: LuminaTokens.error,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text("Sign Out"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
