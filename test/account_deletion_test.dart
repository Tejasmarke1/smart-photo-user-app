import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/api_error.dart';

const _faceDataBody = {
  'selfie_objects_deleted': 2,
  'persons_removed': 1,
  'faces_removed': 3,
  'face_crops_deleted': 3,
  'search_history_deleted': 4,
  'consents_revoked': 1,
  'deleted_at': '2026-10-28T12:00:00',
};

/// A Dio whose "server" answers every request with [status]/[data] and records what was sent.
({Dio dio, List<RequestOptions> sent}) _fakeServer(int status, Object data) {
  final sent = <RequestOptions>[];
  final dio = Dio()
    ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      sent.add(options);
      final response = Response(requestOptions: options, statusCode: status, data: data);
      if (status >= 400) {
        handler.reject(DioException(
            requestOptions: options, response: response, type: DioExceptionType.badResponse));
      } else {
        handler.resolve(response);
      }
    }));
  return (dio: dio, sent: sent);
}

void main() {
  _signupWithoutStoredSelfie();
  group('face data deletion calls the API', () {
    test('DELETE /auth/me/face-data with the confirmation, and parses the result', () async {
      final server = _fakeServer(200, _faceDataBody);
      final result = await ApiClient(server.dio, baseUrl: 'http://api.test/v1').deleteFaceData({'confirm': 'DELETE'});

      expect(server.sent, hasLength(1));
      expect(server.sent.single.method, 'DELETE');
      expect(server.sent.single.uri.toString(), 'http://api.test/v1/auth/me/face-data');
      expect(server.sent.single.data, {'confirm': 'DELETE'});
      expect(result.selfieObjectsDeleted, 2);
      expect(result.personsRemoved, 1);
      expect(result.facesRemoved, 3);
      expect(result.searchHistoryDeleted, 4);
    });

    test('a server failure surfaces as an error, never as success', () async {
      final server = _fakeServer(502, {'detail': 'Could not delete stored images. Nothing else was changed; please try again.'});
      await expectLater(
        ApiClient(server.dio, baseUrl: 'http://api.test').deleteFaceData({'confirm': 'DELETE'}),
        throwsA(isA<DioException>()),
      );
    });

    test('the screen no longer simulates the call', () {
      final source = File('lib/features/settings/face_data_management_screen.dart').readAsStringSync();
      expect(source.contains('Future.delayed'), isFalse);
      expect(source.contains('deleteFaceData'), isTrue);
    });
  });

  group('account deletion calls the API', () {
    test('DELETE /auth/me with the confirmation and album choice', () async {
      final server = _fakeServer(200, {
        ..._faceDataBody,
        'albums_deleted': 1,
        'photos_deleted': 10,
        'album_objects_deleted': 30,
        'subscriptions_cancelled': 1,
        'sessions_revoked': 2,
      });
      final result = await ApiClient(server.dio, baseUrl: 'http://api.test').deleteAccount(
        {'confirm': 'DELETE', 'delete_owned_albums': true},
      );

      expect(server.sent.single.method, 'DELETE');
      expect(server.sent.single.uri.path, '/auth/me');
      expect(server.sent.single.data, {'confirm': 'DELETE', 'delete_owned_albums': true});
      expect(result.albumsDeleted, 1);
      expect(result.photosDeleted, 10);
      expect(result.sessionsRevoked, 2);
    });
  });

  group('parseApiError', () {
    DioException failure(int status, Object data) {
      final options = RequestOptions(path: '/auth/me');
      return DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: status, data: data),
          type: DioExceptionType.badResponse);
    }

    test('recognises an account that owns albums', () {
      final error = parseApiError(failure(409, {
        'detail': {'code': 'OWNS_ALBUMS', 'message': 'This account owns albums.', 'album_count': 3}
      }));
      expect(error.ownsAlbums, isTrue);
      expect(error.detail['album_count'], 3);
      expect(error.message, 'This account owns albums.');
    });

    test('other 409s are not mistaken for it', () {
      expect(parseApiError(failure(409, {'detail': 'conflict'})).ownsAlbums, isFalse);
    });

    test('plain string details are shown as the message', () {
      final error = parseApiError(failure(502, {'detail': 'Could not delete stored images.'}));
      expect(error.statusCode, 502);
      expect(error.message, 'Could not delete stored images.');
    });

    test('unreadable responses and non-HTTP failures use the fallback', () {
      expect(parseApiError(failure(500, 'oops'), fallback: 'try again').message, 'try again');
      expect(parseApiError(StateError('boom'), fallback: 'try again').message, 'try again');
    });

    test('no response means the server was unreachable', () {
      final error = parseApiError(DioException(
          requestOptions: RequestOptions(path: '/auth/me'), type: DioExceptionType.connectionError));
      expect(error.message, contains('Could not reach the server'));
    });
  });
}

// Retention (P3-4): the server stores no signup selfie by default, so signup must work without a URL.
void _signupWithoutStoredSelfie() {
  test('signup no longer requires the server to keep the selfie', () {
    final source = File('lib/features/auth/signup_screen.dart').readAsStringSync();
    expect(source.contains('Failed to retrieve profile image URL'), isFalse);
  });
}
