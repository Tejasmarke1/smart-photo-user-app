import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/tokens.dart';

class DownloadPermissionsScreen extends StatefulWidget {
  const DownloadPermissionsScreen({super.key});

  @override
  State<DownloadPermissionsScreen> createState() => _DownloadPermissionsScreenState();
}

class _DownloadPermissionsScreenState extends State<DownloadPermissionsScreen> {
  bool _isLoading = true;
  String _downloadPermission = 'Everyone'; // Everyone | CloseFriends | Nobody
  bool _watermarkOriginals = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _downloadPermission = prefs.getString('download_permission_rule') ?? 'Everyone';
      _watermarkOriginals = prefs.getBool('watermark_original_downloads') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
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
          'Download Permissions',
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
                    'Permissions Rules',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure who is allowed to download original quality photos that you have uploaded into shared event groups.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: LuminaTokens.darkTextMuted,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Option Selector List
                  Container(
                    decoration: BoxDecoration(
                      color: LuminaTokens.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        _buildRadioTile('Everyone', 'Allow all group members to download my photos'),
                        Divider(color: LuminaTokens.darkBorder.withOpacity(0.2), height: 1),
                        _buildRadioTile('CloseFriends', 'Only Close Friends can download my photos'),
                        Divider(color: LuminaTokens.darkBorder.withOpacity(0.2), height: 1),
                        _buildRadioTile('Nobody', 'Prevent anyone from downloading my photos'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Watermark Safeguards',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Watermark card toggle
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
                            child: const Icon(Icons.branding_watermark_rounded, color: Colors.white70, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Apply Download Watermarks',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Embed watermark signature in downloads',
                                  style: GoogleFonts.inter(
                                    color: LuminaTokens.darkTextMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _watermarkOriginals,
                            onChanged: (val) {
                              setState(() => _watermarkOriginals = val);
                              _saveSetting('watermark_original_downloads', val);
                              if (val) {
                                _showSnackBar('Watermarks enabled for downloads.');
                              } else {
                                _showSnackBar('Watermarks disabled.');
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
                ],
              ),
            ),
    );
  }

  Widget _buildRadioTile(String value, String subtitle) {
    final isSelected = _downloadPermission == value;
    String displayLabel = value;
    if (value == 'CloseFriends') displayLabel = 'Only Close Friends';
    if (value == 'Nobody') displayLabel = 'Private (Nobody)';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Text(
        displayLabel,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          color: LuminaTokens.darkTextMuted,
          fontSize: 11,
        ),
      ),
      trailing: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? LuminaTokens.primaryLight : LuminaTokens.darkBorder,
            width: 2,
          ),
          color: isSelected ? LuminaTokens.primaryLight : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: isSelected
            ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
            : null,
      ),
      onTap: () {
        setState(() {
          _downloadPermission = value;
        });
        _saveSetting('download_permission_rule', value);
        _showSnackBar('Download permission set to: $displayLabel');
      },
    );
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
}
