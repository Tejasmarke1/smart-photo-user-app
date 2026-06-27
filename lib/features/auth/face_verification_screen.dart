import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:camera/camera.dart';
import '../../core/theme/tokens.dart';
import '../../core/network/api_client.dart';

enum VerificationState {
  searching,
  detected,
  verified
}

class FaceVerificationScreen extends ConsumerStatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  ConsumerState<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends ConsumerState<FaceVerificationScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  VerificationState _state = VerificationState.searching;
  
  // Animation controllers for 3D elements
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late AnimationController _gridController;
  late AnimationController _rippleController;

  Timer? _detectionTimer;
  bool _isProcessingFrame = false;
  
  List<dynamic> _landmarks = [];
  Size? _previewSize;
  
  // Simulated device parallax angles
  double _parallaxX = 0.0;
  double _parallaxY = 0.0;
  late Timer _parallaxTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeCamera();
    _startParallaxSimulation();
  }

  void _initAnimations() {
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  void _startParallaxSimulation() {
    // Generate organic 3D float/parallax movement simulating physical handling
    _parallaxTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        final double t = DateTime.now().millisecondsSinceEpoch / 1000.0;
        setState(() {
          _parallaxX = math.sin(t * 0.8) * 0.15;
          _parallaxY = math.cos(t * 1.2) * 0.12;
        });
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
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
            // Set default frame size for scaling landmarks
            _previewSize = _cameraController!.value.previewSize;
          });
          _startFaceDetectionLoop();
        }
      }
    } catch (e) {
      debugPrint("Camera init failed: $e");
    }
  }

  File? _verifiedPhotoFile;

  void _startFaceDetectionLoop() {
    _detectionTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isCameraReady || _cameraController == null || _isProcessingFrame || _state == VerificationState.verified) {
        return;
      }
      _isProcessingFrame = true;

      try {
        final XFile file = await _cameraController!.takePicture();
        final File photoFile = File(file.path);
        
        final dio = Dio();
        final client = ApiClient(dio);
        final result = await client.detectLiveFace(photoFile);

        if (mounted) {
          if (result['detected'] == true) {
            // Face found!
            _verifiedPhotoFile = photoFile;
            setState(() {
              _landmarks = result['landmarks'] ?? [];
              _state = VerificationState.detected;
              
              // Speed up rotation anim to indicate analysis
              _rotationController.duration = const Duration(seconds: 3);
              _rotationController.repeat();
            });

            // Trigger success verification flow after 2 seconds
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _state == VerificationState.detected) {
                setState(() {
                  _state = VerificationState.verified;
                });
                _rippleController.forward();
                
                // Show success callback / pop back to home after 2.5 seconds
                Future.delayed(const Duration(milliseconds: 2500), () {
                  if (mounted) {
                    context.pop(_verifiedPhotoFile!.path);
                  }
                });
              }
            });
          } else {
            // No face found, reset searching state
            setState(() {
              _state = VerificationState.searching;
              _landmarks = [];
              _rotationController.duration = const Duration(seconds: 8);
              _rotationController.repeat();
            });
            
            // Clean up temporary photo since no face was detected
            if (await photoFile.exists()) {
              await photoFile.delete();
            }
          }
        }
      } catch (e) {
        debugPrint("Face detection error: $e");
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _parallaxTimer.cancel();
    _cameraController?.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    _gridController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color activeBorderColor = LuminaTokens.primaryLight;
    if (_state == VerificationState.detected) {
      activeBorderColor = Colors.tealAccent;
    } else if (_state == VerificationState.verified) {
      activeBorderColor = LuminaTokens.success;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050816),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Top glowing background flare
              Positioned(
                top: -100,
                left: MediaQuery.of(context).size.width * 0.1,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LuminaTokens.primary.withOpacity(0.18),
                    ),
                  ),
                ),
              ),

              // Close Back Button
              Positioned(
                top: LuminaTokens.spacingMd,
                left: LuminaTokens.spacingMd,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.06),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Screen Header Title
                  Text(
                    _state == VerificationState.verified ? "SELFIE CAPTURED" : "FACE PROFILE SETUP",
                    style: GoogleFonts.outfit(
                      fontSize: LuminaTokens.textXl,
                      fontWeight: LuminaTokens.fontWeightBold,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ).animate().fade().slideY(begin: -0.3),
                  
                  const SizedBox(height: LuminaTokens.spacingXs),

                  Text(
                    _state == VerificationState.verified 
                        ? "Selfie scan completed successfully!" 
                        : "Fit your face inside the frame to setup your face profile.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: LuminaTokens.textXs,
                      color: Colors.white54,
                    ),
                  ).animate().fade(delay: 150.ms),

                  const Expanded(child: SizedBox()),

                  // 3D Matrix Layer Container
                  Center(
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0018) // 3D Perspective!
                        ..rotateX(_parallaxY)   // Tilt based on animated simulation
                        ..rotateY(_parallaxX),
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ripple animation on success
                          if (_state == VerificationState.verified)
                            AnimatedBuilder(
                              animation: _rippleController,
                              builder: (context, child) {
                                return Container(
                                  width: 250 + (100 * _rippleController.value),
                                  height: 250 + (100 * _rippleController.value),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: LuminaTokens.success.withOpacity(1.0 - _rippleController.value),
                                      width: 2.0,
                                    ),
                                  ),
                                );
                              },
                            ),

                          // Outer Pulsating Border Ring
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final double pulse = 1.0 + (_pulseController.value * 0.05);
                              return Transform.scale(
                                scale: _state == VerificationState.searching ? pulse : 1.0,
                                child: Container(
                                  width: 258,
                                  height: 258,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: activeBorderColor.withOpacity(0.4),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Primary Camera Preview Frame
                          Container(
                            width: 236,
                            height: 236,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: activeBorderColor,
                                width: 3.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: activeBorderColor.withOpacity(0.35),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildCameraPreview(),
                                  _buildScanLaser(),
                                  if (_state == VerificationState.detected)
                                    _buildGridOverlay(),
                                  if (_landmarks.isNotEmpty)
                                    CustomPaint(
                                      painter: LandmarksPainter(
                                        landmarks: _landmarks,
                                        previewSize: _previewSize,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // 3D Holographic Orbit Ring 1 (Tilted forward clockwise)
                          AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.002)
                                  ..rotateX(1.1)
                                  ..rotateZ(_rotationController.value * 2 * math.pi),
                                alignment: Alignment.center,
                                child: CustomPaint(
                                  painter: HolographicRingPainter(
                                    color: activeBorderColor,
                                    dashes: 18,
                                  ),
                                  size: const Size(280, 280),
                                ),
                              );
                            },
                          ),

                          // 3D Holographic Orbit Ring 2 (Tilted back counter-clockwise)
                          AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.002)
                                  ..rotateX(-1.0)
                                  ..rotateZ(-_rotationController.value * 2 * math.pi),
                                alignment: Alignment.center,
                                child: CustomPaint(
                                  painter: HolographicRingPainter(
                                    color: _state == VerificationState.searching ? Colors.cyanAccent : activeBorderColor,
                                    dashes: 12,
                                  ),
                                  size: const Size(295, 295),
                                ),
                              );
                            },
                          ),

                          // Floating scanning particles
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: ParticlePainter(
                                  progress: _rotationController.value,
                                  color: activeBorderColor,
                                ),
                              ),
                            ),
                          ),

                          // Lens flare reflection highlight
                          Positioned(
                            top: 20,
                            right: 40,
                            child: Container(
                              width: 80,
                              height: 15,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.0),
                                    Colors.white.withOpacity(0.25),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                              transform: Matrix4.rotationZ(-0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Expanded(child: SizedBox()),

                  // Scanner Status Display Panel
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: LuminaTokens.spacingLg),
                    padding: const EdgeInsets.all(LuminaTokens.spacingMd),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusIcon(),
                        const SizedBox(width: LuminaTokens.spacingSm),
                        Text(
                          _buildStatusText(),
                          style: GoogleFonts.outfit(
                            fontSize: LuminaTokens.textXs,
                            fontWeight: LuminaTokens.fontWeightBold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 300.ms),

                  const SizedBox(height: 60),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraReady || _cameraController == null) {
      return Container(
        color: const Color(0xFF070A18),
        child: const Center(
          child: CircularProgressIndicator(color: LuminaTokens.primaryLight),
        ),
      );
    }
    return CameraPreview(_cameraController!);
  }

  Widget _buildScanLaser() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        return Positioned(
          top: 236 * _scanController.value,
          left: 0,
          right: 0,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: (_state == VerificationState.verified ? LuminaTokens.success : LuminaTokens.primaryLight).withOpacity(0.8),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _state == VerificationState.verified ? LuminaTokens.success : LuminaTokens.primaryLight,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridOverlay() {
    return AnimatedBuilder(
      animation: _gridController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.15 * (1.0 - _gridController.value),
          child: CustomPaint(
            painter: GridPainter(),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon() {
    switch (_state) {
      case VerificationState.searching:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: LuminaTokens.primaryLight,
          ),
        );
      case VerificationState.detected:
        return const Icon(Icons.face_retouching_natural_rounded, color: Colors.tealAccent, size: 20);
      case VerificationState.verified:
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: LuminaTokens.success,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 14),
        );
    }
  }

  String _buildStatusText() {
    switch (_state) {
      case VerificationState.searching:
        return "POSITION FACE INSIDE FRAME";
      case VerificationState.detected:
        return "FACE DETECTED... ANALYZING";
      case VerificationState.verified:
        return "SELFIE CAPTURED";
    }
  }
}

