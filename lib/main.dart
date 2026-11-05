import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/storage/app_prefs.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.kakaoJsKey.isEmpty) {
    debugPrint('KAKAO_JS_KEY is not set: pass --dart-define=KAKAO_JS_KEY=<JavaScript key>');
  }
  // kakao_map_plugin renders through a WebView and authenticates with the JavaScript key.
  AuthRepository.initialize(appKey: AppConfig.kakaoJsKey);

  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const DdarungiApp(),
  ));
}

class DdarungiApp extends ConsumerWidget {
  const DdarungiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read once: the first screen is decided at launch, later navigation is explicit.
    final onboarded = ref.read(appPrefsProvider).onboarded;
    return MaterialApp(
      title: '따릉이 알리미',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: onboarded ? Routes.home : Routes.onboarding,
      onGenerateRoute: onGenerateAppRoute,
    );
  }
}
