/// Build-time configuration, injected with `--dart-define`:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=KAKAO_JS_KEY=xxxx
abstract final class AppConfig {
  /// Backend base URL. 10.0.2.2 is the host machine as seen from the Android emulator;
  /// use http://localhost:8080 for the iOS simulator.
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8080');

  /// Kakao Developers "JavaScript key" (kakao_map_plugin renders through a WebView).
  static const String kakaoJsKey = String.fromEnvironment('KAKAO_JS_KEY');

  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
