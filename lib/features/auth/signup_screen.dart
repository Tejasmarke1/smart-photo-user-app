import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
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
  
  bool _isLoading = false;
  File? _capturedPhoto;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startBiometricScan() async {
    final result = await context.push('/face-verification');
    if (result != null && result is String) {
      setState(() {
        _capturedPhoto = File(result);
      });
    }
  }

  Future<void> _completeSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_capturedPhoto == null) {
      _showSnackBar("A live biometric profile verification is required to create an account", isError: true);
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
                  "Perform a biometric verification scan to complete your account registration.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fade(delay: 100.ms),

                const SizedBox(height: LuminaTokens.spacingXxl),

                // Biometric 3D Scanner Button or Result Image
                Center(
                  child: Column(
                    children: [
                      if (_capturedPhoto != null) ...[
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: LuminaTokens.success,
                              width: 3.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: LuminaTokens.success.withOpacity(0.35),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.file(_capturedPhoto!, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: LuminaTokens.spacingLg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_user_rounded, color: LuminaTokens.success, size: 20),
                            const SizedBox(width: LuminaTokens.spacingXs),
                            Text(
                              "Biometrics Verified",
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
                          onPressed: _startBiometricScan,
                          icon: const Icon(Icons.refresh_rounded, color: LuminaTokens.darkText),
                          label: Text(
                            "Retake Biometric Scan",
                            style: GoogleFonts.inter(
                              color: LuminaTokens.darkText,
                              fontWeight: LuminaTokens.fontWeightMedium,
                            ),
                          ),
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: _startBiometricScan,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: LuminaTokens.primaryLight.withOpacity(0.4),
                                width: 2.0,
                              ),
                              color: Colors.white.withOpacity(0.03),
                              boxShadow: [
                                BoxShadow(
                                  color: LuminaTokens.primary.withOpacity(0.15),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.face_retouching_natural_rounded,
                                    size: 48,
                                    color: LuminaTokens.primaryLight,
                                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                                   .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.seconds),
                                  const SizedBox(height: LuminaTokens.spacingSm),
                                  Text(
                                    "START FACE ID SCAN",
                                    style: GoogleFonts.outfit(
                                      fontSize: LuminaTokens.textXs,
                                      fontWeight: LuminaTokens.fontWeightBold,
                                      color: LuminaTokens.primaryLight,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: LuminaTokens.spacingLg),
                        Text(
                          "Tap the scanner to verify your identity.",
                          style: GoogleFonts.outfit(
                            color: LuminaTokens.darkTextMuted,
                            fontSize: LuminaTokens.textXs,
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
}
