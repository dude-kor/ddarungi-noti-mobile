import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_guard.dart';
import '../../core/providers.dart';
import '../../core/push/push_token_provider.dart';

const String kAppVersion = '0.1.0'; // backend column is VARCHAR(16)

/// POST /api/v1/devices – registers (or refreshes) this install and its push token.
/// Uses Dio directly, not [ApiGuard], because the guard itself calls this on UNKNOWN_DEVICE.
class DeviceRegistrar {
  DeviceRegistrar(this._dio, this._push);

  final Dio _dio;
  final PushTokenProvider _push;

  Future<void> register() async {
    final pushToken = await _push.getToken();
    await _dio.post<void>('/api/v1/devices', data: {
      'pushToken': pushToken,
      'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID',
      'appVersion': kAppVersion,
    });
  }
}

final deviceRegistrarProvider = Provider<DeviceRegistrar>(
  (ref) => DeviceRegistrar(ref.watch(dioProvider), ref.watch(pushTokenProvider)),
);

final apiGuardProvider = Provider<ApiGuard>(
  (ref) => ApiGuard(() => ref.read(deviceRegistrarProvider).register()),
);
