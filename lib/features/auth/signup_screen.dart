import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  String? _selectedProfilePic;

  final List<String> _avatarOptions = [
    "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80",
    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80",
    "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80",
    "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80",
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final request = SignupRequest(
      tempToken: widget.tempToken,
      name: _nameController.text.trim(),
      email: widget.email,
      phone: widget.phone,
      profilePictureUrl: _selectedProfilePic,
    );

    try {
      final dio = Dio();
      final client = ApiClient(dio);
      final response = await client.signup(request);

      if (response.success) {
        // Authenticate the user globally
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
      _showSnackBar(e is DioException ? (e.response?.data['detail'] ?? "Signup failed") : "Connection failed", isError: true);
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
                const SizedBox(height: LuminaTokens.spacingXl),

                Text(
                  "Complete Profile",
                  style: Theme.of(context).textTheme.headlineLarge,
                ).animate().fade().slideX(begin: -0.2),

                const SizedBox(height: LuminaTokens.spacingXs),

                Text(
                  "Tell us a bit about yourself so photographers and friends can identify you.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fade(delay: 100.ms),

                const SizedBox(height: LuminaTokens.spacingXxl),

                // Profile Avatar Picker
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: LuminaTokens.darkSurfaceSecondary,
                        backgroundImage: _selectedProfilePic != null 
                            ? NetworkImage(_selectedProfilePic!) 
                            : null,
                        child: _selectedProfilePic == null 
                            ? const Icon(Icons.person_rounded, size: 54, color: LuminaTokens.darkTextMuted)
                            : null,
                      ),
                      const SizedBox(height: LuminaTokens.spacingMd),
                      Text(
                        "Choose an Avatar",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: LuminaTokens.textXs,
                          fontWeight: LuminaTokens.fontWeightMedium,
                        ),
                      ),
                      const SizedBox(height: LuminaTokens.spacingSm),
                      
                      // Avatar List Options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _avatarOptions.map((url) {
                          final isSelected = _selectedProfilePic == url;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedProfilePic = url;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: LuminaTokens.spacingXxs),
                              padding: const EdgeInsets.all(2.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? LuminaTokens.primary : Colors.transparent,
                                  width: 2.0,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(url),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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

                // Action Button
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
