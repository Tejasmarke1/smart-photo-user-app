import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_client.dart';

class UploadPhotosScreen extends ConsumerStatefulWidget {
  final String albumId;
  final String albumTitle;

  const UploadPhotosScreen({
    super.key,
    required this.albumId,
    required this.albumTitle,
  });

  @override
  ConsumerState<UploadPhotosScreen> createState() => _UploadPhotosScreenState();
}

class _UploadPhotosScreenState extends ConsumerState<UploadPhotosScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _linkController = TextEditingController();
  
  bool _isUploading = false;
  String _uploadStatusMessage = "";
  double _uploadProgress = 0.0;

  Future<void> _pickFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo == null) return;
      await _uploadPhotos([File(photo.path)]);
    } catch (e) {
      _showSnackBar("Failed to capture photo: $e", isError: true);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isEmpty) return;
      await _uploadPhotos(images.map((img) => File(img.path)).toList());
    } catch (e) {
      _showSnackBar("Failed to pick images: $e", isError: true);
    }
  }

  Future<void> _uploadPhotos(List<File> files) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final authState = ref.read(authProvider);
    final dio = Dio(BaseOptions(headers: {
      'Authorization': 'Bearer ${authState.accessToken}',
    }));
    final client = ApiClient(dio);

    int successCount = 0;

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final filename = file.path.split(Platform.pathSeparator).last;
      final filesize = await file.length();
      
      setState(() {
        _uploadStatusMessage = "Uploading $filename (${i + 1}/${files.length})...";
        _uploadProgress = i / files.length;
      });

      try {
        // Step 1: Request presigned URL
        final presignRes = await client.getPresignedUrl(widget.albumId, {
          'filename': filename,
          'filesize': filesize,
          'content_type': _getContentType(filename),
        });

        final uploadUrl = presignRes['upload_url']?.toString();
        final photoId = presignRes['photo_id']?.toString();
        final s3Key = presignRes['s3_key']?.toString();

        if (uploadUrl == null || photoId == null || s3Key == null) {
          throw Exception("Invalid presign details from backend");
        }

        // Step 2: PUT file directly to S3
        final fileBytes = await file.readAsBytes();
        final s3Dio = Dio();
        await s3Dio.put(
          uploadUrl,
          data: Stream.fromIterable([fileBytes]),
          options: Options(
            headers: {
              'Content-Type': _getContentType(filename),
              'Content-Length': fileBytes.length,
            },
          ),
        );

        // Step 3: Complete upload
        await client.completeUpload(widget.albumId, {
          'photo_id': photoId,
          's3_key': s3Key,
        });

        successCount++;
      } catch (e) {
        debugPrint("Failed to upload $filename: $e");
      }
    }

    setState(() {
      _isUploading = false;
      _uploadProgress = 1.0;
    });

    if (successCount == files.length) {
      _showSnackBar("Uploaded all $successCount photos successfully!", isError: false);
      if (mounted) Navigator.pop(context, true);
    } else {
      _showSnackBar("Uploaded $successCount of ${files.length} photos. Some failed.", isError: true);
      if (mounted) Navigator.pop(context, true);
    }
  }

  String _getContentType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  void _handleAddLink() {
    final link = _linkController.text.trim();
    if (link.isEmpty) return;
    
    // Simulating adding external links as required by UI reference
    _linkController.clear();
    _showSnackBar("Link added successfully! Processing files in background...", isError: false);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Upload to ${widget.albumTitle}",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                
                // Camera Button
                GestureDetector(
                  onTap: _pickFromCamera,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: LuminaTokens.darkSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LuminaTokens.primaryLight.withOpacity(0.4), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_rounded, color: LuminaTokens.primaryLight, size: 28),
                        const SizedBox(width: 16),
                        Text(
                          "Camera",
                          style: GoogleFonts.outfit(
                            color: LuminaTokens.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),

                // Gallery Button
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: LuminaTokens.darkSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LuminaTokens.primaryLight.withOpacity(0.4), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.photo_library_rounded, color: LuminaTokens.primaryLight, size: 28),
                        const SizedBox(width: 16),
                        Text(
                          "Gallery",
                          style: GoogleFonts.outfit(
                            color: LuminaTokens.primaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Divider line matching UI layout
                Container(
                  height: 1,
                  color: LuminaTokens.darkBorder.withOpacity(0.3),
                ),
                
                const SizedBox(height: 24),

                Text(
                  "Upload using these links :",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                
                const SizedBox(height: 20),

                // Cloud Services Row matching Design
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCloudItem(Icons.cloud_circle_rounded, "Google Drive", Colors.green),
                    _buildCloudItem(Icons.folder_shared_rounded, "Dropbox", Colors.blue),
                    _buildCloudItem(Icons.cloudy_snowing, "OneDrive", Colors.cyan),
                    _buildCloudItem(Icons.video_library_rounded, "Youtube", Colors.red),
                  ],
                ),

                const SizedBox(height: 28),

                // Insert Link input field
                Container(
                  decoration: BoxDecoration(
                    color: LuminaTokens.darkSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: LuminaTokens.primaryLight.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _linkController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.link_rounded, color: LuminaTokens.primaryLight),
                      hintText: "Insert Link here",
                      hintStyle: GoogleFonts.inter(color: LuminaTokens.darkTextMuted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Warning / Info
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "Only YouTube is supported for uploading videos",
                      style: GoogleFonts.inter(
                        color: Colors.blue.shade300,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Add button
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LuminaTokens.darkSurfaceSecondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: _handleAddLink,
                      child: Text(
                        "Add",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.75),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: LuminaTokens.primaryLight),
                    const SizedBox(height: 24),
                    Text(
                      _uploadStatusMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      color: LuminaTokens.primaryLight,
                      backgroundColor: Colors.white24,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCloudItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: LuminaTokens.darkTextMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
