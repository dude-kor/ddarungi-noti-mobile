import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// Source of the FCM registration token sent to POST /api/v1/devices.
abstract class PushTokenProvider {
  Future<String> getToken();
}

/// Development stand-in so the app can register without Firebase. Pushes will NOT arrive with it.
/// TODO(fcm): add firebase_core + firebase_messaging, configure google-services.json /
/// GoogleService-Info.plist, and return `FirebaseMessaging.instance.getToken()` here.
class PlaceholderPushTokenProvider implements PushTokenProvider {
  PlaceholderPushTokenProvider(this._deviceToken);

  final String _deviceToken;

  @override
  Future<String> getToken() async => 'dev-$_deviceToken';
}

final pushTokenProvider =
    Provider<PushTokenProvider>((ref) => PlaceholderPushTokenProvider(ref.watch(deviceTokenProvider)));
