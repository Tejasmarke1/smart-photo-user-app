import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/face_verification_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/create_group_screen.dart';
import '../../features/home/join_group_screen.dart';
import '../../features/album/album_detail_screen.dart';
import '../../features/album/upload_photos_screen.dart';
import '../../features/album/group_settings_screen.dart';
import '../../features/album/share_link_screen.dart';
import '../../features/search/selfie_search_screen.dart';
import '../../features/photo/photo_viewer_screen.dart';
import '../../features/payments/payments_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../network/models.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authProvider.notifier);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authNotifier.stream),
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
        path: '/create-group',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/join-group',
        builder: (context, state) => const JoinGroupScreen(),
      ),
      GoRoute(
        path: '/join/:sharing_code',
        builder: (context, state) {
          final sharingCode = state.pathParameters['sharing_code']!;
          return JoinGroupScreen(prefilledCode: sharingCode);
        },
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
        path: '/upload-photos/:id',
        builder: (context, state) {
          final albumId = state.pathParameters['id']!;
          final albumTitle = state.extra as String? ?? 'Group';
          return UploadPhotosScreen(albumId: albumId, albumTitle: albumTitle);
        },
      ),
      GoRoute(
        path: '/group-settings/:id',
        builder: (context, state) {
          final albumId = state.pathParameters['id']!;
          final albumDetail = state.extra as AlbumDetailResponse;
          return GroupSettingsScreen(albumId: albumId, albumDetail: albumDetail);
        },
      ),
      GoRoute(
        path: '/share-link/:id',
        builder: (context, state) {
          final albumId = state.pathParameters['id']!;
          final albumDetail = state.extra as AlbumDetailResponse;
          return ShareLinkScreen(albumId: albumId, albumDetail: albumDetail);
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
      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;

      final isGoingToSplash = state.matchedLocation == '/splash';
      final isGoingToAuth = state.matchedLocation == '/login' ||
                            state.matchedLocation == '/signup' ||
                            state.matchedLocation == '/face-verification';

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
