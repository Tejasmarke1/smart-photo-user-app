import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/models.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  final String albumId;
  final AlbumDetailResponse albumDetail;

  const GroupSettingsScreen({
    super.key,
    required this.albumId,
    required this.albumDetail,
  });

  @override
  ConsumerState<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  late String _groupTitle;
  bool _isMuted = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _groupTitle = widget.albumDetail.title;
  }

  Future<void> _editGroupName() async {
    final controller = TextEditingController(text: _groupTitle);
    
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LuminaTokens.darkSurface,
        title: Text(
          "Edit Group Name",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter group name",
            hintStyle: GoogleFonts.inter(color: LuminaTokens.darkTextMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: LuminaTokens.primaryLight)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: LuminaTokens.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: LuminaTokens.primary),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text("Save", style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newTitle == null || newTitle.isEmpty || newTitle == _groupTitle) return;

    setState(() => _isSaving = true);

    try {
      final authState = ref.read(authProvider);
      final dio = Dio(BaseOptions(headers: {
        'Authorization': 'Bearer ${authState.accessToken}',
      }));
      
      // Call backend PATCH /albums/{id}
      await dio.patch(
        '/albums/${widget.albumId}',
        data: {'title': newTitle},
      );

      setState(() {
        _groupTitle = newTitle;
        _isSaving = false;
      });
      _showSnackBar("Group renamed successfully!", isError: false);
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnackBar("Failed to rename group: $e", isError: true);
    }
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LuminaTokens.darkSurface,
        title: Text("Leave Group?", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("You will no longer see this group in your list.", style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel", style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Leave", style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_albums') ?? [];
    list.remove(widget.albumId);
    await prefs.setStringList('recent_albums', list);
    
    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LuminaTokens.darkSurface,
        title: Text("Delete Group?", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("This will permanently delete this group and all its photos.", style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel", style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete", style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final authState = ref.read(authProvider);
      final dio = Dio(BaseOptions(headers: {
        'Authorization': 'Bearer ${authState.accessToken}',
      }));
      
      // Call backend DELETE /albums/{id}
      await dio.delete('/albums/${widget.albumId}');

      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('recent_albums') ?? [];
      list.remove(widget.albumId);
      await prefs.setStringList('recent_albums', list);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      _showSnackBar("Failed to delete group: $e", isError: true);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? LuminaTokens.error : LuminaTokens.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final photographerName = widget.albumDetail.photographerName ?? "Photographer";

    return Scaffold(
      backgroundColor: LuminaTokens.darkBg,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Organic Curved Banner matching design Image 3
                Stack(
                  children: [
                    // Curved Background Shape
                    Container(
                      height: 180,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E4366), Color(0xFF14223A)],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                    ),
                    
                    // Left Back Arrow
                    Positioned(
                      top: 40,
                      left: 16,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    
                    // Center Group Avatar & Details
                    Positioned(
                      top: 40,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(Icons.group_rounded, color: Colors.white, size: 36),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _groupTitle,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: _editGroupName,
                                child: const Icon(Icons.edit_rounded, color: Colors.white70, size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.albumDetail.isPublic ? "Public Group" : "Private Group",
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Invite people row
                ListTile(
                  leading: const Icon(Icons.link_rounded, color: LuminaTokens.primaryLight),
                  title: Text(
                    "Invite people to Join Group",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: LuminaTokens.primaryLight),
                  onTap: () => context.push('/share-link/${widget.albumId}', extra: widget.albumDetail),
                ),

                const SizedBox(height: 8),

                // Quick Action Buttons Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(Icons.settings_rounded, "Settings", () {
                        _showSnackBar("Settings are configured by the admin.", isError: false);
                      }),
                      _buildQuickAction(
                        _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        _isMuted ? "Unmute" : "Mute",
                        () {
                          setState(() => _isMuted = !_isMuted);
                          _showSnackBar(_isMuted ? "Group notifications muted" : "Group notifications unmuted", isError: false);
                        },
                      ),
                      _buildQuickAction(Icons.history_rounded, "Notification log", () {
                        _showSnackBar("No notifications in the log.", isError: false);
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Participants List Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Participants : 2",
                        style: GoogleFonts.outfit(
                          color: LuminaTokens.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.search_rounded, color: LuminaTokens.primaryLight, size: 18),
                          const SizedBox(width: 14),
                          Row(
                            children: [
                              const Icon(Icons.add_rounded, color: LuminaTokens.primaryLight, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "Add",
                                style: GoogleFonts.inter(color: LuminaTokens.primaryLight, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Participant Item 1 (Admin)
                _buildParticipantTile(
                  name: photographerName,
                  subtitle: "Photographer / Creator",
                  isAdmin: true,
                ),

                // Participant Item 2 (You)
                _buildParticipantTile(
                  name: "${authState.userName ?? 'You'} (You)",
                  subtitle: authState.userEmail ?? "",
                  isAdmin: false,
                ),

                Center(
                  child: TextButton(
                    onPressed: () => _showSnackBar("All participants shown", isError: false),
                    child: Text(
                      "Show All",
                      style: GoogleFonts.inter(
                        color: LuminaTokens.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons at the bottom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E4B66),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _leaveGroup,
                            icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                            label: Text("Leave Group", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade900,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _deleteGroup,
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: Text("Delete Group", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          if (_isSaving)
            Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: LuminaTokens.primaryLight),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LuminaTokens.darkSurface,
              shape: BoxShape.circle,
              border: Border.all(color: LuminaTokens.primaryLight.withOpacity(0.2)),
            ),
            child: Icon(icon, color: LuminaTokens.primaryLight, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: LuminaTokens.darkTextMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile({
    required String name,
    required String subtitle,
    required bool isAdmin,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LuminaTokens.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: LuminaTokens.primary.withOpacity(0.1),
            child: const Icon(Icons.person_rounded, color: LuminaTokens.primaryLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: LuminaTokens.darkTextMuted.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "Admin",
                style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
