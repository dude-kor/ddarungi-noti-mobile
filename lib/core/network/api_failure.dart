import 'package:dio/dio.dart';

/// Normalised error for every backend call. The backend answers errors as `{"code": "...", "message": "..."}`
/// (e.g. UNKNOWN_DEVICE, MISSING_DEVICE_TOKEN, FAVORITE_LIMIT_REACHED, STATION_NOT_FOUND, VALIDATION_FAILED).
class ApiFailure implements Exception {
  const ApiFailure({this.statusCode, required this.code, required this.message});

  final int? statusCode;
  final String code;
  final String message;

  /// The device token is not registered (yet): call POST /api/v1/devices, then retry.
  bool get isUnknownDevice => statusCode == 401 && code == 'UNKNOWN_DEVICE';

  /// No response at all (offline, timeout, DNS ...).
  bool get isNetwork => statusCode == null;

  factory ApiFailure.from(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['code'] is String) {
      return ApiFailure(
        statusCode: e.response?.statusCode,
        code: data['code'] as String,
        message: (data['message'] as String?) ?? '',
      );
    }
    final status = e.response?.statusCode;
    return ApiFailure(
      statusCode: status,
      code: status == null ? 'NETWORK_ERROR' : 'HTTP_$status',
      message: e.message ?? 'Request failed',
    );
  }

  @override
  String toString() => 'ApiFailure($statusCode $code: $message)';
}
