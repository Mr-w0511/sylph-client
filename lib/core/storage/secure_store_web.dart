import 'package:web/web.dart' as web;

abstract class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// web 实现：localStorage（同步 API 包成 Future）。
class _LocalStorageStore implements SecureStore {
  web.Storage get _ls => web.window.localStorage;

  @override
  Future<String?> read(String key) async => _ls.getItem(key);

  @override
  Future<void> write(String key, String value) async =>
      _ls.setItem(key, value);

  @override
  Future<void> delete(String key) async => _ls.removeItem(key);
}

SecureStore createSecureStore() => _LocalStorageStore();
