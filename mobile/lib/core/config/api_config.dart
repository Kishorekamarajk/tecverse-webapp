import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

/// Centralized server URL configuration for TEC-VERSE.
///
/// This is the ONE source of truth for the server location. Every API URL,
/// web page link (privacy policy, account deletion, registration) and QR
/// verification URL is derived from [serverBaseUrl].
///
/// Override at build time with:
/// `--dart-define=API_BASE_URL=https://your-host/tecverse`
/// (a value that already ends in `/api` or `/api/mobile` is also accepted).
///
/// The default below is the production website origin. API requests use
/// `https://tec-verse.cdac.in/api`; override it at build time when needed.
class ApiConfig {
  ApiConfig._();

  /// Raw value supplied via `--dart-define=API_BASE_URL=...` (empty if absent).
  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Default production website origin. See class docs.
  static const String _defaultServerBaseUrl = 'https://tec-verse.cdac.in';

  /// Configured server origin + context path, as supplied (not yet normalized).
  static String get _configuredBaseUrl =>
      _definedBaseUrl.isNotEmpty ? _definedBaseUrl : _defaultServerBaseUrl;

  static String? _resolvedBaseUrl;

  /// Centralized base URL for all API requests (always ends with `/api`).
  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _normalizeUrl(_definedBaseUrl);
    }

    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;

    return _normalizeUrl(_configuredBaseUrl);
  }

  /// Website origin + context path without the `/api` suffix,
  /// e.g. `https://tec-verse.cdac.in`.
  static String get webBaseUrl {
    final api = _normalizeUrl(_configuredBaseUrl);
    return api.substring(0, api.length - '/api'.length);
  }

  /// Public privacy policy page.
  static String get privacyPolicyUrl => '$webBaseUrl/privacy-policy';

  /// Public account deletion request page.
  static String get accountDeletionUrl => '$webBaseUrl/account-deletion';

  /// Ordered candidate base URLs to attempt in sequence
  static List<String> get candidateBaseUrls {
    if (_definedBaseUrl.isNotEmpty) {
      return [_normalizeUrl(_definedBaseUrl)];
    }

    return [
      _normalizeUrl(_defaultServerBaseUrl),
    ];
  }

  /// Ensures URL ends with `/api` without double slashes.
  /// A URL may already include `/api/mobile` when supplied by a deployment.
  /// Release builds reject non-HTTPS URLs.
  static String _normalizeUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    final parsed = Uri.tryParse(trimmed);
    if (!kDebugMode && parsed?.scheme != 'https') {
      throw ArgumentError('Release builds require an HTTPS API URL.');
    }
    if (trimmed.endsWith('/api/mobile')) {
      return trimmed.substring(0, trimmed.length - '/mobile'.length);
    }
    return trimmed.endsWith('/api') ? trimmed : '$trimmed/api';
  }

  /// Cache a successfully verified base URL
  static void setResolvedBaseUrl(String url) {
    _resolvedBaseUrl = url;
  }

  /// Direct URL for physical devices
  static String get physicalDeviceBaseUrl => baseUrl;
}
