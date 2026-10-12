import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/navigation/voice_navigation_service.dart';
import 'core/networking/api_client.dart';
import 'core/storage/session_manager.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/data/auth_api.dart';
import 'features/authentication/data/auth_repository_impl.dart';
import 'features/authentication/domain/auth_repository.dart';
import 'features/authentication/presentation/auth_controller.dart';
import 'features/digital_pass/data/digital_pass_repository_impl.dart';
import 'features/digital_pass/domain/digital_pass_repository.dart';
import 'features/digital_pass/presentation/digital_pass_controller.dart';
import 'navigation/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Core Service Singletons
  final apiClient = ApiClient();
  final tokenStorage = SecureTokenStorageImpl();
  final sessionManager = SessionManager(storage: tokenStorage);

  // Authentication Layer
  final authApi = AuthApi(client: apiClient);
  final AuthRepository authRepository = AuthRepositoryImpl(
    authApi: authApi,
    tokenStorage: tokenStorage,
  );

  // Digital Pass Layer
  final DigitalPassRepository digitalPassRepository = DigitalPassRepositoryImpl(
    client: apiClient,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionManager>.value(value: sessionManager),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(
            repository: authRepository,
            sessionManager: sessionManager,
          ),
        ),
        ChangeNotifierProvider<DigitalPassController>(
          create: (_) => DigitalPassController(
            repository: digitalPassRepository,
          ),
        ),
      ],
      child: const TecVerseApp(),
    ),
  );
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.unknown,
  };
}

class TecVerseApp extends StatelessWidget {
  const TecVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TEC-VERSE 2026',
      navigatorKey: VoiceNavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      scrollBehavior: const AppScrollBehavior(),
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
