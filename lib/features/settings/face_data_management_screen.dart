import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/tokens.dart';

class FaceDataManagementScreen extends StatefulWidget {
  const FaceDataManagementScreen({super.key});

  @override
  State<FaceDataManagementScreen> createState() => _FaceDataManagementScreenState();
}

class _FaceDataManagementScreenState extends State<FaceDataManagementScreen> {
  bool _isLoading = true;
  bool _optOutOfFaceMatching = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _optOutOfFaceMatching = prefs.getBool('opt_out_face_matching') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _deleteFaceSignature() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LuminaTokens.darkSurface,
        title: Text(
          'Delete Face Data?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete your face vector signature from our face recognition server. You will no longer be matched in photos unless you register a new selfie.',
          style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete Permanently', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
    });

    // Simulate API call to delete face signatures
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isDeleting = false;
    });

    _showSnackBar('Face signature data deleted successfully.');
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
          'Face Data Management',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: LuminaTokens.fontWeightSemibold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: LuminaTokens.primaryLight))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lumina Face Recognition Tech',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We process facial data to match you inside albums you are joined in. This facial signature is encrypted and never shared.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: LuminaTokens.darkTextMuted,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Opt out panel
                  Container(
                    decoration: BoxDecoration(
                      color: LuminaTokens.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: LuminaTokens.darkSurfaceSecondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.face_retouching_off_rounded, color: Colors.white70, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Opt-out of Face Matching',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Stop matching me in new photo uploads',
                                  style: GoogleFonts.inter(
                                    color: LuminaTokens.darkTextMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _optOutOfFaceMatching,
                            onChanged: (val) {
                              setState(() => _optOutOfFaceMatching = val);
                              _saveSetting('opt_out_face_matching', val);
                              if (val) {
                                _showSnackBar('Opted out of face matching.');
                              } else {
                                _showSnackBar('Opted in to face matching!');
                              }
                            },
                            activeColor: LuminaTokens.primaryLight,
                            activeTrackColor: LuminaTokens.primary.withOpacity(0.5),
                            inactiveThumbColor: Colors.white70,
                            inactiveTrackColor: LuminaTokens.darkSurfaceSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Delete Face Signatures',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Delete face data card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LuminaTokens.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remove all registered biometrics',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Permanently deletes the face signature vector generated from your selfie profile. This action is irreversible.',
                          style: GoogleFonts.inter(
                            color: LuminaTokens.darkTextMuted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.12),
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent, width: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            onPressed: _isDeleting ? null : _deleteFaceSignature,
                            icon: _isDeleting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                                  )
                                : const Icon(Icons.delete_forever_rounded, size: 18),
                            label: Text(
                              _isDeleting ? 'Deleting...' : 'Delete Face Signatures',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
