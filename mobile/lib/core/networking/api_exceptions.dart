/// Base exception for TEC-VERSE API errors.
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

/// Thrown when user enters wrong email/mobile or password.
class InvalidCredentialsException extends ApiException {
  const InvalidCredentialsException([super.message = 'Invalid credentials'])
      : super(statusCode: 401);
}

/// Thrown when user is not found in the registration database.
class UserNotRegisteredException extends ApiException {
  const UserNotRegisteredException([super.message = 'Invalid credentials'])
      : super(statusCode: 401);
}

/// Thrown when user registration exists but is pending / not approved.
class RegistrationPendingException extends ApiException {
  const RegistrationPendingException([super.message = 'Your registration is not yet approved for TEC-VERSE 2026.'])
      : super(statusCode: 403);
}

/// Thrown when connection to the backend server times out.
class ConnectionTimeoutException extends ApiException {
  const ConnectionTimeoutException([super.message = 'Unable to reach the server. Please try again.']);
}

/// Thrown when backend or database service is unavailable (HTTP 503 or connection refused).
class ServerUnavailableException extends ApiException {
  const ServerUnavailableException([super.message = 'Unable to reach the server. Please try again.'])
      : super(statusCode: 503);
}

/// Thrown when device has no network connection.
class NetworkUnavailableException extends ApiException {
  const NetworkUnavailableException([super.message = 'Unable to reach the server. Please try again.']);
}

/// Thrown on network timeout or offline state (legacy alias).
class NetworkException extends ApiException {
  const NetworkException([super.message = 'Unable to reach the server. Please try again.']);
}

/// Thrown when JWT token expires or session is invalidated.
class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Your session has expired. Please sign in again.'])
      : super(statusCode: 401);
}

/// Thrown when server returns 403 Forbidden.
class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Access denied.'])
      : super(statusCode: 403);
}

/// Thrown when resource is not found (e.g. unverified registration).
class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Registered account not found. Please verify your website registration.'])
      : super(statusCode: 404);
}

/// Thrown on 500+ internal server errors.
class ServerException extends ApiException {
  const ServerException([super.message = 'Server error. Please try again later.'])
      : super(statusCode: 500);
}

/// Thrown when a server rate limit includes a retry delay.
class TooManyRequestsException extends ApiException {
  final int retryAfterSeconds;

  const TooManyRequestsException(String message, {required this.retryAfterSeconds})
      : super(message, statusCode: 429);
}

/// Thrown on 400 Bad Request or validation failure.
class ValidationException extends ApiException {
  const ValidationException(super.message, {super.statusCode = 400, super.details});
}

