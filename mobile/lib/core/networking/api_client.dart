import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../constants/api_constants.dart';
import 'api_exceptions.dart';

/// Central HTTP Client for TEC-VERSE backend communication.
///
/// Features:
/// - Configurable base URL with multi-candidate network fallback (Wi-Fi, ADB reverse, Emulator)
/// - Automatic authorization header injection
/// - Development logging [LOGIN] with separate error classification
/// - Robust mapping to typed domain [ApiException]s
class ApiClient {
  final http.Client _httpClient;
  final String? _customBaseUrl;

  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _customBaseUrl = baseUrl;

  String get baseUrl => _customBaseUrl ?? ApiConfig.baseUrl;

  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _sendWithFallback(
      (base) {
        final uri = _buildUriForBase(base, endpoint, queryParameters);
        return _httpClient.get(uri, headers: _buildHeaders(headers, token));
      },
      endpoint,
    );
  }

  /// POST request
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    String? token,
  }) async {
    return _sendWithFallback(
      (base) {
        final uri = _buildUriForBase(base, endpoint);
        return _httpClient.post(
          uri,
          headers: _buildHeaders(headers, token),
          body: body != null ? jsonEncode(body) : null,
        );
      },
      endpoint,
    );
  }

  /// PUT request
  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
    String? token,
  }) async {
    return _sendWithFallback(
      (base) {
        final uri = _buildUriForBase(base, endpoint);
        return _httpClient.put(
          uri,
          headers: _buildHeaders(headers, token),
          body: body != null ? jsonEncode(body) : null,
        );
      },
      endpoint,
    );
  }

  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    String? token,
  }) async {
    return _sendWithFallback(
      (base) {
        final uri = _buildUriForBase(base, endpoint);
        return _httpClient.delete(uri, headers: _buildHeaders(headers, token));
      },
      endpoint,
    );
  }

  Uri _buildUriForBase(String baseHost, String endpoint, [Map<String, dynamic>? queryParameters]) {
    String base = baseHost.endsWith('/') ? baseHost.substring(0, baseHost.length - 1) : baseHost;
    String path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    if (base.endsWith('/api') && path.startsWith('/api/')) {
      path = path.substring(4);
    }
    final fullUrl = '$base$path';

    final parsed = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      return parsed.replace(queryParameters: {
        ...parsed.queryParameters,
        ...stringParams,
      });
    }
    return parsed;
  }

  Map<String, String> _buildHeaders(Map<String, String>? custom, String? token) {
    final headers = <String, String>{
      ApiConstants.headerContentType: ApiConstants.contentTypeJson,
      ApiConstants.headerAccept: ApiConstants.contentTypeJson,
    };

    if (token != null && token.isNotEmpty) {
      headers[ApiConstants.headerAuthorization] = '${ApiConstants.bearerPrefix}$token';
    }

    if (custom != null) {
      headers.addAll(custom);
    }
    return headers;
  }

  /// Executes request with automatic fallback through candidate base URLs
  Future<dynamic> _sendWithFallback(
    Future<http.Response> Function(String base) action,
    String endpoint,
  ) async {
    final custom = _customBaseUrl;
    final candidates = custom != null
        ? [custom]
        : [baseUrl, ...ApiConfig.candidateBaseUrls.where((c) => c != baseUrl)];

    Object? lastError;
    StackTrace? lastStackTrace;

    for (int i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      final targetUri = _buildUriForBase(candidate, endpoint);
      final bool isAuthRequest = endpoint.contains('auth') || endpoint.contains('login');

      if (isAuthRequest) {
        debugPrint('[LOGIN] API URL: $targetUri');
        debugPrint('[LOGIN] Request started');
      }

      try {
        final response = await action(candidate).timeout(
          ApiConstants.connectTimeout,
        );

        if (isAuthRequest) {
          debugPrint('[LOGIN] Response received: ${response.statusCode}');
        }

        // Successfully connected to candidate backend - lock in candidate URL
        if (_customBaseUrl == null) {
          ApiConfig.setResolvedBaseUrl(candidate);
        }

        return _processResponse(response);
      } on SocketException catch (se, st) {
        lastError = se;
        lastStackTrace = st;
        final msg = se.message.toLowerCase();
        final osError = se.osError?.message.toLowerCase() ?? '';

        if (msg.contains('refused') || osError.contains('refused')) {
          if (isAuthRequest) debugPrint('[LOGIN] Error: Connection refused at $candidate');
        } else if (msg.contains('timed out') || osError.contains('timed out') || msg.contains('unreachable')) {
          if (isAuthRequest) debugPrint('[LOGIN] Error: Connection timeout at $candidate');
        } else {
          if (isAuthRequest) debugPrint('[LOGIN] Error: SocketException - ${se.message}');
        }
        continue;
      } on TimeoutException catch (te, st) {
        lastError = te;
        lastStackTrace = st;
        if (isAuthRequest) debugPrint('[LOGIN] Error: Connection timeout at $candidate');
        continue;
      } on http.ClientException catch (ce, st) {
        lastError = ce;
        lastStackTrace = st;
        if (isAuthRequest) debugPrint('[LOGIN] Error: ClientException - ${ce.message}');
        continue;
      } catch (e) {
        if (e is ApiException) rethrow;
        lastError = e;
        continue;
      }
    }

    // All candidates failed - map to exact network failure exception
    if (lastError is TimeoutException) {
      debugPrint('[LOGIN] Error: Connection timeout');
      throw const ConnectionTimeoutException('Unable to reach the server. Please try again.');
    } else if (lastError is SocketException) {
      debugPrint('[LOGIN] Error: Network / socket error');
      throw const ServerUnavailableException('Unable to reach the server. Please try again.');
    } else if (lastError is http.ClientException) {
      debugPrint('[LOGIN] Error: HTTP Client failure');
      throw const ConnectionTimeoutException('Unable to reach the server. Please try again.');
    } else if (lastError is ApiException) {
      throw lastError;
    }

    debugPrint('[LOGIN] Error: General failure - $lastError');
    Error.throwWithStackTrace(
      const ConnectionTimeoutException('Unable to reach the server. Please try again.'),
      lastStackTrace ?? StackTrace.current,
    );
  }

  dynamic _processResponse(http.Response response) {
    final code = response.statusCode;
    dynamic decoded;
    try {
      if (response.body.isNotEmpty) {
        decoded = jsonDecode(response.body);
      }
    } catch (_) {
      decoded = response.body;
    }

    if (code >= 200 && code < 300) {
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('data') &&
            decoded['data'] != null &&
            !decoded.containsKey('success') &&
            !decoded.containsKey('token') &&
            !decoded.containsKey('accessToken')) {
          return decoded['data'];
        }
      }
      return decoded;
    }

    String message = 'An unexpected error occurred';
    String? errorCode;
    if (decoded is Map<String, dynamic>) {
      errorCode = decoded['code']?.toString();
      message = decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          decoded['description']?.toString() ??
          decoded['detail']?.toString() ??
          message;
    }

    switch (code) {
      case 400:
        debugPrint('[LOGIN] Error: HTTP 400 - $message');
        throw ValidationException(message, statusCode: code, details: decoded);
      case 401:
        debugPrint('[LOGIN] Error: HTTP 401 - $message');
        if (errorCode == 'USER_NOT_REGISTERED' || message.toLowerCase().contains('not registered')) {
          throw const UserNotRegisteredException('Invalid credentials');
        }
        throw UnauthorizedException(
          message.isNotEmpty &&
                  message != 'An unexpected error occurred' &&
                  message.toLowerCase() != 'unauthorized'
              ? message
              : 'Your session has expired. Please sign in again.',
        );
      case 403:
        debugPrint('[LOGIN] Error: HTTP 403 - $message');
        if (errorCode == 'REGISTRATION_NOT_APPROVED' || message.toLowerCase().contains('not yet approved')) {
          throw RegistrationPendingException(message);
        }
        throw ForbiddenException(message.isNotEmpty && message != 'An unexpected error occurred' ? message : 'Access denied.');
      case 429:
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '') ?? 60;
        throw TooManyRequestsException(message, retryAfterSeconds: retryAfter);
      case 404:
        debugPrint('[LOGIN] Error: HTTP 404 - $message');
        throw NotFoundException(
          message.toLowerCase() == 'not found'
              ? 'Attendee or digital pass was not found.'
              : message,
        );
      case 500:
        debugPrint('[LOGIN] Error: HTTP 500 - $message');
        throw const ServerException('Server error. Please try again later.');
      case 502:
      case 503:
      case 504:
        debugPrint('[LOGIN] Error: HTTP $code - $message');
        throw const ServerUnavailableException('Unable to reach the server. Please try again.');
      default:
        debugPrint('[LOGIN] Error: HTTP $code - $message');
        throw ServerException('$message (HTTP $code)');
    }
  }

  void close() {
    _httpClient.close();
  }
}
