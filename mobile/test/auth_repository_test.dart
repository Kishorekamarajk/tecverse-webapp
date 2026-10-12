import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tec_app/core/networking/api_client.dart';
import 'package:tec_app/core/networking/api_exceptions.dart';
import 'package:tec_app/core/storage/session_manager.dart';
import 'package:tec_app/core/storage/token_storage.dart';
import 'package:tec_app/features/authentication/data/auth_api.dart';
import 'package:tec_app/features/authentication/data/auth_repository_impl.dart';
import 'package:tec_app/features/authentication/presentation/auth_controller.dart';

class MockTokenStorage implements TokenStorage {
  String? token;
  String? refreshToken;
  Map<String, dynamic>? cache;

  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    token = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => token;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveUserCache(Map<String, dynamic> userData) async {
    cache = userData;
  }

  @override
  Future<Map<String, dynamic>?> getUserCache() async => cache;

  @override
  Future<void> clearAll() async {
    token = null;
    refreshToken = null;
    cache = null;
  }
}

void main() {
  group('AuthRepository & Website User Synchronization Tests', () {
    late MockTokenStorage tokenStorage;
    late AuthRepositoryImpl authRepository;
    late SessionManager sessionManager;
    late AuthController authController;

    setUp(() {
      tokenStorage = MockTokenStorage();
      sessionManager = SessionManager(storage: tokenStorage);

      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('login')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final password = body['password'];

          if (password == 'wrong_password_xyz' || password == '1') {
            return http.Response(
              jsonEncode({'message': 'Invalid email or password.', 'code': 'INVALID_CREDENTIALS'}),
              401,
            );
          }

          return http.Response(
            jsonEncode({
              'accessToken': 'mock_access_token_123',
              'refreshToken': 'mock_refresh_token_123',
              'user': {
                'id': 'USR-CDAC-1042',
                'referenceNumber': '202611261042',
                'officialName': 'Dr. Kishore Kumar',
                'email': 'kishore@cdac.in',
                'mobile': '9840123456',
                'category': 'Central Government',
                'organization': 'C-DAC Chennai',
                'designation': 'Joint Director / Scientist F',
                'attendanceDays': 'Both Days (26 & 27 Nov 2026)',
                'interests': ['AI & Supercomputing', 'Quantum Technologies'],
                'registrationStatus': 'APPROVED',
              }
            }),
            200,
          );
        }

        if (request.url.path.contains('interests')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final List interests = body['interests'] ?? [];
          return http.Response(
            jsonEncode({
              'id': 'USR-CDAC-1042',
              'referenceNumber': '202611261042',
              'officialName': 'Dr. Kishore Kumar',
              'email': 'kishore@cdac.in',
              'mobile': '9840123456',
              'category': 'Central Government',
              'organization': 'C-DAC Chennai',
              'designation': 'Joint Director / Scientist F',
              'attendanceDays': 'Both Days (26 & 27 Nov 2026)',
              'interests': interests,
              'registrationStatus': 'APPROVED',
            }),
            200,
          );
        }

        return http.Response(jsonEncode({}), 200);
      });

      final apiClient = ApiClient(httpClient: mockHttpClient, baseUrl: 'http://127.0.0.1:2302/api');
      final authApi = AuthApi(client: apiClient);
      authRepository = AuthRepositoryImpl(
        authApi: authApi,
        tokenStorage: tokenStorage,
      );
      authController = AuthController(
        repository: authRepository,
        sessionManager: sessionManager,
      );
    });

    test('1. Valid registered website user logs in successfully', () async {
      final result = await authRepository.login(
        identifier: 'kishore@cdac.in',
        password: 'tecverse2026',
      );

      expect(result.profile.officialName, 'Dr. Kishore Kumar');
      expect(result.profile.referenceNumber, '202611261042');
      expect(result.profile.organization, 'C-DAC Chennai');
      expect(result.profile.category, 'Central Government');
      expect(result.tokens.accessToken, isNotEmpty);

      // Verify token storage
      expect(await tokenStorage.getAccessToken(), isNotEmpty);
    });

    test('2. Valid registered mobile number logs in successfully', () async {
      final result = await authRepository.login(
        identifier: '9840123456',
        password: 'tecverse2026',
      );

      expect(result.profile.officialName, 'Dr. Kishore Kumar');
      expect(result.profile.referenceNumber, '202611261042');
    });

    test('3. Invalid password throws InvalidCredentialsException', () async {
      expect(
        () => authRepository.login(
          identifier: 'kishore@cdac.in',
          password: '1',
        ),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });

    test('4. Session restoration when valid token exists', () async {
      // First login
      await authController.login(
        identifier: 'kishore@cdac.in',
        password: 'tecverse2026',
      );
      expect(authController.isAuthenticated, isTrue);

      // Simulate app restart
      final newController = AuthController(
        repository: authRepository,
        sessionManager: sessionManager,
      );
      final hasSession = await newController.checkSession();
      expect(hasSession, isTrue);
      expect(newController.currentUser?.officialName, 'Dr. Kishore Kumar');
    });

    test('5. Logout cleans session and token storage', () async {
      await authController.login(
        identifier: 'kishore@cdac.in',
        password: 'tecverse2026',
      );
      expect(authController.isAuthenticated, isTrue);

      await authController.logout();
      expect(authController.isAuthenticated, isFalse);
      expect(authController.currentUser, isNull);
      expect(await tokenStorage.getAccessToken(), isNull);
    });

    test('6. Updating attendee technology interests', () async {
      final loginResult = await authRepository.login(
        identifier: 'kishore@cdac.in',
        password: 'tecverse2026',
      );

      final updated = await authRepository.updateInterests(
        token: loginResult.tokens.accessToken,
        interests: ['Quantum Technologies', 'Semiconductors & VLSI'],
      );

      expect(updated.interests, contains('Quantum Technologies'));
      expect(updated.interests, contains('Semiconductors & VLSI'));
    });
  });
}

