import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  AuthTokenManager._();
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

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_keyToken);
      _refreshToken = prefs.getString(_keyRefreshToken);
      final userJson = prefs.getString(_keyUser);
      if (userJson != null && userJson.isNotEmpty) {
        try {
          _currentUser = AuthUser.fromJson(
            jsonDecode(userJson) as Map<String, dynamic>,
          );
        } catch (e) {
          debugPrint('[AuthTokenManager] Failed to decode user: $e');
        }
      }
      _initialized = true;
      debugPrint(
        '[AuthTokenManager] Initialized. Authenticated: $isAuthenticated, User: ${_currentUser?.name} (${_currentUser?.role})',
      );
    } catch (e) {
      debugPrint('[AuthTokenManager] Init failed: $e');
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    if (refreshToken != null) {
      await prefs.setString(_keyRefreshToken, refreshToken);
    }
    if (user != null) {
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    }
  }

  Future<void> updateTokens({
    required String token,
    String? refreshToken,
  }) async {
    _accessToken = token;
    if (refreshToken != null) _refreshToken = refreshToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    if (refreshToken != null) {
      await prefs.setString(_keyRefreshToken, refreshToken);
    }
  }

  Future<void> updateCurrentUser(AuthUser user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUser);
  }
}
