import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/lumina_theme.dart';
import 'core/router/router.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Note: Firebase.initializeApp() is simulated if GoogleServices configuration files are missing.
  // We wrap this inside a try-catch to allow development builds without hard blockers.
  try {
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Fail silently in development
  }

  runApp(
    const ProviderScope(
      child: LuminaApp(),
    ),
  );
}

class LuminaApp extends ConsumerWidget {
  const LuminaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Initialize Push Notification listeners
    ref.read(notificationServiceProvider).initialize();

    return MaterialApp.router(
      title: 'Lumina',
      debugShowCheckedModeBanner: false,
      theme: LuminaTheme.lightTheme,
      darkTheme: LuminaTheme.darkTheme,
      themeMode: ThemeMode.dark, // Obsidian design language by default
      routerConfig: router,
    );
  }
}
