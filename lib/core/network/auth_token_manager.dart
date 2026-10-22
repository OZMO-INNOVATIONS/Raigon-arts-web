import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;

  bool get isAdmin => role.toLowerCase() == 'admin';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    role: json['role'] as String? ?? 'staff',
  );
}

class AuthTokenManager {
  AuthTokenManager._() {
    _restoreFromLocalStorage();
  }
  static final AuthTokenManager instance = AuthTokenManager._();

  static const String _keyToken = 'raigon_auth_token';
  static const String _keyRefreshToken = 'raigon_auth_refresh_token';
  static const String _keyUser = 'raigon_auth_user';

  String? _accessToken;
  String? _refreshToken;
  AuthUser? _currentUser;
  bool _initialized = false;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated =>
      _accessToken != null && _accessToken!.trim().isNotEmpty;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isInitialized => _initialized;

  void _restoreFromLocalStorage() {
    if (!kIsWeb) return;
    try {
      final token = web.window.localStorage.getItem(_keyToken);
      final refresh = web.window.localStorage.getItem(_keyRefreshToken);
      final userJson = web.window.localStorage.getItem(_keyUser);

      if (token != null && token.trim().isNotEmpty) {
        _accessToken = token.trim();
        if (refresh != null && refresh.trim().isNotEmpty) {
          _refreshToken = refresh.trim();
        }
        if (userJson != null && userJson.trim().isNotEmpty) {
          try {
            _currentUser = AuthUser.fromJson(
              jsonDecode(userJson) as Map<String, dynamic>,
            );
          } catch (_) {}
        }
        _initialized = true;
        debugPrint(
          '[AuthTokenManager] Synchronously restored session from localStorage. User: ${_currentUser?.name} (${_currentUser?.role})',
        );
      }
    } catch (e) {
      debugPrint('[AuthTokenManager] localStorage restore note: $e');
    }
  }

  Future<void> init() async {
    _restoreFromLocalStorage();

    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken ??= prefs.getString(_keyToken);
      _refreshToken ??= prefs.getString(_keyRefreshToken);
      final userJson = prefs.getString(_keyUser);
      if (_currentUser == null && userJson != null && userJson.isNotEmpty) {
        try {
          _currentUser = AuthUser.fromJson(
            jsonDecode(userJson) as Map<String, dynamic>,
          );
        } catch (e) {
          debugPrint('[AuthTokenManager] Failed to decode user from prefs: $e');
        }
      }
      _initialized = true;
      debugPrint(
        '[AuthTokenManager] Initialized. Authenticated: $isAuthenticated, User: ${_currentUser?.name} (${_currentUser?.role})',
      );
    } catch (e) {
      debugPrint('[AuthTokenManager] Prefs init failed: $e');
    }
  }

  Future<void> saveSession({
    required String token,
    String? refreshToken,
    AuthUser? user,
  }) async {
    _accessToken = token;
    if (refreshToken != null) _refreshToken = refreshToken;
    if (user != null) _currentUser = user;
    _initialized = true;

    if (kIsWeb) {
      try {
        web.window.localStorage.setItem(_keyToken, token);
        if (refreshToken != null) {
          web.window.localStorage.setItem(_keyRefreshToken, refreshToken);
        }
        if (user != null) {
          web.window.localStorage.setItem(_keyUser, jsonEncode(user.toJson()));
        }
      } catch (e) {
        debugPrint('[AuthTokenManager] localStorage save error: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      if (refreshToken != null) {
        await prefs.setString(_keyRefreshToken, refreshToken);
      }
      if (user != null) {
        await prefs.setString(_keyUser, jsonEncode(user.toJson()));
      }
    } catch (e) {
      debugPrint('[AuthTokenManager] SharedPreferences save error: $e');
    }
  }

  Future<void> updateTokens({
    required String token,
    String? refreshToken,
  }) async {
    _accessToken = token;
    if (refreshToken != null) _refreshToken = refreshToken;

    if (kIsWeb) {
      try {
        web.window.localStorage.setItem(_keyToken, token);
        if (refreshToken != null) {
          web.window.localStorage.setItem(_keyRefreshToken, refreshToken);
        }
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      if (refreshToken != null) {
        await prefs.setString(_keyRefreshToken, refreshToken);
      }
    } catch (_) {}
  }

  Future<void> updateCurrentUser(AuthUser user) async {
    _currentUser = user;

    if (kIsWeb) {
      try {
        web.window.localStorage.setItem(_keyUser, jsonEncode(user.toJson()));
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    _initialized = false;

    if (kIsWeb) {
      try {
        web.window.localStorage.removeItem(_keyToken);
        web.window.localStorage.removeItem(_keyRefreshToken);
        web.window.localStorage.removeItem(_keyUser);
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyUser);
    } catch (_) {}
  }
}
