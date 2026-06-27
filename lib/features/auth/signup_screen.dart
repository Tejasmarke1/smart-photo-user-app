import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:camera/camera.dart';
import '../../core/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/models.dart';

class SignupScreen extends ConsumerStatefulWidget {
  final String tempToken;
  final String? email;
  final String? phone;

  const SignupScreen({
    super.key,
    required this.tempToken,
    this.email,
    this.phone,
  });

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  
  bool _isCameraReady = false;
  bool _isLoading = false;
  File? _capturedPhoto;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Locate front camera for selfie capture
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
    } catch (e) {
      debugPrint("Failed to access front camera: $e");
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      final XFile file = await _cameraController!.takePicture();
      setState(() {
        _capturedPhoto = File(file.path);
      });
    } catch (e) {
      _showSnackBar("Failed to capture photo", isError: true);
    }
  }

  Future<void> _completeSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_capturedPhoto == null) {
      _showSnackBar("A live profile capture is required to create an account", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = Dio();
      final client = ApiClient(dio);
      
      // Step 1: Upload captured profile photo to receive S3 public URL
      final uploadResponse = await client.uploadProfilePicture(_capturedPhoto!);
      final profilePicUrl = uploadResponse['url']?.toString();

      if (profilePicUrl == null) {
        throw Exception("Failed to retrieve profile image URL");
      }

      // Step 2: Proceed with signup registration
      final request = SignupRequest(
        tempToken: widget.tempToken,
        name: _nameController.text.trim(),
        email: widget.email,
        phone: widget.phone,
        profilePictureUrl: profilePicUrl,
      );

      final response = await client.signup(request);

      if (response.success) {
        await ref.read(authProvider.notifier).login(
          response.accessToken,
          response.refreshToken,
          name: response.user['name']?.toString(),
          email: response.user['email']?.toString(),
        );
        if (mounted) context.go('/home');
      } else {
        _showSnackBar(response.message, isError: true);
      }
    } catch (e) {
      String errMsg = "Connection failed";
      if (e is DioException) {
        final detail = e.response?.data?['detail'];
        if (detail != null) {
          if (detail is String) {
            errMsg = detail;
          } else if (detail is List) {
            try {
              errMsg = detail.map((err) => err['msg'] ?? '').join(', ');
            } catch (_) {
              errMsg = detail.toString();
            }
          } else {
            errMsg = detail.toString();
          }
        } else {
          errMsg = "Signup failed";
        }
      } else {
        errMsg = e.toString();
      }
      _showSnackBar(errMsg, isError: true);
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: LuminaTokens.spacingLg,
            vertical: LuminaTokens.spacingXl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: LuminaTokens.spacingLg),

                Text(
                  "Complete Profile",
                  style: Theme.of(context).textTheme.headlineLarge,
                ).animate().fade().slideX(begin: -0.2),

                const SizedBox(height: LuminaTokens.spacingXs),

                Text(
                  "Capture a live profile picture to complete your account registration.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fade(delay: 100.ms),

                const SizedBox(height: LuminaTokens.spacingXxl),

                // 3D Scanner / Camera Capture Card
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _capturedPhoto != null ? LuminaTokens.success : LuminaTokens.primaryLight,
                            width: 3.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_capturedPhoto != null ? LuminaTokens.success : LuminaTokens.primary)
                                  .withOpacity(0.35),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _capturedPhoto != null
                              ? Image.file(_capturedPhoto!, fit: BoxFit.cover)
                              : _buildCameraWidget(),
                        ),
                      ),
                      const SizedBox(height: LuminaTokens.spacingLg),
                      
                      // Secondary Action (Capture / Retake)
                      if (_capturedPhoto != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: LuminaTokens.success, size: 20),
                            const SizedBox(width: LuminaTokens.spacingXs),
                            Text(
                              "Holographic Scan Completed",
                              style: GoogleFonts.outfit(
                                color: LuminaTokens.success,
                                fontWeight: LuminaTokens.fontWeightBold,
                                fontSize: LuminaTokens.textSm,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: LuminaTokens.spacingSm),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _capturedPhoto = null;
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, color: LuminaTokens.darkText),
                          label: Text(
                            "Retake Capture",
                            style: GoogleFonts.inter(color: LuminaTokens.darkText, fontWeight: LuminaTokens.fontWeightMedium),
                          ),
                        ),
                      ] else ...[
                        Text(
                          "Fit your face inside the scanner frame",
                          style: GoogleFonts.outfit(
                            color: LuminaTokens.darkTextMuted,
                            fontSize: LuminaTokens.textXs,
                          ),
                        ),
                        const SizedBox(height: LuminaTokens.spacingMd),
                        IconButton.filled(
                          onPressed: _isCameraReady ? _capturePhoto : null,
                          icon: const Icon(Icons.camera_front_rounded, size: 28),
                          style: IconButton.styleFrom(
                            backgroundColor: LuminaTokens.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(LuminaTokens.spacingMd),
                          ),
                        ),
                      ],
                    ],
                  ).animate().fade(delay: 200.ms),
                ),

                const SizedBox(height: LuminaTokens.spacingXxl),

                // Name Input Field
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: "Your Full Name",
                    hintText: "John Doe",
                    prefixIcon: Icon(Icons.badge_rounded, color: LuminaTokens.darkTextMuted),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter your name";
                    }
                    if (value.trim().length < 3) {
                      return "Name must be at least 3 characters";
                    }
                    return null;
                  },
                ).animate().fade(delay: 300.ms),

                const SizedBox(height: LuminaTokens.spacingXl),

                // Complete Action Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeSignup,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text("Save & Enter Home"),
                  ),
                ).animate().fade(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraWidget() {
    if (!_isCameraReady || _cameraController == null) {
      return Container(
        color: LuminaTokens.darkSurface,
        child: const Center(
          child: CircularProgressIndicator(color: LuminaTokens.primaryLight),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        
        // Circular Holographic sweeps laser overlay
        Positioned.fill(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: LuminaTokens.primaryLight.withOpacity(0.85),
                    blurRadius: 10,
                    spreadRadius: 2.5,
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [Colors.transparent, LuminaTokens.primaryLight, Colors.transparent],
                ),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .slideY(begin: 0.05, end: 0.95, duration: 1.8.seconds, curve: Curves.easeInOut),
        ),
        
        // Ring overlay grid guide line
        Positioned.fill(
          child: Center(
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: LuminaTokens.primaryLight.withOpacity(0.25),
                  width: 1.0,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
