import '../../../core/constants/api_constants.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_exceptions.dart';
import '../../authentication/domain/authenticated_user.dart';
import '../domain/digital_event_pass.dart';
import '../domain/digital_pass_repository.dart';

class DigitalPassRepositoryImpl implements DigitalPassRepository {
  final ApiClient client;

  DigitalPassRepositoryImpl({required this.client});

  @override
  Future<DigitalEventPass> getDigitalPass({
    required String token,
    required UserProfile user,
  }) async {
    // The server derives attendee identity from the validated bearer session.
    final response = await client.get(
      ApiConstants.digitalPassEndpoint,
      token: token,
    );
    if (response is Map<String, dynamic> && response.isNotEmpty && !response.containsKey('error')) {
      return DigitalEventPass.fromJson(response);
    }

    throw const ServerException(
      'The registration service returned an invalid pass response. Please try again.',
    );
  }

  @override
  Future<DigitalEventPass> refreshPassStatus({
    required String token,
    required String passId,
  }) async {
    try {
      final response = await client.get(
        '${ApiConstants.digitalPassEndpoint}/$passId/status',
        token: token,
      );
      if (response is Map<String, dynamic> && response.isNotEmpty) {
        return DigitalEventPass.fromJson(response);
      }
    } catch (_) {}

    throw Exception('Pass not found');
  }

  @override
  Future<DigitalEventPass> verifyPassAtGate({
    required String qrToken,
    required String gateId,
  }) async {
    try {
      final response = await client.post(
        ApiConstants.verifyPassEndpoint,
        body: {
          'qrToken': qrToken,
          'gateId': gateId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (response is Map<String, dynamic>) {
        return DigitalEventPass.fromJson(response);
      }
    } catch (_) {}

    throw Exception('Invalid or expired QR token');
  }
}
