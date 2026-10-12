import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tec_app/core/networking/api_client.dart';
import 'package:tec_app/core/networking/api_exceptions.dart';
import 'package:tec_app/features/authentication/data/auth_api.dart';
import 'package:tec_app/features/authentication/data/auth_repository_impl.dart';

import 'auth_repository_test.dart';

void main() {
  group('Login Connectivity & Error Classification Tests (Scenarios A through F)', () {
    late MockTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = MockTokenStorage();
    });

    test('Test A: Valid registered user + correct password -> Successful login', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'accessToken': 'valid_token_A',
            'user': {
              'id': 'USR-CDAC-1042',
              'referenceNumber': '202611261042',
              'officialName': 'Dr. Kishore Kumar',
              'email': 'kishore@cdac.in',
            }
          }),
          200,
        );
      });

      final client = ApiClient(httpClient: mockHttpClient, baseUrl: 'http://localhost:2302/api');
      final authApi = AuthApi(client: client);
      final repo = AuthRepositoryImpl(authApi: authApi, tokenStorage: tokenStorage);

      final result = await repo.login(
        identifier: 'kishore@cdac.in',
        password: 'tecverse2026',
      );

      expect(result.tokens.accessToken, isNotEmpty);
      expect(result.profile.officialName, 'Dr. Kishore Kumar');
      expect(result.profile.email, 'kishore@cdac.in');
      expect(result.profile.referenceNumber, '202611261042');
    });

    test('Test B: Registered user + incorrect password -> Invalid credentials message, NOT timeout', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Invalid email or password.', 'code': 'INVALID_CREDENTIALS'}),
          401,
        );
      });

      final client = ApiClient(httpClient: mockHttpClient, baseUrl: 'http://localhost:2302/api');
      final authApi = AuthApi(client: client);
      final repo = AuthRepositoryImpl(authApi: authApi, tokenStorage: tokenStorage);

      expect(
        () => repo.login(
          identifier: 'kishore@cdac.in',
          password: 'wrong_password_xyz',
        ),
        throwsA(
          isA<InvalidCredentialsException>().having(
            (e) => e.message,
            'message',
            'Invalid credentials',
          ),
        ),
      );
    });

    test('Test C: Unregistered user -> Registration error message, NOT timeout', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'You are not registered for TEC-VERSE 2026.', 'code': 'USER_NOT_REGISTERED'}),
          401,
        );
      });

      final client = ApiClient(httpClient: mockHttpClient, baseUrl: 'http://localhost:2302/api');
      final authApi = AuthApi(client: client);
      final repo = AuthRepositoryImpl(authApi: authApi, tokenStorage: tokenStorage);

      expect(
        () => repo.login(
          identifier: 'unregistered.person@test.in',
          password: 'somepassword123',
        ),
        throwsA(
          isA<UserNotRegisteredException>().having(
            (e) => e.message,
            'message',
            'Invalid credentials',
          ),
        ),
      );
    });

    test('Test D: Backend stopped / unreachable port -> Server unavailable message', () async {
      final mockHttpClient = MockClient((request) async {
        throw const SocketException('Connection refused');
      });

      final client = ApiClient(httpClient: mockHttpClient, baseUrl: 'http://127.0.0.1:59999/api');
      final authApi = AuthApi(client: client);
      final repo = AuthRepositoryImpl(authApi: authApi, tokenStorage: tokenStorage);

      expect(
        () => repo.login(
          identifier: 'kishore@cdac.in',
          password: 'tecverse2026',
        ),
        throwsA(
          isA<ServerUnavailableException>().having(
            (e) => e.message,
            'message',
            'Unable to reach the server. Please try again.',
          ),
        ),
      );
    });

    test('Test F: Correct local API URL -> Login works successfully with candidate fallback', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'accessToken': 'valid_token_F',
            'user': {
              'id': 'USR-DEVIKA-4091',
              'referenceNumber': '202611264091',
              'officialName': 'devika R',
              'email': 'devika.r@tecverse.in',
            }
          }),
          200,
        );
      });

      final client = ApiClient(httpClient: mockHttpClient, baseUrl: 'http://localhost:2302/api');
      final authApi = AuthApi(client: client);
      final repo = AuthRepositoryImpl(authApi: authApi, tokenStorage: tokenStorage);

      final result = await repo.login(
        identifier: 'devika R',
        password: 'tecverse2026',
      );

      expect(result.tokens.accessToken, isNotEmpty);
      expect(result.profile.officialName, 'devika R');
    });
  });
}

