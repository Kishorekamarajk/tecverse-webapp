import 'authenticated_user.dart';

/// Contract for Authentication and Profile synchronization.
/// The UI depends ONLY on this domain abstraction.
abstract class AuthRepository {
  /// Authenticates user with registered email or mobile and password.
  Future<AuthenticatedUser> login({
    required String identifier,
    required String password,
  });

  /// Request OTP for existing registered website user.
  /// Requests a reset OTP and returns the server's resend cooldown in seconds.
  Future<int> requestPasswordReset({required String identifier});

  /// Verify entered 6-digit OTP and return the one-time reset token.
  /// The token must be kept in memory only and passed to [resetPassword].
  Future<String> verifyResetOtp({
    required String identifier,
    required String otp,
  });

  /// Set new password using the reset token obtained from [verifyResetOtp].
  Future<void> resetPassword({
    required String identifier,
    required String resetToken,
    required String newPassword,
    String? confirmPassword,
  });

  /// Permanently deletes the attendee account after re-checking [password],
  /// then clears all locally stored credentials.
  Future<void> deleteAccount({
    required String token,
    required String password,
  });

  /// Synchronizes attendee profile from authoritative website backend.
  Future<UserProfile> getProfile({required String token});

  /// Updates attendee technology interests on the backend.
  Future<UserProfile> updateInterests({
    required String token,
    required List<String> interests,
  });

  /// Terminates session and informs backend if supported.
  Future<void> logout({String? token});
}