// Custom Painter for 3D Holographic Orbit Ring
class HolographicRingPainter extends CustomPainter {
  final Color color;
  final int dashes;

  HolographicRingPainter({required this.color, required this.dashes});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final paint = Paint()
      ..color = color.withOpacity(0.65)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double dashAngle = (2 * math.pi) / dashes;

    for (int i = 0; i < dashes; i++) {
      final double angle = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        dashAngle * 0.45,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for Orbiting Particles
class ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  ParticlePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double baseRadius = size.width / 2 - 20;

    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Build 6 orbit particles
    final List<double> phaseOffsets = [0, 1.0, 2.0, 3.0, 4.0, 5.0];
    for (int i = 0; i < phaseOffsets.length; i++) {
      final double angle = (progress * 2 * math.pi) + (phaseOffsets[i] * (math.pi / 3));
      final double radOffset = math.sin(progress * 4 * math.pi + i) * 8;
      
      final Offset offset = Offset(
        center.dx + (baseRadius + radOffset) * math.cos(angle),
        center.dy + (baseRadius + radOffset) * math.sin(angle),
      );
      
      canvas.drawCircle(offset, 3.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

// Custom Painter for Face Landmarks overlay mapping
class LandmarksPainter extends CustomPainter {
  final List<dynamic> landmarks;
  final Size? previewSize;

  LandmarksPainter({required this.landmarks, required this.previewSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty || previewSize == null) return;

    final paint = Paint()
      ..color = Colors.tealAccent
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // RetinaFace returns coordinates based on original image dimension (e.g. 480x640)
    // Scale coordinates into 236x236 preview widget dimension
    final double imgW = previewSize!.height; // Width/Height are reversed due to camera rotation orientation
    final double imgH = previewSize!.width;

    for (var point in landmarks) {
      if (point is List && point.length == 2) {
        final double x = (point[0] as num).toDouble();
        final double y = (point[1] as num).toDouble();

        // Project coordinate
        final double scaleX = size.width / imgW;
        final double scaleY = size.height / imgH;

        final Offset offset = Offset(x * scaleX, y * scaleY);

        // Draw glowing biometric dots
        canvas.drawCircle(offset, 6.0, paint);
        canvas.drawCircle(offset, 2.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LandmarksPainter oldDelegate) => true;
}

// Custom Painter for HUD biometric Grid Overlay
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.tealAccent
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final int divisions = 6;
    final double cellW = size.width / divisions;
    final double cellH = size.height / divisions;

    for (int i = 1; i < divisions; i++) {
      // Horizontal grid lines
      canvas.drawLine(Offset(0, i * cellH), Offset(size.width, i * cellH), paint);
      // Vertical grid lines
      canvas.drawLine(Offset(i * cellW, 0), Offset(i * cellW, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
