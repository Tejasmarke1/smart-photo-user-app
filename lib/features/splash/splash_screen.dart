import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Delay for branding visibility
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    // Check authentication state
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminaTokens.darkBg,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Gradient Glow
          Positioned(
            top: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: LuminaTokens.primary.withOpacity(0.15),
                    blurRadius: 120,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: LuminaTokens.secondary.withOpacity(0.12),
                    blurRadius: 120,
                  ),
                ],
              ),
            ),
          ),
          
          // Core Branding Logo & Text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Icon
                Container(
                  padding: const EdgeInsets.all(LuminaTokens.spacingMd),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LuminaTokens.primaryGradient,
                    boxShadow: LuminaTokens.shadowGlowPrimary,
                  ),
                  child: const Icon(
                    Icons.lens_blur_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ).animate()
                 .fade(duration: 800.ms)
                 .scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: LuminaTokens.spacingLg),
                
                // Brand Text Name
                Text(
                  LuminaTokens.brandName,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    letterSpacing: 2.0,
                    fontWeight: LuminaTokens.fontWeightBold,
                  ),
                ).animate()
                 .fade(delay: 500.ms, duration: 800.ms)
                 .slideY(begin: 0.2, curve: Curves.easeOutQuad),
                
                const SizedBox(height: LuminaTokens.spacingXxs),
                
                // Subtitle
                Text(
                  "Smart Event Photo Discovery",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LuminaTokens.darkTextMuted.withOpacity(0.7),
                    letterSpacing: 1.0,
                  ),
                ).animate()
                 .fade(delay: 800.ms, duration: 800.ms),
              ],
            ),
          ),

          // Bottom Loading / Version details
          Positioned(
            bottom: LuminaTokens.spacingXxl,
            child: Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(LuminaTokens.primaryLight),
                  ),
                ).animate()
                 .fade(delay: 1000.ms),
                 
                const SizedBox(height: LuminaTokens.spacingMd),
                
                Text(
                  "Version ${LuminaTokens.brandVersion}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: LuminaTokens.textXs,
                    color: LuminaTokens.darkTextMuted.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
