import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/tokens.dart';

class BlockedUser {
  final String id;
  final String name;
  final String email;

  BlockedUser({
    required this.id,
    required this.name,
    required this.email,
  });
}

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final List<BlockedUser> _blockedUsers = [
    BlockedUser(id: 'bl_1', name: 'Kabir Kapoor', email: 'kabir.kapoor@example.com'),
    BlockedUser(id: 'bl_2', name: 'Simran Gill', email: 'simran.gill@example.com'),
  ];

  void _unblockUser(BlockedUser user) {
    setState(() {
      _blockedUsers.remove(user);
    });
    _showSnackBar('${user.name} has been unblocked.');
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
        backgroundColor: LuminaTokens.darkSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Blocked Users',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: LuminaTokens.fontWeightSemibold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Blocked Accounts',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Blocked users cannot invite you to groups, view your uploaded photos, or request face matching inside mutual albums.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: LuminaTokens.darkTextMuted,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            if (_blockedUsers.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _blockedUsers.length,
                itemBuilder: (context, index) {
                  final user = _blockedUsers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: LuminaTokens.darkSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        // Avatar Initial
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.1),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            user.name[0].toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: Colors.redAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: GoogleFonts.inter(
                                  color: LuminaTokens.darkTextMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LuminaTokens.darkSurfaceSecondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () => _unblockUser(user),
                          child: Text(
                            'Unblock',
                            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 200.ms).slideY(begin: 0.05, curve: Curves.easeOut);
                },
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      const Icon(Icons.people_alt_rounded, size: 54, color: LuminaTokens.darkTextMuted),
                      const SizedBox(height: 16),
                      Text(
                        'No blocked users',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Accounts you block will appear here.',
                        style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
