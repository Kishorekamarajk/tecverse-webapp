import 'package:flutter/foundation.dart';
import '../../../core/networking/api_exceptions.dart';
import '../../../core/storage/session_manager.dart';
import '../domain/auth_repository.dart';
import '../domain/authenticated_user.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository repository;
  final SessionManager sessionManager;

  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthController({
    required this.repository,
    required this.sessionManager,
  });

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => sessionManager.isAuthenticated && _currentUser != null;

  /// Restores session on app startup
  Future<bool> checkSession() async {
    _setLoading(true);
    final hasSession = await sessionManager.checkExistingSession();
    if (hasSession && sessionManager.accessToken != null) {
      try {
        _currentUser = await repository.getProfile(token: sessionManager.accessToken!);
        _errorMessage = null;
        _setLoading(false);
        return true;
      } catch (e) {
        if (e is UnauthorizedException) {
          await handleSessionExpired();
        } else {
          // Retain the saved credentials for a retry after temporary outages.
          _currentUser = null;
        }
      }
    }
    _setLoading(false);
    return false;
  }

  /// Authenticate registered website user
  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final authResult = await repository.login(
        identifier: identifier,
        password: password,
      );
      _currentUser = authResult.profile;
      await sessionManager.setSession(
        accessToken: authResult.tokens.accessToken,
        refreshToken: authResult.tokens.refreshToken,
      );
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  /// Request reset password OTP to registered email
  Future<int?> requestPasswordReset(String identifier) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final retryAfterSeconds = await repository.requestPasswordReset(identifier: identifier);
      _setLoading(false);
      return retryAfterSeconds;
    } on TooManyRequestsException catch (e) {
      _errorMessage = null;
      _setLoading(false);
      return e.retryAfterSeconds;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return null;
    } catch (e) {
      _errorMessage = 'Unable to send OTP. Please check your registered email.';
      _setLoading(false);
      return null;
    }
  }

  /// Verify entered 6-digit OTP
  Future<bool> verifyResetOtp({
    required String identifier,
    required String otp,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final valid = await repository.verifyResetOtp(identifier: identifier, otp: otp);
      _setLoading(false);
      return valid;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Invalid OTP. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  /// Reset password and update in database
  Future<bool> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
    String? confirmPassword,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await repository.verifyResetOtpAndSetPassword(
        identifier: identifier,
        otp: otp,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to reset password. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  /// Update user's technology interests
  Future<void> updateInterests(List<String> interests) async {
    final token = sessionManager.accessToken;
    if (token == null) return;
    try {
      final updated = await repository.updateInterests(token: token, interests: interests);
      _currentUser = updated;
      notifyListeners();
    } catch (_) {}
  }

  /// Sign out attendee and wipe tokens
  Future<void> logout() async {
    _setLoading(true);
    final token = sessionManager.accessToken;
    try {
      await repository.logout(token: token);
    } catch (_) {}
    await sessionManager.terminateSession();
    _currentUser = null;
    _errorMessage = null;
    _setLoading(false);
  }

  /// Clear local identity and credentials after the backend rejects the session.
  Future<void> handleSessionExpired() async {
    await sessionManager.handleSessionExpired();
    _currentUser = null;
    _errorMessage = 'Your session has expired. Please sign in again.';
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
