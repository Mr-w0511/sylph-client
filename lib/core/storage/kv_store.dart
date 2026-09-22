import 'package:shared_preferences/shared_preferences.dart';

/// 轻量 KV：设备 id、主题/语言偏好、同步游标等非敏感配置。
/// Token 等敏感材料走 [SecureStore]（web 下回退 localStorage）。
class KvStore {
  static const _kDeviceId = 'device_id';
  static const kLocale = 'settings.locale';
  static const kThemeMode = 'settings.themeMode';
  static const kThemeColor = 'settings.themeColor';
  static const kWallpaper = 'settings.wallpaper';
  static const kWallpaperOverlay = 'settings.wallpaperOverlay';
  static const kSyncCursor = 'sync.cursor';

  final SharedPreferences _prefs;

  KvStore(this._prefs);

  static Future<KvStore> create() async =>
      KvStore(await SharedPreferences.getInstance());

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<void> remove(String key) => _prefs.remove(key);

  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  double? getDouble(String key) => _prefs.getDouble(key);
  Future<void> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  /// 稳定的设备标识（后端登录 device.deviceId 要求）。
  Future<String> ensureDeviceId(String Function() uuid) async {
    var id = _prefs.getString(_kDeviceId);
    if (id == null || id.isEmpty) {
      id = uuid();
      await _prefs.setString(_kDeviceId, id);
    }
    return id;
  }

  String? get deviceId => _prefs.getString(_kDeviceId);
}
