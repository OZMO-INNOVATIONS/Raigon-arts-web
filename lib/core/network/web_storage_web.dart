import 'package:web/web.dart' as web;

String? getWebStorageItem(String key) {
  try {
    return web.window.localStorage.getItem(key);
  } catch (_) {
    return null;
  }
}

void setWebStorageItem(String key, String value) {
  try {
    web.window.localStorage.setItem(key, value);
  } catch (_) {}
}

void removeWebStorageItem(String key) {
  try {
    web.window.localStorage.removeItem(key);
  } catch (_) {}
}

