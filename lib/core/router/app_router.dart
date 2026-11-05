import 'package:flutter/material.dart';

import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/permission_screen.dart';
import '../../features/schedule/presentation/alert_setup_screen.dart';
import '../../features/station/presentation/home_map_screen.dart';
import '../../features/station/presentation/search_screen.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const permission = '/permission-modal';
  static const home = '/home';
  static const search = '/search';
  static const alertSetup = '/station-alert-setup';
  static const favorites = '/favorites';
}

Route<dynamic>? onGenerateAppRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.onboarding:
      return _page(settings, const OnboardingScreen());
    case Routes.permission:
      return _page(settings, const PermissionScreen(), fullscreenDialog: true);
    case Routes.home:
      return _page(settings, const HomeMapScreen());
    case Routes.search:
      return _page(settings, const SearchScreen());
    case Routes.alertSetup:
      return _page(settings, AlertSetupScreen(args: settings.arguments! as AlertSetupArgs), fullscreenDialog: true);
    case Routes.favorites:
      return _page(settings, const FavoritesScreen());
  }
  return null;
}

MaterialPageRoute<dynamic> _page(RouteSettings settings, Widget child, {bool fullscreenDialog = false}) =>
    MaterialPageRoute<dynamic>(settings: settings, fullscreenDialog: fullscreenDialog, builder: (_) => child);
