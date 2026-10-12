import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tec_app/core/networking/api_client.dart';
import 'package:tec_app/core/storage/session_manager.dart';
import 'package:tec_app/core/theme/app_theme.dart';
import 'package:tec_app/features/authentication/data/auth_api.dart';
import 'package:tec_app/features/authentication/data/auth_repository_impl.dart';
import 'package:tec_app/features/authentication/presentation/auth_controller.dart';
import 'package:tec_app/features/authentication/presentation/login_screen.dart';
import 'package:tec_app/features/digital_pass/data/digital_pass_repository_impl.dart';
import 'package:tec_app/features/digital_pass/presentation/digital_pass_controller.dart';

import 'auth_repository_test.dart';

void main() {
  Widget createTestWidget() {
    final tokenStorage = MockTokenStorage();
    final sessionManager = SessionManager(storage: tokenStorage);
    final apiClient = ApiClient();
    final authApi = AuthApi(client: apiClient);
    final authRepo = AuthRepositoryImpl(authApi: authApi, tokenStorage: tokenStorage);
    final passRepo = DigitalPassRepositoryImpl(client: apiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionManager>.value(value: sessionManager),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(repository: authRepo, sessionManager: sessionManager),
        ),
        ChangeNotifierProvider<DigitalPassController>(
          create: (_) => DigitalPassController(repository: passRepo),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const LoginScreen(),
      ),
    );
  }

  testWidgets('LoginScreen displays 2026 tech branding and input fields', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Build Login Screen
    await tester.pumpWidget(createTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title and Subtitle
    expect(find.text('TEC-VERSE 2026'), findsOneWidget);
    expect(find.text('Bridging Research. Building the Future.'), findsOneWidget);

    // Verify Form Fields
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Register on TEC-VERSE Website'), findsOneWidget);

    // Verify Approved Institutional Branding
    expect(find.text('MeitY'), findsOneWidget);
    expect(find.text('C-DAC'), findsOneWidget);
    expect(find.text('SAMEER'), findsOneWidget);
    expect(find.text('CMET'), findsOneWidget);
  });

  testWidgets('Validation errors shown when fields are cleared and submitted', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Clear pre-filled fields
    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, '');

    final passwordField = find.byType(TextFormField).last;
    await tester.enterText(passwordField, '');

    // Tap LOGIN
    await tester.tap(find.text('LOGIN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify validation errors appear
    expect(find.text('Please enter your registered email address'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
