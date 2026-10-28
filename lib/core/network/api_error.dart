import 'package:dio/dio.dart';

/// A failed API call, reduced to what screens need: the HTTP status, the machine-readable
/// `code` when the server sends one (`detail: {code, message, ...}`), and a message safe to show.
class ApiError {
  final int? statusCode;
  final String? code;
  final String message;
  final Map<String, dynamic> detail;

  const ApiError({this.statusCode, this.code, required this.message, this.detail = const {}});

  /// The account owns albums and the server wants an explicit confirmation to delete them.
  bool get ownsAlbums => statusCode == 409 && code == 'OWNS_ALBUMS';

  @override
  String toString() => 'ApiError($statusCode, $code, $message)';
}

ApiError parseApiError(Object error, {String fallback = 'Something went wrong. Please try again.'}) {
  if (error is! DioException) {
    return ApiError(message: fallback);
  }
  final response = error.response;
  if (response == null) {
    return const ApiError(message: 'Could not reach the server. Check your connection and try again.');
  }
  final data = response.data;
  final detail = data is Map ? data['detail'] : null;
  if (detail is Map) {
    final map = Map<String, dynamic>.from(detail);
    return ApiError(
      statusCode: response.statusCode,
      code: map['code'] as String?,
      message: (map['message'] as String?) ?? fallback,
      detail: map,
    );
  }
  if (detail is String && detail.isNotEmpty) {
    return ApiError(statusCode: response.statusCode, message: detail);
  }
  return ApiError(statusCode: response.statusCode, message: fallback);
}
