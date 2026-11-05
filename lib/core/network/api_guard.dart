import 'package:dio/dio.dart';

import 'api_failure.dart';

/// Runs a backend call and normalises errors to [ApiFailure]. When the backend answers
/// 401 UNKNOWN_DEVICE (token not registered, e.g. after a reinstall or a DB reset) it registers the
/// device once and retries the call.
class ApiGuard {
  ApiGuard(this._reregister);

  final Future<void> Function() _reregister;

  Future<T> call<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on DioException catch (e) {
      final failure = _failure(e);
      if (!failure.isUnknownDevice) throw failure;
      await _reregister();
      try {
        return await op();
      } on DioException catch (e2) {
        throw _failure(e2);
      }
    }
  }

  static ApiFailure _failure(DioException e) =>
      e.error is ApiFailure ? e.error! as ApiFailure : ApiFailure.from(e);
}

/// User-facing (Korean) message for any error thrown by a repository.
String failureMessage(Object error) {
  if (error is ApiFailure) {
    if (error.isNetwork) return '네트워크 연결을 확인해 주세요';
    switch (error.code) {
      case 'FAVORITE_LIMIT_REACHED':
        return '즐겨찾기는 최대 5개까지 추가할 수 있어요';
      case 'STATION_NOT_FOUND':
        return '존재하지 않는 대여소예요';
      case 'SCHEDULE_NOT_FOUND':
        return '알림 설정을 찾을 수 없어요';
      case 'VALIDATION_FAILED':
      case 'BAD_REQUEST':
        return '입력값을 확인해 주세요';
    }
    return error.message.isNotEmpty ? error.message : '요청에 실패했어요';
  }
  return '알 수 없는 오류가 발생했어요';
}
