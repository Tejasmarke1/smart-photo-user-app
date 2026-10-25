import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/config/app_config.dart';
import 'package:user_app/core/network/api_client.dart';

/// Captures the URL of the first request instead of sending it.
Future<Uri> _requestedUri(ApiClient Function(Dio dio) build) async {
  late Uri uri;
  final dio = Dio()
    ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      uri = options.uri;
      handler.reject(DioException(requestOptions: options));
    }));
  await expectLater(build(dio).getCurrentUser(), throwsA(isA<DioException>()));
  return uri;
}

void main() {
  // Run with --dart-define=API_BASE_URL=... to check the override.
  const defined = String.fromEnvironment('API_BASE_URL');

  test('AppConfig.apiBaseUrl comes from API_BASE_URL or the emulator default', () {
    final expected = defined.isEmpty ? 'http://10.0.2.2:8000/api/v1' : defined;
    expect(AppConfig.apiBaseUrl, expected.replaceFirst(RegExp(r'/$'), ''));
  });

  test('ApiClient sends requests to AppConfig.apiBaseUrl', () async {
    final uri = await _requestedUri((dio) => ApiClient(dio));
    expect(uri.toString(), '${AppConfig.apiBaseUrl}/auth/me');
  });

  test('an explicit baseUrl still overrides the config', () async {
    final uri = await _requestedUri(
        (dio) => ApiClient(dio, baseUrl: 'https://api.example.com/api/v1'));
    expect(uri.toString(), 'https://api.example.com/api/v1/auth/me');
  });
}
