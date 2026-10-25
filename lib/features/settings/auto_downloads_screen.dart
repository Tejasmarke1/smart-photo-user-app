import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/tokens.dart';

class AutoDownloadsScreen extends ConsumerStatefulWidget {
  const AutoDownloadsScreen({super.key});

  @override
  ConsumerState<AutoDownloadsScreen> createState() => _AutoDownloadsScreenState();
}

class _AutoDownloadsScreenState extends ConsumerState<AutoDownloadsScreen> {
  bool _isLoading = true;
  
  // Settings values
  bool _autoDownloadEnabled = false;
  bool _onlyWifi = true;
  bool _downloadMe = true;
  bool _downloadCloseFriends = false;
  String _downloadQuality = 'Optimized';
  String _storageDestination = 'Gallery';

  // Simulated download history list
  final List<Map<String, String>> _simulatedHistory = [
    {'title': 'Beach Trip 2026', 'time': '2 hours ago', 'size': '2.4 MB', 'status': 'Downloaded'},
    {'title': 'Wedding Ceremony', 'time': 'Yesterday', 'size': '4.1 MB', 'status': 'Downloaded'},
    {'title': 'Farewell Party', 'time': '3 days ago', 'size': '1.8 MB', 'status': 'Downloaded'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoDownloadEnabled = prefs.getBool('autodownload_enabled') ?? false;
      _onlyWifi = prefs.getBool('autodownload_only_wifi') ?? true;
      _downloadMe = prefs.getBool('autodownload_me') ?? true;
      _downloadCloseFriends = prefs.getBool('autodownload_close_friends') ?? false;
      _downloadQuality = prefs.getString('autodownload_quality') ?? 'Optimized';
      _storageDestination = prefs.getString('autodownload_destination') ?? 'Gallery';
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

  Future<bool> _requestPhotosPermission() async {
    // Check photo/storage status
    PermissionStatus status = await Permission.photos.status;
    if (status.isDenied) {
      status = await Permission.photos.request();
    }

    if (status.isGranted) return true;

    // Fallback to storage permission on older Android/iOS versions
    PermissionStatus storageStatus = await Permission.storage.status;
    if (storageStatus.isDenied) {
      storageStatus = await Permission.storage.request();
    }

    return storageStatus.isGranted;
  }

  Future<void> _handleAutoDownloadToggle(bool val) async {
    if (val) {
      // Request permissions
      final granted = await _requestPhotosPermission();
      if (!granted) {
        _showSnackBar('Gallery storage permission is required to save photos automatically.');
        setState(() {
          _autoDownloadEnabled = false;
        });
        _saveSetting('autodownload_enabled', false);
        return;
      }
    }

    setState(() {
      _autoDownloadEnabled = val;
    });
    _saveSetting('autodownload_enabled', val);
    _showSnackBar(val ? 'Background downloads enabled!' : 'Background downloads disabled.');
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
          'Auto-download Settings',
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
                  // Explanation Header
                  Text(
                    'Automatically download photos you appear in to your phone gallery as soon as they are uploaded.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: LuminaTokens.darkTextMuted,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Group Toggle Panel ──
                  Container(
                    decoration: BoxDecoration(
                      color: LuminaTokens.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.cloud_download_rounded,
                          title: 'Enable Background Downloads',
                          subtitle: 'Download matched photos automatically',
                          value: _autoDownloadEnabled,
                          onChanged: _handleAutoDownloadToggle,
                        ),
                        if (_autoDownloadEnabled) ...[
                          Divider(color: LuminaTokens.darkBorder.withOpacity(0.2), height: 1),
                          _buildSwitchTile(
                            icon: Icons.wifi_rounded,
                            title: 'Download on Wi-Fi Only',
                            subtitle: 'Save cellular data charges',
                            value: _onlyWifi,
                            onChanged: (val) {
                              setState(() => _onlyWifi = val);
                              _saveSetting('autodownload_only_wifi', val);
                            },
                          ),
                          Divider(color: LuminaTokens.darkBorder.withOpacity(0.2), height: 1),
                          _buildSwitchTile(
                            icon: Icons.face_unlock_rounded,
                            title: 'Photos of Me',
                            subtitle: 'Download photos matched with my face',
                            value: _downloadMe,
                            onChanged: (val) {
                              setState(() => _downloadMe = val);
                              _saveSetting('autodownload_me', val);
                            },
                          ),
                          Divider(color: LuminaTokens.darkBorder.withOpacity(0.2), height: 1),
                          _buildSwitchTile(
                            icon: Icons.favorite_rounded,
                            title: 'Photos of Close Friends',
                            subtitle: 'Download photos featuring close friends',
                            value: _downloadCloseFriends,
                            onChanged: (val) {
                              setState(() => _downloadCloseFriends = val);
                              _saveSetting('autodownload_close_friends', val);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_autoDownloadEnabled) ...[
                    // Preferences Header
                    Text(
                      'Download Preferences',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Preference Options Panel
                    Container(
                      decoration: BoxDecoration(
                        color: LuminaTokens.darkSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          _buildDropdownTile(
                            icon: Icons.high_quality_rounded,
                            title: 'Download Quality',
                            value: _downloadQuality,
                            items: ['Original', 'High', 'Optimized'],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _downloadQuality = val);
                                _saveSetting('autodownload_quality', val);
                              }
                            },
                          ),
                          Divider(color: LuminaTokens.darkBorder.withOpacity(0.2), height: 1),
                          _buildDropdownTile(
                            icon: Icons.folder_open_rounded,
                            title: 'Save Destination',
                            value: _storageDestination,
                            items: ['Gallery', 'AppStorage'],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _storageDestination = val);
                                _saveSetting('autodownload_destination', val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Statistics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Statistics',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Saved: 142.5 MB',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: LuminaTokens.successLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Stats Grid Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            label: 'Downloaded',
                            value: '38 photos',
                            icon: Icons.check_circle_outline_rounded,
                            color: LuminaTokens.successLight,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            label: 'Pending Queue',
                            value: '0 photos',
                            icon: Icons.hourglass_empty_rounded,
                            color: LuminaTokens.primaryLight,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Download History Header
                    Text(
                      'Recent Downloads',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Download History List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _simulatedHistory.length,
                      itemBuilder: (context, index) {
                        final historyItem = _simulatedHistory[index];
                        return _buildHistoryTile(historyItem)
                            .animate()
                            .fade(duration: 200.ms)
                            .slideY(begin: 0.05, curve: Curves.easeOut);
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: LuminaTokens.darkTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: LuminaTokens.primaryLight,
            activeTrackColor: LuminaTokens.primary.withOpacity(0.5),
            inactiveThumbColor: Colors.white70,
            inactiveTrackColor: LuminaTokens.darkSurfaceSecondary,
          ),
        ],
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

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuminaTokens.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: LuminaTokens.darkTextMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LuminaTokens.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: LuminaTokens.success.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: LuminaTokens.successLight, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? '',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item['time']} • ${item['size']}',
                  style: GoogleFonts.inter(
                    color: LuminaTokens.darkTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item['status'] ?? '',
            style: GoogleFonts.outfit(
              color: LuminaTokens.successLight,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
