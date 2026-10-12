import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tec_app/core/networking/api_client.dart';
import 'package:tec_app/core/storage/session_manager.dart';
import 'package:tec_app/core/theme/app_theme.dart';
import 'package:tec_app/features/authentication/presentation/auth_controller.dart';
import 'package:tec_app/features/digital_pass/data/digital_pass_repository_impl.dart';
import 'package:tec_app/features/digital_pass/presentation/digital_pass_controller.dart';
import 'package:tec_app/features/floor_plan/presentation/floor_plan_screen.dart';
import 'package:tec_app/features/home/presentation/personalized_home_screen.dart';
import 'package:tec_app/features/location/presentation/location_screen.dart';
import 'package:tec_app/features/profile/presentation/profile_screen.dart';
import 'package:tec_app/features/schedule/presentation/schedule_screen.dart';
import 'package:tec_app/features/sessions/presentation/sessions_screen.dart';
import 'package:tec_app/navigation/main_scaffold.dart';

import 'package:tec_app/core/storage/token_storage.dart';
import 'package:tec_app/features/authentication/domain/auth_repository.dart';
import 'package:tec_app/features/authentication/domain/authenticated_user.dart';

import 'auth_repository_test.dart';

class MockAuthRepository implements AuthRepository {
  final TokenStorage tokenStorage;
  static const _mockProfile = UserProfile(
    id: 'USR-CDAC-1042',
    referenceNumber: '202611261042',
    officialName: 'Dr. Kishore Kumar',
    email: 'kishore@cdac.in',
    mobile: '9840123456',
    category: 'Central Government',
    organization: 'C-DAC Chennai',
    designation: 'Joint Director / Scientist F',
    attendanceDays: 'Both Days (26 & 27 Nov 2026)',
    interests: ['AI & Supercomputing', 'Cybersecurity'],
    registrationStatus: RegistrationStatus.approved,
  );

  MockAuthRepository({required this.tokenStorage});

  @override
  Future<AuthenticatedUser> login({required String identifier, required String password}) async {
    const tokens = AuthTokens(
      accessToken: 'test_access_token',
      refreshToken: 'test_refresh_token',
    );
    await tokenStorage.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
    await tokenStorage.saveUserCache(_mockProfile.toJson());
    return const AuthenticatedUser(tokens: tokens, profile: _mockProfile);
  }

  @override
  Future<UserProfile> getProfile({required String token}) async => _mockProfile;

  @override
  Future<void> logout({String? token}) async => tokenStorage.clearAll();

  @override
  Future<int> requestPasswordReset({required String identifier}) async => 0;

  @override
  Future<bool> verifyResetOtp({required String identifier, required String otp}) async => true;

  @override
  Future<UserProfile> updateInterests({required String token, required List<String> interests}) async => _mockProfile;

  @override
  Future<void> verifyResetOtpAndSetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
    String? confirmPassword,
  }) async {}
}

