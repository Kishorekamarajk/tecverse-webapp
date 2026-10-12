import '../domain/digital_event_pass.dart';
import '../../authentication/domain/authenticated_user.dart';

/// Abstract contract for Digital Pass lifecycle and QR verification.
abstract class DigitalPassRepository {
  /// Fetches authoritative Digital Event Pass for the authenticated attendee.
  Future<DigitalEventPass> getDigitalPass({
    required String token,
    required UserProfile user,
  });

  /// Refreshes pass status (e.g. check if verified at entrance, revoked, or expired).
  Future<DigitalEventPass> refreshPassStatus({
    required String token,
    required String passId,
  });

  /// Backend verification service called by event check-in staff scanning QR.
  Future<DigitalEventPass> verifyPassAtGate({
    required String qrToken,
    required String gateId,
  });
}
