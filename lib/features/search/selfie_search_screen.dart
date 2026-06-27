import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/models.dart';

class SelfieSearchScreen extends ConsumerStatefulWidget {
  final String albumId;
  final String? sharingCode;

  const SelfieSearchScreen({
    super.key,
    required this.albumId,
    this.sharingCode,
  });

  @override
  ConsumerState<SelfieSearchScreen> createState() => _SelfieSearchScreenState();
}

class _SelfieSearchScreenState extends ConsumerState<SelfieSearchScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  
  bool _isCameraReady = false;
  bool _isUploading = false;
  String _uploadStatus = "";
  
  File? _capturedSelfie;
  List<FaceSearchResponse> _matches = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Select front camera by default
        final frontCam = _cameras!.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          frontCam,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraReady = true;
          });
        }
      }
    } catch (_) {
      _showSnackBar("Failed to access camera", isError: true);
    }
  }

  Future<void> _captureAndSearch() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      setState(() {
        _isUploading = true;
        _uploadStatus = "Capturing selfie...";
      });

      final XFile rawFile = await _cameraController!.takePicture();
      final selfieFile = File(rawFile.path);

      setState(() {
        _capturedSelfie = selfieFile;
        _uploadStatus = "Analyzing face quality...";
      });

      final authState = ref.read(authProvider);
      final dio = Dio(BaseOptions(headers: {
        'Authorization': 'Bearer ${authState.accessToken}',
      }));
      
      final client = ApiClient(dio);
      
      setState(() {
        _uploadStatus = "Performing vector comparison...";
      });

      // Upload selfie to face comparison API (supports optional sharing_code authorization)
      final results = await client.searchBySelfie(
        selfieFile,
        widget.albumId,
        widget.sharingCode,
        50,
        0.55, // Similarity threshold
      );

      setState(() {
        _matches = results;
        _isUploading = false;
        _uploadStatus = "";
      });

      if (results.isEmpty) {
        _showSnackBar("No matches found for your face in this album", isError: false);
      } else {
        _showSnackBar("Found ${results.length} matched photos!", isError: false);
      }

    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadStatus = "";
      });
      _showSnackBar(e is DioException ? (e.response?.data['detail'] ?? "Search failed") : "Failed to connect to AI pipeline", isError: true);
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Face Recognition Search", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if (_capturedSelfie != null && !_isUploading) {
              setState(() {
                _capturedSelfie = null;
                _matches.clear();
              });
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _capturedSelfie != null
          ? _buildResultsView()
          : _buildCameraView(),
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraReady || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: LuminaTokens.primaryLight),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera Preview
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        ),

        // Dark dim backdrop with Oval cut-out mask
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 260,
                    height: 360,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(Radius.elliptical(130, 180)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Oval template guide outline
        Align(
          alignment: Alignment.center,
          child: Container(
            width: 260,
            height: 360,
            decoration: BoxDecoration(
              border: Border.all(color: LuminaTokens.primaryLight, width: 2.5),
              borderRadius: const BorderRadius.all(Radius.elliptical(130, 180)),
            ),
          ),
        ),

        // Instruction Text
        Positioned(
          top: LuminaTokens.spacingLg,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: LuminaTokens.spacingMd, vertical: LuminaTokens.spacingXs),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: LuminaTokens.borderRadiusFull,
            ),
            child: Text(
              "Align your face inside the oval",
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: LuminaTokens.fontWeightMedium),
            ),
          ),
        ),

        // Capture Button
        Positioned(
          bottom: LuminaTokens.spacingXxl,
          child: FloatingActionButton.large(
            onPressed: _isUploading ? null : _captureAndSearch,
            backgroundColor: LuminaTokens.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.camera_rounded, size: 36),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    if (_isUploading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: LuminaTokens.primaryLight),
            const SizedBox(height: LuminaTokens.spacingLg),
            Text(
              _uploadStatus,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: LuminaTokens.textLg, fontWeight: LuminaTokens.fontWeightMedium),
            ),
          ],
        ),
      );
    }

    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sentiment_dissatisfied_rounded, size: 64, color: LuminaTokens.darkTextMuted),
            const SizedBox(height: LuminaTokens.spacingMd),
            Text(
              "No matches found.",
              style: GoogleFonts.outfit(color: Colors.white, fontSize: LuminaTokens.textLg, fontWeight: LuminaTokens.fontWeightBold),
            ),
            const SizedBox(height: LuminaTokens.spacingXxs),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _capturedSelfie = null;
                });
              },
              child: const Text("Try Again"),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(LuminaTokens.spacingMd),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        final url = match.thumbnailUrl ?? "";
        
        return GestureDetector(
          onTap: () {
            // Retrieve matched photo
            // Convert simple match object to full PhotoResponse mock for viewer
            final photo = PhotoResponse(
              id: match.photoId,
              albumId: widget.albumId,
              filename: "Matched_${match.faceId}.jpg",
              thumbnailMediumUrl: match.thumbnailUrl,
            );
            context.push('/photo-viewer', extra: {
              'photo': photo,
              'sharingCode': widget.sharingCode,
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: LuminaTokens.borderRadiusMd,
                child: Image.network(url, fit: BoxFit.cover),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: LuminaTokens.borderRadiusSm,
                  ),
                  child: Text(
                    "${(match.similarityScore * 100).toStringAsFixed(0)}% match",
                    style: GoogleFonts.inter(color: LuminaTokens.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
