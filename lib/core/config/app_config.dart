/// Build-time configuration, set with `--dart-define`.
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
///
/// The default targets a backend on the host machine from the Android
/// emulator (10.0.2.2 is the emulator's alias for the host's localhost).
/// Physical devices, iOS simulators and release builds must set API_BASE_URL.
class AppConfig {
  AppConfig._();

  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Backend API root including the version prefix, without a trailing slash.
  static String get apiBaseUrl => _apiBaseUrl.endsWith('/')
      ? _apiBaseUrl.substring(0, _apiBaseUrl.length - 1)
      : _apiBaseUrl;
}
