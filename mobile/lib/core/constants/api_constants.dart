import '../config/api_config.dart';

/// API Constants for Tec-Verse 2026.
///
/// Designed to connect directly to the local Tec-Verse backend
/// (running by default on port 3000) while remaining fully configurable through
/// environment variables or build flags.
class ApiConstants {
  ApiConstants._();

  /// Centralized Base URL resolved via [ApiConfig]
  static String get baseUrl => ApiConfig.baseUrl;

  /// Official Website Registration URL (where users register before using the app).
  /// Derived from the single server URL configured in [ApiConfig].
  static String get websiteRegistrationUrl => ApiConfig.webBaseUrl;

  /// Public web pages opened in the external browser.
  static String get privacyPolicyUrl => ApiConfig.privacyPolicyUrl;
  static String get accountDeletionUrl => ApiConfig.accountDeletionUrl;

  /// Health Check Endpoint
  static const String healthEndpoint = '/mobile/health';

  /// Core Event Master Data Endpoints (from PostgreSQL backend)
  static const String eventEndpoint = '/mobile/event';
  static const String scheduleEndpoint = '/mobile/schedule';
  static const String exhibitorsEndpoint = '/mobile/exhibitors';
  static const String floorPlanEndpoint = '/mobile/floor-plan';
  static const String technologyDomainsEndpoint = '/mobile/technology-domains';
  static const String thematicSessionsEndpoint = '/mobile/thematic-sessions';
  static const String importantDatesEndpoint = '/mobile/important-dates';
  static const String newsEndpoint = '/mobile/news';
  static const String notificationsEndpoint = '/mobile/notifications';
  static const String faqEndpoint = '/mobile/faq';

  /// Profile & Attendee Data
  static const String profileEndpoint = '/mobile/profile';
  static const String userProfileEndpoint = '/mobile/profile';
  static const String userInterestsEndpoint = '/mobile/me/interests';
  static const String deleteAccountEndpoint = '/mobile/me/delete';

  /// Digital Event Pass & QR Verification Endpoints
  static const String digitalPassEndpoint = '/mobile/digital-pass';
  static const String refreshPassEndpoint = '/mobile/digital-pass';
  static const String verifyPassEndpoint = '/mobile/pass/verify';

  /// Authentication & User Session Endpoints
  static const String loginEndpoint = '/mobile/auth/login';
  static const String logoutEndpoint = '/mobile/auth/logout';
  static const String forgotPasswordEndpoint = '/mobile/auth/forgot-password';
  static const String verifyResetOtpEndpoint = '/mobile/auth/verify-reset-otp';
  static const String resetPasswordEndpoint = '/mobile/auth/reset-password';

  static const String speakersEndpoint = '/mobile/speakers';
  static const String thematicDomainsEndpoint = '/mobile/technology-domains';

  /// HTTP Headers
  static const String headerAuthorization = 'Authorization';
  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';
  static const String contentTypeJson = 'application/json';
  static const String bearerPrefix = 'Bearer ';

  /// Timeouts
  /// connectTimeout: per-candidate timeout. With 4 Android candidates, worst-case = 32s.
  /// Primary (10.184.48.20) will succeed instantly when on company network.
  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
