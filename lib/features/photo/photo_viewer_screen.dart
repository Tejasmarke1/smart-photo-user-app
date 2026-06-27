import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/models.dart';

class PhotoViewerScreen extends ConsumerStatefulWidget {
  final PhotoResponse photo;
  final String? sharingCode;

  const PhotoViewerScreen({
    super.key,
    required this.photo,
    this.sharingCode,
  });

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  bool _isDownloading = false;

  Future<void> _downloadImage() async {
    // Request permission (mostly required on Android < 10)
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        _showSnackBar("Storage permission denied", isError: true);
        return;
      }
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final authState = ref.read(authProvider);
      final dio = Dio(BaseOptions(headers: {
        'Authorization': 'Bearer ${authState.accessToken}',
      }));
      final client = ApiClient(dio);

      // Call backend to request download (presigned url)
      final response = await client.downloadPhoto(
        widget.photo.id,
        {
          'quality': 'original',
          'watermark': false,
          'extra_data': {
            if (widget.sharingCode != null) 'sharing_code': widget.sharingCode,
          }
        },
      );

      // Now download the actual file from S3 using Dio
      final directory = await _getDownloadDirectory();
      final filePath = "${directory.path}/${response.filename}";
      
      await dio.download(response.downloadUrl, filePath);

      _showSnackBar("Photo downloaded to: $filePath", isError: false);
    } catch (e) {
      _showSnackBar("Download failed. Make sure you have unlocked high-res access.", isError: true);
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    }
    // Android: use public Downloads folder
    final dir = Directory('/storage/emulated/0/Download');
    if (await dir.exists()) {
      return dir;
    }
    return await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
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
    final displayUrl = widget.photo.originalUrl ??
        widget.photo.thumbnailLargeUrl ??
        widget.photo.thumbnailMediumUrl ??
        "";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: _isDownloading ? null : _downloadImage,
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: 'photo_${widget.photo.id}',
          child: PhotoView(
            imageProvider: NetworkImage(displayUrl),
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: LuminaTokens.primaryLight),
            ),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image_rounded, size: 64, color: LuminaTokens.darkTextMuted),
            ),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.5,
          ),
        ),
      ),
    );
  }
}
