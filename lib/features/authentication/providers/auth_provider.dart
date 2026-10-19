import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:raigon_art/core/network/auth_token_manager.dart';
import 'package:raigon_art/features/authentication/models/auth_model.dart';
import 'package:raigon_art/features/authentication/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _init();
  }

  static const int _resendSeconds = 120;
  String? get userRole => _state.userRole;

  AuthModel _state = const AuthModel();
  Timer? _timer;

  AuthModel get state => _state;
  AuthStep get step => _state.step;
  bool get isLoading => _state.isLoading;
  int get secondsLeft => _state.secondsLeft;
  bool get canResend => _state.canResend;
  bool get isAuthenticated => _state.isAuthenticated;
  String? get errorMessage => _state.errorMessage;
  String? get successMessage => _state.successMessage;

  String get registeredPhone => AuthModel.registeredPhone;
  String? get devOtp => AuthService.lastDevOtp;
  String get timeText => _state.timeText;

  Future<void> _init() async {
    await AuthTokenManager.instance.init();
    if (AuthTokenManager.instance.isAuthenticated) {
      _update(
        _state.copyWith(
          isAuthenticated: true,
          userRole: AuthTokenManager.instance.currentUser?.role,
        ),
      );
    }
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    _stopTimer();
    _update(const AuthModel());
  }


  void _update(AuthModel newState) {
    _state = newState;
    notifyListeners();
  }

  Future<bool> _execute(
    Future<bool> Function() action,
    String failureMessage,
  ) async {
    if (isLoading) return false;

    _update(
      _state.copyWith(isLoading: true, clearError: true, clearSuccess: true),
    );

    try {
      final success = await action();

      _update(
        _state.copyWith(
          isLoading: false,
          errorMessage: success ? null : (AuthService.lastError ?? failureMessage),
          clearError: success,
        ),
      );

      return success;
    } catch (error) {
      debugPrint('[AuthProvider] Authentication operation failed: $error');

      _update(
        _state.copyWith(
          isLoading: false,
          errorMessage: AuthService.lastError ?? failureMessage,
        ),
      );

      return false;
    }
  }

  void goTo(AuthStep nextStep) {
    if (nextStep == AuthStep.signIn) {
      backToSignIn();
      return;
    }

    _update(
      _state.copyWith(step: nextStep, clearError: true, clearSuccess: true),
    );
  }

  void backToSignIn() {
    _stopTimer();

    _update(
      _state.copyWith(
        step: AuthStep.signIn,
        secondsLeft: 0,
        isLoading: false,
        clearError: true,
        clearSuccess: true,
      ),
    );
  }

  Future<bool> signIn(String identifier, String password) async {
    if (isLoading) return false;

    _update(
      _state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
        clearRole: true,
      ),
    );

    try {
      final role = await AuthService.signIn(identifier, password);
      final success = role != null;

      _update(
        _state.copyWith(
          isLoading: false,
          isAuthenticated: success,
          userRole: role,
          errorMessage: success
              ? null
              : (AuthService.lastError ??
                  'Invalid mobile number/email or password.'),
          clearError: success,
        ),
      );

      return success;
    } catch (error) {
      debugPrint('[AuthProvider] Sign-in failed: $error');

      _update(
        _state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          errorMessage: 'Unable to sign in. Please try again.',
        ),
      );

      return false;
    }
  }

  Future<bool> sendOtp(String phone) async {
    final success = await _execute(
      () => AuthService.sendWhatsAppOtp(phone),
      'Could not send OTP. Try again.',
    );

    if (!success) return false;

    _update(
      _state.copyWith(
        step: AuthStep.otp,
        secondsLeft: _resendSeconds,
        clearError: true,
      ),
    );

    _startTimer();
    return true;
  }

  Future<bool> resendOtp(String phone) async {
    if (!canResend || isLoading) return false;

    final success = await _execute(
      () => AuthService.sendWhatsAppOtp(phone),
      'Could not resend OTP. Try again.',
    );

    if (!success) return false;

    _update(_state.copyWith(secondsLeft: _resendSeconds, clearError: true));

    _startTimer();
    return true;
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    final success = await _execute(
      () => AuthService.verifyOtp(phone, otp),
      'Invalid OTP. Please try again.',
    );

    if (!success) return false;

    _stopTimer();

    _update(
      _state.copyWith(
        step: AuthStep.newPassword,
        secondsLeft: 0,
        clearError: true,
      ),
    );

    return true;
  }

  Future<bool> resetPassword(String phone, String newPassword) async {
    return _execute(
      () => AuthService.resetPassword(phone, newPassword),
      'Could not update password. Try again.',
    );
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state.secondsLeft <= 1) {
        timer.cancel();
        _timer = null;
        _update(_state.copyWith(secondsLeft: 0));
        return;
      }

      _update(_state.copyWith(secondsLeft: _state.secondsLeft - 1));
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
