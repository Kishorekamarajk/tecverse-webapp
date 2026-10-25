import '../../../core/networking/api_exceptions.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/authenticated_user.dart';
import 'auth_api.dart';

/// Implementation of [AuthRepository] interacting directly with Spring Boot backend & PostgreSQL database.
class AuthRepositoryImpl implements AuthRepository {
  final AuthApi authApi;
  final TokenStorage tokenStorage;

  AuthRepositoryImpl({
    required this.authApi,
    required this.tokenStorage,
  });

  @override
  Future<AuthenticatedUser> login({
    required String identifier,
    required String password,
  }) async {
    final cleanIdentifier = identifier.trim().toLowerCase();
    // Passwords are used exactly as typed: the server never trims them, so neither may the app.
    final cleanPassword = password;

    final data = await authApi.login(identifier: cleanIdentifier, password: cleanPassword);
    if (data.isNotEmpty && (data.containsKey('accessToken') || data.containsKey('token'))) {
      final tokens = AuthTokens.fromJson(data);
      final userProfile = UserProfile.fromJson(
        data['user'] is Map<String, dynamic> ? data['user'] : data,
      );
      await tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      await tokenStorage.saveUserCache(userProfile.toJson());
      return AuthenticatedUser(tokens: tokens, profile: userProfile);
    }

    throw const ServerException('Invalid response received from authentication service.');
  }

  @override
  Future<int> requestPasswordReset({required String identifier}) async {
    final cleanIdentifier = identifier.trim().toLowerCase();
    final res = await authApi.requestPasswordReset(identifier: cleanIdentifier);
    final seconds = res['retryAfterSeconds'];
    return seconds is num ? seconds.toInt() : 0;
  }

  @override
  Future<String> verifyResetOtp({
    required String identifier,
    required String otp,
  }) async {
    final cleanEmail = identifier.trim().toLowerCase();
    final res = await authApi.verifyResetOtp(
      email: cleanEmail,
      otp: otp.trim(),
    );
    final resetToken = res['resetToken']?.toString() ?? '';
    if (res['success'] == true && resetToken.isNotEmpty) {
      return resetToken;
    }
    throw ValidationException(
      res['message']?.toString() ?? 'Invalid or expired OTP. Please try again.',
    );
  }

  @override
  Future<void> resetPassword({
    required String identifier,
    required String resetToken,
    required String newPassword,
    String? confirmPassword,
  }) async {
    final cleanEmail = identifier.trim().toLowerCase();
    await authApi.resetPassword(
      email: cleanEmail,
      resetToken: resetToken,
      newPassword: newPassword,
      confirmPassword: confirmPassword ?? newPassword,
    );
  }

  @override
  Future<void> deleteAccount({
    required String token,
    required String password,
  }) async {
    final res = await authApi.deleteAccount(token: token, password: password);
    if (res['success'] == false) {
      throw ValidationException(
        res['message']?.toString() ?? 'Unable to delete the account. Please try again.',
      );
    }
    // The account no longer exists on the server: wipe every local credential.
    await tokenStorage.clearAll();
  }

  @override
  Future<UserProfile> getProfile({required String token}) async {
    try {
      final data = await authApi.fetchProfile(token);
      if (data.isNotEmpty) {
        final profile = UserProfile.fromJson(data);
        await tokenStorage.saveUserCache(profile.toJson());
        return profile;
      }
      throw const ServerException('The profile service returned an invalid response.');
    } catch (error) {
      if (error is UnauthorizedException ||
          error is ForbiddenException ||
          error is NotFoundException ||
          error is ValidationException) {
        rethrow;
      }
      // Keep a valid saved session when the backend is temporarily unreachable.
      final cached = await tokenStorage.getUserCache();
      if (cached != null) return UserProfile.fromJson(cached);
      rethrow;
    }
  }

  @override
  Future<UserProfile> updateInterests({
    required String token,
    required List<String> interests,
  }) async {
    final cached = await tokenStorage.getUserCache();
    UserProfile? currentProfile = cached != null ? UserProfile.fromJson(cached) : null;

    try {
      final data = await authApi.updateInterests(
        token: token,
        interests: interests,
        email: currentProfile?.email,
        referenceNumber: currentProfile?.referenceNumber,
      );
      if (data.isNotEmpty) {
        final updated = currentProfile != null
            ? currentProfile.copyWith(interests: interests)
            : UserProfile.fromJson(data);
        await tokenStorage.saveUserCache(updated.toJson());
        return updated;
      }
    } catch (_) {}

    if (currentProfile != null) {
      final updated = currentProfile.copyWith(interests: interests);
      await tokenStorage.saveUserCache(updated.toJson());
      return updated;
    }

    throw const UnauthorizedException('Session expired or profile unavailable.');
  }

  @override
  Future<void> logout({String? token}) async {
    await authApi.logout(token);
    await tokenStorage.clearAll();
  }
}

