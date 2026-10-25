# user_app

A new Flutter project.

## Backend URL

The API base URL is set at build time with `--dart-define=API_BASE_URL` (see `lib/core/config/app_config.dart`). Include the `/api/v1` prefix.

| Target | Command |
|---|---|
| Android emulator, backend on this PC | `flutter run` (defaults to `http://10.0.2.2:8000/api/v1`) |
| Physical phone on the same Wi-Fi | `flutter run --dart-define=API_BASE_URL=http://<PC LAN IP>:8000/api/v1` |
| Release build | `flutter build apk --dart-define=API_BASE_URL=https://api.example.com/api/v1` |

For a phone, start the backend with `--host 0.0.0.0` so it listens on your LAN IP (find it with `ipconfig`).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
