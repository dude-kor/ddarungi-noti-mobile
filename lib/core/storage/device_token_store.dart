import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// The anonymous device identity sent as `X-Device-Token` (backend limit: 64 chars; a UUID is 36).
/// Generated once on first launch and kept for the lifetime of the install.
class DeviceTokenStore {
  DeviceTokenStore(this._prefs);

  static const _key = 'device_token';
  final SharedPreferences _prefs;

  String get token {
    final existing = _prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = const Uuid().v4();
    _prefs.setString(_key, created);
    return created;
  }
}
