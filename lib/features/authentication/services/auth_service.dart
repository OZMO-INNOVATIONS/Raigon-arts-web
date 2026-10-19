import 'package:flutter/foundation.dart';
import 'package:raigon_art/core/network/api_client.dart';
import 'package:raigon_art/core/network/api_constants.dart';
import 'package:raigon_art/core/network/api_exception.dart';
import 'package:raigon_art/core/network/auth_token_manager.dart';

class AuthService {
  AuthService._();

  static final ApiClient _api = ApiClient();
  static String? _lastResetToken;
  static String? _lastDevOtp;
  static String? _lastError;

  static String? get lastDevOtp => _lastDevOtp;
  static String? get lastError => _lastError;
  static AuthUser? get currentUser => AuthTokenManager.instance.currentUser;
  static bool get isAuthenticated => AuthTokenManager.instance.isAuthenticated;
  static bool get isAdmin => AuthTokenManager.instance.isAdmin;

  static Future<String?> signIn(String identifier, String password) async {
    _lastError = null;
    try {
      final response = await _api.post(
        ApiConstants.login,
        body: {
          'identifier': identifier.trim(),
          'password': password,
        },
        requiresAuth: false,
      );

      final token = response['token'] as String?;
      final refreshToken = response['refreshToken'] as String?;
      final userData = response['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        _lastError = 'Server returned an invalid authentication response.';
        return null;
      }

      final user = AuthUser.fromJson(userData);
      await AuthTokenManager.instance.saveSession(
        token: token,
        refreshToken: refreshToken,
        user: user,
      );

      debugPrint('[AuthService] Login successful. User: ${user.name}, Role: ${user.role}');
      return user.role;
    } on ApiException catch (e) {
      _lastError = e.userFriendlyMessage;
      debugPrint('[AuthService] Login API error: ${e.userFriendlyMessage}');
      return null;
    } catch (e) {
      _lastError = 'Connection failure: $e';
      debugPrint('[AuthService] Login unexpected error: $e');
      return null;
    }
  }

  static Future<bool> sendWhatsAppOtp(String phone) async {
    _lastError = null;
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
      final response = await _api.post(
        ApiConstants.forgotPassword,
        body: {'phone': cleanPhone},
        requiresAuth: false,
      );

      if (response is Map<String, dynamic>) {
        _lastDevOtp = response['devOtp'] as String?;
        if (_lastDevOtp != null) {
          debugPrint('[AuthService] Dev OTP received: $_lastDevOtp');
        }
      }

      return true;
    } on ApiException catch (e) {
      _lastError = e.userFriendlyMessage;
      debugPrint('[AuthService] sendWhatsAppOtp API error: ${e.userFriendlyMessage}');
      return false;
    } catch (e) {
      _lastError = 'Connection failure: $e';
      debugPrint('[AuthService] sendWhatsAppOtp error: $e');
      return false;
    }
  }

  static Future<bool> verifyOtp(String phone, String otp) async {
    _lastError = null;
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
      final response = await _api.post(
        ApiConstants.verifyOtp,
        body: {
          'phone': cleanPhone,
          'otp': otp.trim(),
        },
        requiresAuth: false,
      );

      if (response is Map<String, dynamic>) {
        _lastResetToken = response['resetToken'] as String?;
        return _lastResetToken != null && _lastResetToken!.isNotEmpty;
      }

      _lastError = 'Verification failed. Please try again.';
      return false;
    } on ApiException catch (e) {
      _lastError = e.userFriendlyMessage;
      debugPrint('[AuthService] verifyOtp API error: ${e.userFriendlyMessage}');
      return false;
    } catch (e) {
      _lastError = 'Connection failure: $e';
      debugPrint('[AuthService] verifyOtp error: $e');
      return false;
    }
  }

  static Future<bool> resetPassword(String phone, String newPassword) async {
    _lastError = null;
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
      await _api.post(
        ApiConstants.resetPassword,
        body: {
          'phone': cleanPhone,
          'resetToken': _lastResetToken ?? '',
          'newPassword': newPassword,
        },
        requiresAuth: false,
      );

      _lastResetToken = null;
      return true;
    } on ApiException catch (e) {
      _lastError = e.userFriendlyMessage;
      debugPrint('[AuthService] resetPassword API error: ${e.userFriendlyMessage}');
      return false;
    } catch (e) {
      _lastError = 'Connection failure: $e';
      debugPrint('[AuthService] resetPassword error: $e');
      return false;
    }
  }

  static Future<AuthUser?> fetchProfile() async {
    try {
      final response = await _api.get(ApiConstants.me);
      if (response is Map<String, dynamic>) {
        final user = AuthUser.fromJson(response);
        await AuthTokenManager.instance.updateCurrentUser(user);
        return user;
      }
      return null;
    } catch (e) {
      debugPrint('[AuthService] fetchProfile error: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await AuthTokenManager.instance.clear();
    _lastResetToken = null;
    _lastDevOtp = null;
    _lastError = null;
  }
}
