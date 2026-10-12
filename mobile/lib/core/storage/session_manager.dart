import 'package:flutter/foundation.dart';
import 'token_storage.dart';

enum SessionStatus {
  initial,
  authenticated,
  unauthenticated,
  expired,
}

/// Central Session Manager managing user lifecycle and auth persistence.
class SessionManager extends ChangeNotifier {
  final TokenStorage storage;
  SessionStatus _status = SessionStatus.initial;
  String? _accessToken;

  SessionManager({required this.storage});

  SessionStatus get status => _status;
  bool get isAuthenticated => _status == SessionStatus.authenticated;
  String? get accessToken => _accessToken;

  /// Check existing session on app startup (Splash screen)
  Future<bool> checkExistingSession() async {
    final token = await storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      _accessToken = token;
      _status = SessionStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _status = SessionStatus.unauthenticated;
      _accessToken = null;
      notifyListeners();
      return false;
    }
  }

  /// Establish session after successful login
  Future<void> setSession({required String accessToken, String? refreshToken}) async {
    _accessToken = accessToken;
    _status = SessionStatus.authenticated;
    await storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    notifyListeners();
  }

  /// Handle session expiration or 401 unauthorized
  Future<void> handleSessionExpired() async {
    _status = SessionStatus.expired;
    _accessToken = null;
    await storage.clearAll();
    notifyListeners();
  }

  /// Clean user logout
  Future<void> terminateSession() async {
    _status = SessionStatus.unauthenticated;
    _accessToken = null;
    await storage.clearAll();
    notifyListeners();
  }
}
