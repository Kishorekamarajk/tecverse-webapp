import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tec_app/core/networking/api_client.dart';
import 'package:tec_app/features/authentication/domain/authenticated_user.dart';
import 'package:tec_app/features/digital_pass/data/digital_pass_repository_impl.dart';
import 'package:tec_app/features/digital_pass/domain/digital_event_pass.dart';

void main() {
  group('Unique Digital Event Pass & QR Architecture Tests', () {
    late ApiClient apiClient;
    late DigitalPassRepositoryImpl passRepository;

    final testUser = UserProfile(
      id: 'USR-CDAC-1042',
      referenceNumber: '202611261042',
      officialName: 'Dr. Kishore Kumar',
      email: 'kishore@cdac.in',
      mobile: '9840123456',
      category: 'Central Government',
      organization: 'C-DAC Chennai',
      designation: 'Joint Director / Scientist F',
      attendanceDays: 'Both Days (26 & 27 Nov 2026)',
      interests: const ['AI & Supercomputing', 'Quantum Technologies'],
      registrationStatus: RegistrationStatus.approved,
    );

    setUp(() {
      final mockHttpClient = MockClient((request) async {
        return http.Response('{"error": "not_found"}', 404);
      });
      apiClient = ApiClient(httpClient: mockHttpClient, baseUrl: 'http://localhost:2302/api');
      passRepository = DigitalPassRepositoryImpl(client: apiClient);
    });

    test('1. Pass identity is tied 1-to-1 to website registration reference number', () async {
      final pass = await passRepository.getDigitalPass(
        token: 'test_token',
        user: testUser,
      );

      expect(pass.attendeeId, '202611261042');
      expect(pass.holderName, 'Dr. Kishore Kumar');
      expect(pass.organization, 'C-DAC Chennai');
      expect(pass.status, PassStatus.active);
      expect(pass.eventName, 'TEC-VERSE 2026');
      expect(pass.venue, 'CHENNAI TRADE CENTRE, NANDAMBAKKAM, CHENNAI 600089');
    });

    test('2. QR token is opaque, signed, and contains no passwords or raw DB dumps', () async {
      final pass = await passRepository.getDigitalPass(
        token: 'test_token',
        user: testUser,
      );

      // Verify prefix format
      expect(pass.qrToken.startsWith('TECVERSE26:'), isTrue);

      // Verify it does NOT expose sensitive personal secrets
      expect(pass.qrToken.contains('password'), isFalse);
      expect(pass.qrToken.contains('tecverse2026'), isFalse);
      expect(pass.qrToken.contains('SELECT'), isFalse);
    });

    test('3. Repeated opens return IDENTICAL pass (not randomly generated each time)', () async {
      final pass1 = await passRepository.getDigitalPass(
        token: 'test_token',
        user: testUser,
      );

      final pass2 = await passRepository.getDigitalPass(
        token: 'test_token',
        user: testUser,
      );

      expect(pass1.passId, equals(pass2.passId));
      expect(pass1.qrToken, equals(pass2.qrToken));
      expect(pass1.attendeeId, equals(pass2.attendeeId));
    });

    test('4. Gate verification transitions pass from ACTIVE to USED', () async {
      final pass = await passRepository.getDigitalPass(
        token: 'test_token',
        user: testUser,
      );

      expect(pass.status, PassStatus.active);

      // Registration staff scans QR code at Hall 1 Entry Gate
      final verifiedPass = await passRepository.verifyPassAtGate(
        qrToken: pass.qrToken,
        gateId: 'GATE-HALL1-A',
      );

      expect(verifiedPass.status, PassStatus.used);
      expect(verifiedPass.checkedInAt, isNotNull);
    });
  });
}
