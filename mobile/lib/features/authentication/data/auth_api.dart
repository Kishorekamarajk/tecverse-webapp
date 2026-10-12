import '../../../core/constants/api_constants.dart';
import '../../../core/networking/api_client.dart';

/// HTTP API implementation for authentication endpoints.
class AuthApi {
  final ApiClient client;

  AuthApi({required this.client});

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await client.post(
      ApiConstants.loginEndpoint,
      body: {
        'identifier': identifier,
        'email': identifier.contains('@') ? identifier : null,
        'mobile': !identifier.contains('@') ? identifier : null,
        'password': password,
      },
    );
    return response is Map<String, dynamic> ? response : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> requestPasswordReset({required String identifier}) async {
    final response = await client.post(
      ApiConstants.forgotPasswordEndpoint,
      body: {
        'identifier': identifier,
        'email': identifier.contains('@') ? identifier : null,
        'mobile': !identifier.contains('@') ? identifier : null,
      },
    );
    return response is Map<String, dynamic> ? response : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> verifyResetOtp({
    required String identifier,
    required String otp,
  }) async {
    final response = await client.post(
      ApiConstants.verifyResetOtpEndpoint,
      body: {
        'identifier': identifier,
        'email': identifier.contains('@') ? identifier : null,
        'otp': otp,
      },
    );
    return response is Map<String, dynamic> ? response : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
    String? confirmPassword,
  }) async {
    final response = await client.post(
      ApiConstants.resetPasswordEndpoint,
      body: {
        'identifier': identifier,
        'email': identifier.contains('@') ? identifier : null,
        'otp': otp,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword ?? newPassword,
      },
    );
    return response is Map<String, dynamic> ? response : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchProfile(String token) async {
    final response = await client.get(
      ApiConstants.userProfileEndpoint,
      token: token,
    );
    return response is Map<String, dynamic> ? response : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateInterests({
    required String token,
    required List<String> interests,
    String? email,
    String? referenceNumber,
  }) async {
    final response = await client.put(
      ApiConstants.userInterestsEndpoint,
      token: token,
      body: {
        'interests': interests,
        if (email != null && email.isNotEmpty) 'email': email,
        if (referenceNumber != null && referenceNumber.isNotEmpty) 'referenceNumber': referenceNumber,
      },
    );
    return response is Map<String, dynamic> ? response : <String, dynamic>{};
  }

  Future<void> logout(String? token) async {
    try {
      await client.post(ApiConstants.logoutEndpoint, token: token);
    } catch (_) {
      // Best effort backend notification
    }
  }
}
