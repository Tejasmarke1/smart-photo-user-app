import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/face_verification_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/album/album_detail_screen.dart';
import '../../features/search/selfie_search_screen.dart';
import '../../features/photo/photo_viewer_screen.dart';
import '../../features/payments/payments_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../network/models.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SignupScreen(
            tempToken: extra?['tempToken'] as String? ?? '',
            email: extra?['email'] as String?,
            phone: extra?['phone'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/face-verification',
        builder: (context, state) => const FaceVerificationScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/album/:id',
        builder: (context, state) {
          final albumId = state.pathParameters['id']!;
          final sharingCode = state.extra as String?;
          return AlbumDetailScreen(
            id: albumId,
            sharingCode: sharingCode,
          );
        },
      ),
      GoRoute(
        path: '/selfie-search/:id',
        builder: (context, state) {
          final albumId = state.pathParameters['id']!;
          final sharingCode = state.extra as String?;
          return SelfieSearchScreen(
            albumId: albumId,
            sharingCode: sharingCode,
          );
        },
      ),
      GoRoute(
        path: '/photo-viewer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PhotoViewerScreen(
            photo: extra['photo'] as PhotoResponse,
            sharingCode: extra['sharingCode'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    // Redirect guard: protect routes from unauthenticated access (mandatory signup requirement)
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isGoingToSplash = state.matchedLocation == '/splash';
      final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!authState.isAuthenticated) {
        if (!isGoingToSplash && !isGoingToAuth) {
          return '/login'; // Force login gate
        }
      } else {
        if (isGoingToAuth) {
          return '/home'; // Redirect authenticated users away from auth gates
        }
      }
      return null;
    },
  );
});
