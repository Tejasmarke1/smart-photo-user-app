import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/models.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isPersonal = true; // True = Small Personal Group, False = Big Public Group
  File? _groupImageFile;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _groupImageFile = File(picked.path);
        });
      }
    } catch (e) {
      _showSnackBar("Failed to pick image", isError: true);
    }
  }

  Future<void> _handleCreateGroup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authProvider);
      final dio = Dio(BaseOptions(headers: {
        'Authorization': 'Bearer ${authState.accessToken}',
      }));
      final client = ApiClient(dio);
      
      String? coverUrl;
      if (_groupImageFile != null) {
        final uploadResponse = await client.uploadProfilePicture(_groupImageFile!);
        coverUrl = uploadResponse['url']?.toString();
      }

      final Map<String, dynamic> body = {
        "title": _nameController.text.trim(),
        "location": null,
        "password_protected": false,
        "album_password": null,
        "is_public": _isPersonal,
        "face_detection_enabled": true,
        "watermark_enabled": true,
        "download_enabled": true,
        "cover_photo_url": coverUrl,
      };

      final album = await client.createAlbum(body);
      
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList('recent_albums') ?? [];
      if (!current.contains(album.id)) {
        current.insert(0, album.id);
        await prefs.setStringList('recent_albums', current);
      }

      _showSnackBar("Group created successfully!", isError: false);
      
      if (mounted) {
        context.pop();
        context.push('/album/${album.id}', extra: album.sharingCode);
      }
    } catch (e) {
      _showSnackBar(e is DioException ? (e.response?.data['detail'] ?? "Failed to create group") : "Failed to connect to server", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    return Scaffold(
      backgroundColor: LuminaTokens.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LuminaTokens.primaryLight),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Text(
          "Create a Group",
          style: GoogleFonts.outfit(
            color: LuminaTokens.darkText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFCCCCCC), // Styled light gray placeholder
                                    shape: BoxShape.circle,
                                  ),
                                  child: _groupImageFile != null
                                      ? ClipOval(child: Image.file(_groupImageFile!, fit: BoxFit.cover))
                                      : const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 36),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: LuminaTokens.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              style: GoogleFonts.inter(color: LuminaTokens.darkText, fontSize: 18),
                              decoration: InputDecoration(
                                hintText: "Enter Group Name",
                                hintStyle: GoogleFonts.inter(color: LuminaTokens.darkTextMuted, fontSize: 18),
                                border: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: LuminaTokens.darkBorder),
                                ),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: LuminaTokens.darkBorder),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: LuminaTokens.primaryLight),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Group name is required";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 36),
                      
                      GestureDetector(
                        onTap: () {
                          _showSnackBar("Participants selection coming soon!", isError: false);
                        },
                        child: Row(
                          children: [
                            Text(
                              "Add Participants",
                              style: GoogleFonts.outfit(
                                color: LuminaTokens.primaryLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.add, color: LuminaTokens.primaryLight, size: 18),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      Text(
                        "Privacy Settings",
                        style: GoogleFonts.outfit(
                          color: LuminaTokens.darkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      GestureDetector(
                        onTap: () => setState(() => _isPersonal = true),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: LuminaTokens.darkSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isPersonal ? LuminaTokens.primaryLight : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Small Personal Group",
                                    style: GoogleFonts.outfit(
                                      color: _isPersonal ? LuminaTokens.primaryLight : LuminaTokens.darkText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Members can see ALL photos",
                                    style: GoogleFonts.inter(
                                      color: LuminaTokens.darkTextMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _isPersonal ? LuminaTokens.primaryLight : LuminaTokens.darkBorder,
                                    width: 2,
                                  ),
                                ),
                                child: _isPersonal
                                    ? Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: LuminaTokens.primaryLight,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      GestureDetector(
                        onTap: () => setState(() => _isPersonal = false),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: LuminaTokens.darkSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: !_isPersonal ? LuminaTokens.primaryLight : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Big Public Group",
                                    style: GoogleFonts.outfit(
                                      color: !_isPersonal ? LuminaTokens.primaryLight : LuminaTokens.darkText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Members can only see their OWN photos",
                                    style: GoogleFonts.inter(
                                      color: LuminaTokens.darkTextMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: !_isPersonal ? LuminaTokens.primaryLight : LuminaTokens.darkBorder,
                                    width: 2,
                                  ),
                                ),
                                child: !_isPersonal
                                    ? Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: LuminaTokens.primaryLight,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: LuminaTokens.darkSurface,
                border: Border(
                  top: BorderSide(color: LuminaTokens.darkBorder.withOpacity(0.2), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: LuminaTokens.darkTextMuted, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        "Advanced\nSettings",
                        style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted, fontSize: 12, height: 1.2),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LuminaTokens.darkSurfaceSecondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _handleCreateGroup,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              "Create Group",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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
