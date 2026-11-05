import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';

/// Local-only state: onboarding flag, recent searches, favourite card order (SCR-06 keeps the order
/// on the device, the backend only stores the bookmark itself).
class AppPrefs {
  AppPrefs(this._p);

  final SharedPreferences _p;

  bool get onboarded => _p.getBool('onboarded') ?? false;

  Future<void> completeOnboarding({required bool marketingOptIn}) async {
    await _p.setBool('marketing_opt_in', marketingOptIn);
    await _p.setBool('onboarded', true);
  }

  List<String> get recentSearches => _p.getStringList('recent_searches') ?? const [];

  Future<void> addRecentSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final list = [q, ...recentSearches.where((e) => e != q)].take(8).toList();
    await _p.setStringList('recent_searches', list);
  }

  Future<void> clearRecentSearches() => _p.remove('recent_searches');

  List<String> get favoriteOrder => _p.getStringList('favorite_order') ?? const [];

  Future<void> setFavoriteOrder(List<String> stationIds) => _p.setStringList('favorite_order', stationIds);
}

final appPrefsProvider = Provider<AppPrefs>((ref) => AppPrefs(ref.watch(sharedPreferencesProvider)));
