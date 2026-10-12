import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

/// Centralized Production / Staging API Configuration for TEC-VERSE.
///
/// Defaults to the shared TEC-VERSE staging application and API.
///
/// Can also be dynamically overridden at build time via:
/// `--dart-define=API_BASE_URL=https://...`
class ApiConfig {
  ApiConfig._();

  /// Shared website/backend staging origin. Override with
  /// `--dart-define=STAGING_BASE_URL=https://your-staging-host/tecverse`.
  static const String stagingBaseUrl = String.fromEnvironment(
    'STAGING_BASE_URL',
    defaultValue: 'https://ngypr123.bosschn.in/tecverse',
  );

  static String? _resolvedBaseUrl;

  /// Centralized base URL for all API requests
  static String get baseUrl {
    const definedUrl = String.fromEnvironment('API_BASE_URL');
    if (definedUrl.isNotEmpty) {
      return _normalizeUrl(definedUrl);
    }

    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;

    return _normalizeUrl(stagingBaseUrl);
  }

  /// Ordered candidate base URLs to attempt in sequence
  static List<String> get candidateBaseUrls {
    const definedUrl = String.fromEnvironment('API_BASE_URL');
    if (definedUrl.isNotEmpty) {
      return [_normalizeUrl(definedUrl)];
    }

    return [
      _normalizeUrl(stagingBaseUrl),
      if (!kIsWeb && kDebugMode) ...[
        'http://10.0.2.2:2304/api',
        'http://127.0.0.1:2304/api',
        'http://localhost:2304/api',
      ],
    ];
  }

  /// Ensures URL ends with `/api` without double slashes.
  /// A URL may already include `/api/mobile` when supplied by a deployment.
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
