import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'network/dio_client.dart';
import 'storage/device_token_store.dart';

/// Overridden in main() with the instance obtained before runApp.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden in main()'),
);

final deviceTokenStoreProvider =
    Provider<DeviceTokenStore>((ref) => DeviceTokenStore(ref.watch(sharedPreferencesProvider)));

final deviceTokenProvider = Provider<String>((ref) => ref.watch(deviceTokenStoreProvider).token);

final dioProvider = Provider<Dio>((ref) {
  final token = ref.watch(deviceTokenProvider);
  return buildDio(deviceToken: () => token);
});