void main() {
  late SessionManager sessionManager;
  late AuthController authController;
  late DigitalPassController digitalPassController;

  setUp(() {
    final tokenStorage = MockTokenStorage();
    sessionManager = SessionManager(storage: tokenStorage);
    final apiClient = ApiClient();
    final authRepo = MockAuthRepository(tokenStorage: tokenStorage);
    final passRepo = DigitalPassRepositoryImpl(client: apiClient);

    authController = AuthController(repository: authRepo, sessionManager: sessionManager);
    digitalPassController = DigitalPassController(repository: passRepo);
  });

  Widget createWrapper(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionManager>.value(value: sessionManager),
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<DigitalPassController>.value(value: digitalPassController),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
        routes: {
          '/home': (_) => const MainScaffold(initialIndex: 0),
          '/schedule': (_) => const ScheduleScreen(),
          '/profile': (_) => const ProfileScreen(),
        },
      ),
    );
  }

  group('TEC-VERSE 2026 Premium UI & Zero-Overflow Tests', () {
    testWidgets('Home screen renders without overflow on 360px width phone', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWrapper(const PersonalizedHomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Title & Brand & Live Countdown
      expect(find.text('TEC-VERSE 2026'), findsWidgets);
      expect(find.text('DIGITAL EVENT PASS'), findsOneWidget);
      expect(find.byType(HeroLiveCountdownWidget), findsOneWidget);

      // Verify Quick Action Tiles exist without overflow
      expect(find.text('Schedule'), findsWidgets);
      expect(find.text('Floor Plan'), findsOneWidget);
      expect(find.text('Exhibitors'), findsNothing);

      // Verify CustomScrollView exists and has BouncingScrollPhysics
      final scrollViewFinder = find.byType(CustomScrollView);
      expect(scrollViewFinder, findsOneWidget);

      final CustomScrollView scrollView = tester.widget(scrollViewFinder);
      expect(scrollView.physics, isA<BouncingScrollPhysics>());

      // Test vertical drag scrolling to the bottom with zero overflow
      await tester.drag(scrollViewFinder, const Offset(0, -800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Latest News'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      expect(find.textContaining('Registrations Now Open'), findsOneWidget);
    });

    testWidgets('Home screen renders without overflow on standard mobile widths (375px, 390px, 412px, 430px)', (tester) async {
      for (final width in [375.0, 390.0, 412.0, 430.0]) {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createWrapper(const PersonalizedHomeScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('TEC-VERSE 2026'), findsWidgets);
        expect(find.text('DIGITAL EVENT PASS'), findsOneWidget);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('Home screen displays Event Location card for Chennai Trade Centre Nandambakkam with Google Maps directions', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWrapper(const PersonalizedHomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 1. Scroll to bring Event Location card into view
      final scrollView = find.byType(CustomScrollView);
      await tester.drag(scrollView, const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 2. Verify Event Location card header & badges
      expect(find.text('EVENT LOCATION'), findsOneWidget);
      expect(find.textContaining('Chennai Trade Centre'), findsWidgets);
      expect(find.textContaining('Nandambakkam'), findsWidgets);
      expect(find.textContaining('600089'), findsWidgets);

      // 3. Verify Google Maps primary action button and verify auxiliary buttons removed
      expect(find.text('Get Directions on Google Maps'), findsOneWidget);
      expect(find.text('Explore Routes'), findsNothing);
      expect(find.text('Copy'), findsNothing);
    });

    testWidgets('MainScaffold renders floating bottom navigation on mobile and switches tabs', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWrapper(const MainScaffold()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify floating bottom nav labels
      expect(find.text('Home'), findsWidgets);
      expect(find.text('About'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);
      expect(find.text('Explore'), findsNothing);

      // Tap About tab
      await tester.tap(find.text('About').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('MainScaffold renders navigation rail on desktop screens (>840px)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWrapper(const MainScaffold()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('2026 EXPO'), findsOneWidget);
      expect(find.text('NANDAMBAKKAM, TAMIL NADU 600089'), findsOneWidget);
    });

    testWidgets('Schedule screen displays date tabs, search, and filtered sessions', (tester) async {
      tester.view.physicalSize = const Size(1080, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWrapper(const ScheduleScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CONFERENCE PROGRAMME'), findsOneWidget);
      expect(find.text('DAY 01'), findsOneWidget);
      expect(find.text('DAY 02'), findsOneWidget);

      // Tap Day 2
      await tester.tap(find.text('DAY 02'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Registration'), findsWidgets);
    });

    testWidgets('Sessions screen displays complete technology domains, search, and thematic sessions', (tester) async {
      tester.view.physicalSize = const Size(1080, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWrapper(const SessionsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TECHNOLOGY SESSIONS'), findsOneWidget);
      expect(find.text('TECHNOLOGY DOMAINS'), findsOneWidget);
      expect(find.text('AI & Supercomputing'), findsWidgets);
      expect(find.text('Quantum Technologies'), findsWidgets);
      expect(find.text('Cybersecurity'), findsWidgets);

      // Verify search input
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'PARAM');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('PARAM Supercomputing Frontiers'), findsOneWidget);
    });

    testWidgets('Profile screen displays registration records and domain editing', (tester) async {
      tester.view.physicalSize = const Size(1080, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Pre-seed user in controller for profile display
      await authController.login(identifier: 'kishore@cdac.in', password: 'tecverse2026');

      await tester.pumpWidget(createWrapper(const ProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('Dr. Kishore Kumar'), findsOneWidget);
      expect(find.text('Reference No.'), findsOneWidget);
      expect(find.text('SIGN OUT OF TEC-VERSE'), findsOneWidget);
    });

    testWidgets('FloorPlanScreen renders header, tech zones, and interactive map controls', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWrapper(const FloorPlanScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 1. Verify Top Header per requirement
      expect(find.text('Floor Plan'), findsOneWidget);
      expect(find.text('Nandambakkam, Tamil Nadu 600089'), findsOneWidget);
      expect(find.text('CTC'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);

      // 2. Verify Technology Zones filter chips
      expect(find.text('All Zones'), findsOneWidget);
      expect(find.text('AI & Supercomputing'), findsOneWidget);

      // 3. Verify Interactive Map Controls
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.legend_toggle_rounded), findsOneWidget);

      // 4. Test tapping Download opens official status dialog
      await tester.tap(find.text('Download'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('OFFICIAL FLOOR PLAN'), findsOneWidget);
      expect(find.text('Official floor plan will be available soon.'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 5. Test Legend Sheet opens
      await tester.tap(find.byIcon(Icons.legend_toggle_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('FLOOR PLAN LEGEND'), findsOneWidget);
      await tester.tap(find.text('DISMISS LEGEND'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 6. Test Search Sheet opens
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Search halls'), findsOneWidget);
      expect(find.textContaining('RESULTS ('), findsOneWidget);
    });

    testWidgets('LocationScreen renders destination, 4 transport modes, route info, and action buttons', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWrapper(const LocationScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 1. Verify Header
      expect(find.text('Event Location'), findsOneWidget);
      expect(find.textContaining('Chennai Trade Centre'), findsWidgets);
      expect(find.text('TAMIL NADU'), findsOneWidget);

      // 2. Verify 4 Transport Modes icons
      expect(find.byIcon(Icons.directions_car_rounded), findsWidgets);
      expect(find.byIcon(Icons.two_wheeler_rounded), findsOneWidget);
      expect(find.byIcon(Icons.directions_subway_rounded), findsOneWidget);
      expect(find.byIcon(Icons.directions_walk_rounded), findsOneWidget);

      // 3. Verify Bottom Venue Card & buttons
      expect(find.text('CONFIRMED VENUE'), findsOneWidget);
      expect(find.text('Get Directions'), findsOneWidget);
      expect(find.text('Google Maps'), findsOneWidget);

      // 4. Test Switching Transport Modes (tap Two-Wheeler)
      await tester.tap(find.byIcon(Icons.two_wheeler_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 5. Test opening Manual Origin picker dialog
      await tester.tap(find.byIcon(Icons.edit_location_alt_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('SELECT STARTING LOCATION'), findsOneWidget);
      expect(find.text('Chennai International Airport (MAA)'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('Home screen Latest News cards display important dates and open details & See All modal', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWrapper(const PersonalizedHomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final scrollView = find.byType(CustomScrollView);
      await tester.drag(scrollView, const Offset(0, -900));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify Latest News heading and See All
      expect(find.text('Latest News'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);

      // 2. Verify Important Dates content
      expect(find.textContaining('Registrations Now Open'), findsOneWidget);
      expect(find.textContaining('Call for Research Papers'), findsOneWidget);

      // 3. Tap card opens detail sheet
      await tester.tap(find.textContaining('Registrations Now Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Visit Official Portal'), findsOneWidget);

      // Close detail sheet
      await tester.tapAt(const Offset(20, 20));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 4. Tap See All opens full modal
      await tester.tap(find.text('See All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Latest News & Dates'), findsOneWidget);
    });

    testWidgets('Home screen notification bell opens notifications modal sheet', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWrapper(const PersonalizedHomeScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap notification bell icon in top bar
      final notifIcon = find.byIcon(Icons.notifications_outlined);
      expect(notifIcon, findsOneWidget);
      await tester.tap(notifIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify notifications sheet opened
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.textContaining('Digital Pass Activated'), findsOneWidget);
    });
  });
}
