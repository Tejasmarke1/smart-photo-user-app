import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/network/api_client.dart';

/// Captures the headers of the first request instead of sending it.
Future<Map<String, dynamic>> _sentHeaders(String? signupToken) async {
  late Map<String, dynamic> headers;
  final dio = Dio()
    ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      headers = options.headers;
      handler.reject(DioException(requestOptions: options));
    }));
  final file = File('${Directory.systemTemp.path}/selfie_test.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF]);
  await expectLater(
    ApiClient(dio).uploadProfilePicture(file, signupToken: signupToken),
    throwsA(isA<DioException>()),
  );
  return headers;
}

void main() {
  test('signup selfie upload sends the signup token', () async {
    expect((await _sentHeaders('temp-token-123'))['X-Signup-Token'], 'temp-token-123');
  });

  test('signed-in upload sends no signup token header', () async {
    expect((await _sentHeaders(null)).containsKey('X-Signup-Token'), isFalse);
  });
}
