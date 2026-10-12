import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract contract for secure token and credential persistence.
abstract class TokenStorage {
  Future<void> saveTokens({required String accessToken, String? refreshToken});
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveUserCache(Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUserCache();
  Future<void> clearAll();
}

/// Stores authentication tokens and the small user cache in platform secure storage.
class SecureTokenStorageImpl implements TokenStorage {
  static const String _keyAccessToken = 'tecverse_access_token';
  static const String _keyRefreshToken = 'tecverse_refresh_token';
  static const String _keyUserData = 'tecverse_user_profile_cache';

  final FlutterSecureStorage _secureStorage;

  SecureTokenStorageImpl({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
              mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
              wOptions: WindowsOptions(useBackwardCompatibility: true),
            );

  /// Remove values written by older versions that stored credentials in
  /// SharedPreferences. Never read or restore these values.
  Future<void> _removeLegacyPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserData);
  }

  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await _removeLegacyPreferences();
    await _secureStorage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
    } else {
      await _secureStorage.delete(key: _keyRefreshToken);
    }
  }

  @override
  Future<String?> getAccessToken() async {
    await _removeLegacyPreferences();
    return _secureStorage.read(key: _keyAccessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    await _removeLegacyPreferences();
    return _secureStorage.read(key: _keyRefreshToken);
  }

  @override
  Future<void> saveUserCache(Map<String, dynamic> userData) async {
    await _removeLegacyPreferences();
    await _secureStorage.write(key: _keyUserData, value: jsonEncode(userData));
  }

  @override
  Future<Map<String, dynamic>?> getUserCache() async {
    await _removeLegacyPreferences();
    final jsonStr = await _secureStorage.read(key: _keyUserData);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  @override
  Future<void> clearAll() async {
    await _removeLegacyPreferences();
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
    await _secureStorage.delete(key: _keyUserData);
  }
}
