import 'web_storage_stub.dart'
    if (dart.library.js_interop) 'web_storage_web.dart';

abstract class WebStorage {
  static String? getItem(String key) => getWebStorageItem(key);
  static void setItem(String key, String value) => setWebStorageItem(key, value);
  static void removeItem(String key) => removeWebStorageItem(key);
}

