import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'api_failure.dart';

const String kDeviceTokenHeader = 'X-Device-Token';

/// Dio configured for the Ddareungi backend: injects `X-Device-Token` into every request and turns
/// failures into [ApiFailure] (available as `DioException.error`).
Dio buildDio({required String Function() deviceToken, String? baseUrl}) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    headers: {'Accept': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      options.headers[kDeviceTokenHeader] = deviceToken();
      handler.next(options);
    },
    onError: (error, handler) {
      handler.next(error.copyWith(error: ApiFailure.from(error)));
    },
  ));

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestHeader: false, responseHeader: false));
  }
  return dio;
}
