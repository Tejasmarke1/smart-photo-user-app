import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/tokens.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _isLoading = true;
  String _selectedTheme = 'System';
  String _selectedLanguage = 'English';
  bool _analyticsEnabled = true;
  double _cacheSizeMb = 0.0;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Calculate actual temporary directory cache size
    double computedSize = 0.0;
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final List<FileSystemEntity> files = tempDir.listSync(recursive: true);
        int totalBytes = 0;
        for (final FileSystemEntity file in files) {
          if (file is File) {
            totalBytes += file.lengthSync();
          }
        }
        computedSize = totalBytes / (1024 * 1024); // Convert to MB
      }
    } catch (e) {
      debugPrint('Failed to calculate actual cache size: $e');
    }

    setState(() {
      _selectedTheme = prefs.getString('app_theme') ?? 'System';
      _selectedLanguage = prefs.getString('app_language') ?? 'English';
      _analyticsEnabled = prefs.getBool('app_analytics') ?? true;
      _cacheSizeMb = computedSize;
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

  Future<void> _clearCache() async {
    setState(() {
      _isClearingCache = true;
    });
    
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final List<FileSystemEntity> files = tempDir.listSync(recursive: true);
        for (final FileSystemEntity file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
      setState(() {
        _cacheSizeMb = 0.0;
      });
      _showSnackBar('Cache cleared successfully!');
    } catch (e) {
      _showSnackBar('Failed to clear cache: $e');
    } finally {
      setState(() {
        _isClearingCache = false;
      });
    }
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
          'App Settings',
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
                    'Preferences',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Preferences Group Panel
                  Container(
                    decoration: BoxDecoration(
                      color: LuminaTokens.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        _buildDropdownTile(
                          icon: Icons.palette_rounded,
                          title: 'App Theme',
                          value: _selectedTheme,
                          items: ['System', 'Dark', 'Light'],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedTheme = val);
                              _saveSetting('app_theme', val);
                            }
                          },
                        ),
                        Divider(color: LuminaTokens.darkBorder.withOpacity(0.2), height: 1),
                        _buildDropdownTile(
                          icon: Icons.language_rounded,
                          title: 'App Language',
                          value: _selectedLanguage,
                          items: ['English', 'Hindi', 'Spanish'],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedLanguage = val);
                              _saveSetting('app_language', val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Privacy & Telemetry',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Telemetry panel
                  Container(
                    decoration: BoxDecoration(
                      color: LuminaTokens.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: LuminaTokens.darkSurfaceSecondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.analytics_rounded, color: Colors.white70, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Share Crash Reports',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Help us improve performance by sending reports',
                                  style: GoogleFonts.inter(
                                    color: LuminaTokens.darkTextMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _analyticsEnabled,
                            onChanged: (val) {
                              setState(() => _analyticsEnabled = val);
                              _saveSetting('app_analytics', val);
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
                    'Storage & Cache',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cache management panel
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: LuminaTokens.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Image & Video Cache',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Temporarily downloaded images size: ${_cacheSizeMb.toStringAsFixed(2)} MB',
                                style: GoogleFonts.inter(
                                  color: LuminaTokens.darkTextMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _cacheSizeMb > 0 ? Colors.redAccent : LuminaTokens.darkTextMuted,
                            side: BorderSide(color: _cacheSizeMb > 0 ? Colors.redAccent.withOpacity(0.3) : LuminaTokens.darkBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onPressed: (_cacheSizeMb > 0 && !_isClearingCache) ? _clearCache : null,
                          child: _isClearingCache
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                                )
                              : Text(
                                  'Clear',
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
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

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: LuminaTokens.darkSurfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: LuminaTokens.darkSurfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    ),
                  );
                }).toList(),
                dropdownColor: LuminaTokens.darkSurface,
                iconEnabledColor: Colors.white70,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
