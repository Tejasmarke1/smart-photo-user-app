import 'dart:async';
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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inputController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isPhoneMode = false;
  bool _otpSent = false;
  bool _isLoading = false;
  int _timerSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _inputController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer(int seconds) {
    setState(() {
      _timerSeconds = seconds;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    final inputVal = _inputController.text.trim();
    final request = SendOtpRequest(
      email: !_isPhoneMode ? inputVal : null,
      phone: _isPhoneMode ? inputVal : null,
      otpType: "login",
    );

    try {
      final dio = Dio();
      final client = ApiClient(dio);
      final response = await client.sendOtp(request);
      
      if (response.success) {
        setState(() {
          _otpSent = true;
        });
        _startResendTimer(response.canResendIn);
        _showSnackBar(response.message, isError: false);
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
          errMsg = "Failed to send OTP";
        }
      }
      _showSnackBar(errMsg, isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otpVal = _otpController.text.trim();
    if (otpVal.length < 4) {
      _showSnackBar("Please enter the complete verification code", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final inputVal = _inputController.text.trim();
    final request = VerifyOtpRequest(
      email: !_isPhoneMode ? inputVal : null,
      phone: _isPhoneMode ? inputVal : null,
      otpCode: otpVal,
    );

    try {
      final dio = Dio();
      final client = ApiClient(dio);
      final response = await client.verifyOtp(request);

      if (response.success) {
        if (response.userExists && response.accessToken != null && response.refreshToken != null) {
          // Store tokens and navigate home
          await ref.read(authProvider.notifier).login(
            response.accessToken!,
            response.refreshToken!,
          );
          if (mounted) context.go('/home');
        } else if (response.requiresSignup && response.tempToken != null) {
          // Navigate to signup with temp token
          final email = !_isPhoneMode ? inputVal : null;
          final phone = _isPhoneMode ? inputVal : null;
          if (mounted) {
            context.go('/signup', extra: {
              'tempToken': response.tempToken,
              'email': email,
              'phone': phone,
            });
          }
        }
      } else {
        _showSnackBar(response.message, isError: true);
      }
    } catch (e) {
      String errMsg = "Verification failed";
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
          errMsg = "Invalid OTP";
        }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: LuminaTokens.spacingXl),
              
              // Top Icon Back Button (if OTP is open)
              if (_otpSent)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: LuminaTokens.darkText),
                  onPressed: () {
                    setState(() {
                      _otpSent = false;
                      _otpController.clear();
                    });
                  },
                ).animate().fade(),

              const SizedBox(height: LuminaTokens.spacingLg),

              // Title Header
              Text(
                _otpSent ? "Verify Identity" : "Welcome to Lumina",
                style: Theme.of(context).textTheme.headlineLarge,
              ).animate().fade().slideX(begin: -0.2),

              const SizedBox(height: LuminaTokens.spacingXs),

              Text(
                _otpSent 
                    ? "We've sent a 6-digit code to ${_inputController.text}" 
                    : "Enter your details to sign in or get started instantly.",
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fade(delay: 100.ms),

              const SizedBox(height: LuminaTokens.spacingXxl),

              // Auth input Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!_otpSent) ...[
                      // Email / Phone Selector Toggle
                      Row(
                        children: [
                          _buildTabButton("Email Address", !_isPhoneMode, () {
                            setState(() {
                              _isPhoneMode = false;
                              _inputController.clear();
                            });
                          }),
                          _buildTabButton("Phone Number", _isPhoneMode, () {
                            setState(() {
                              _isPhoneMode = true;
                              _inputController.clear();
                            });
                          }),
                        ],
                      ),
                      
                      const SizedBox(height: LuminaTokens.spacingLg),

                      // Input Field
                      TextFormField(
                        controller: _inputController,
                        keyboardType: _isPhoneMode ? TextInputType.phone : TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: _isPhoneMode ? "Phone Number" : "Email Address",
                          hintText: _isPhoneMode ? "+91 XXXXX XXXXX" : "name@example.com",
                          prefixIcon: Icon(
                            _isPhoneMode ? Icons.phone_android_rounded : Icons.alternate_email_rounded,
                            color: LuminaTokens.darkTextMuted,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "This field is required";
                          }
                          if (!_isPhoneMode && !value.contains('@')) {
                            return "Please enter a valid email address";
                          }
                          return null;
                        },
                      ).animate().fade().slideY(begin: 0.1),
                    ] else ...[
                      // OTP Input Field
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: LuminaTokens.fontWeightBold,
                          letterSpacing: 8,
                        ),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: "Verification Code",
                          hintText: "000000",
                          counterText: "",
                          prefixIcon: Icon(Icons.lock_clock_rounded, color: LuminaTokens.darkTextMuted),
                        ),
                      ).animate().fade().slideY(begin: 0.1),
                    ],

                    const SizedBox(height: LuminaTokens.spacingXl),

                    // Primary Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading 
                            ? null 
                            : (_otpSent ? _verifyOtp : _sendOtp),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(_otpSent ? "Verify & Sign In" : "Send Verification Code"),
                      ),
                    ).animate().fade(delay: 200.ms),

                    // Resend Timer (if OTP sent)
                    if (_otpSent) ...[
                      const SizedBox(height: LuminaTokens.spacingLg),
                      TextButton(
                        onPressed: _timerSeconds == 0 && !_isLoading ? _sendOtp : null,
                        child: Text(
                          _timerSeconds > 0
                              ? "Resend code in ${_timerSeconds}s"
                              : "Resend verification code",
                          style: GoogleFonts.inter(
                            color: _timerSeconds > 0 
                                ? LuminaTokens.darkTextMuted 
                                : LuminaTokens.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: LuminaTokens.spacingSm),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? LuminaTokens.primary : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: isActive ? LuminaTokens.fontWeightSemibold : LuminaTokens.fontWeightRegular,
              color: isActive ? LuminaTokens.darkText : LuminaTokens.darkTextMuted,
            ),
          ),
        ),
      ),
    );
  }
}
