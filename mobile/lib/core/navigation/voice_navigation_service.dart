import 'package:flutter/material.dart';
import '../../features/about/presentation/about_screen.dart';
import '../../features/digital_pass/presentation/digital_pass_screen.dart';
import '../../features/floor_plan/presentation/floor_plan_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/sessions/presentation/sessions_screen.dart';
import '../../navigation/app_router.dart';

/// Global Navigation Service capable of executing hands-free Voice Navigation
/// ("Go to...", "Open...", "Show...", "Navigate to...") across the entire app.
class VoiceNavigationService {
  VoiceNavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Global callback to switch tabs on [MainScaffold] when active
  static Function(int tabIndex)? onTabChangeRequested;

  /// Global callback to check if robot overlay is hidden
  static ValueNotifier<bool> isRobotVisible = ValueNotifier<bool>(true);

  /// Parse user speech or text to determine if it is a Navigation command.
  /// Returns a result map with `isNavigation`, `destinationName`, and `feedbackMessage`.
  static VoiceNavResult evaluateNavigationIntent(String query) {
    final lower = query.toLowerCase().trim();

    // Check for navigation trigger words
    final isNavTrigger = lower.startsWith('go to') ||
        lower.startsWith('goto') ||
        lower.startsWith('open') ||
        lower.startsWith('show') ||
        lower.startsWith('take me to') ||
        lower.startsWith('navigate to') ||
        lower.startsWith('launch') ||
        lower.startsWith('switch to');

    // 1. Digital Pass / Ticket / QR
    if (lower.contains('pass') ||
        lower.contains('ticket') ||
        lower.contains('qr code') ||
        lower.contains('badge') ||
        lower.contains('digital pass') ||
        lower.contains('my pass')) {
      return VoiceNavResult(
        isNavigation: true,
        destination: VoiceNavDestination.digitalPass,
        destinationName: 'Digital Pass',
        feedbackMessage: '🚀 Opening your Encrypted Digital Pass...',
        action: (context) => navigateTo(VoiceNavDestination.digitalPass),
      );
    }

    // 2. Floor Plan / Venue Map / Hall navigation
    if (lower.contains('floor plan') ||
        lower.contains('floorplan') ||
        lower.contains('hall') ||
        lower.contains('map') ||
        lower.contains('venue') ||
        lower.contains('location') ||
        lower.contains('wayfinding') ||
        lower.contains('stall') ||
        lower.contains('where is')) {
      
      String? hallId;
      for (int i = 1; i <= 8; i++) {
        if (lower.contains('hall $i') || lower.contains('hall$i')) {
          hallId = 'hall-$i';
          break;
        }
      }

      final hallName = hallId != null ? 'Hall ${hallId.split('-').last}' : 'Floor Plan';
      return VoiceNavResult(
        isNavigation: true,
        destination: VoiceNavDestination.floorPlan,
        destinationName: 'Venue Floor Plan',
        feedbackMessage: '🗺️ Navigating to $hallName at Chennai Trade Centre...',
        action: (context) => navigateTo(VoiceNavDestination.floorPlan, targetId: hallId),
      );
    }

    // 3. Sessions / Thematic Tracks
    if (lower.contains('session') ||
        lower.contains('tracks') ||
        lower.contains('quantum') ||
        lower.contains('semiconductor') ||
        lower.contains('vlsi') ||
        lower.contains('generative ai') ||
        lower.contains('thematic') ||
        lower.contains('cybersecurity') ||
        lower.contains('robotics')) {
      return VoiceNavResult(
        isNavigation: true,
        destination: VoiceNavDestination.sessions,
        destinationName: 'Thematic Sessions',
        feedbackMessage: '🔬 Navigating to Thematic Sessions & Technology Tracks...',
        action: (context) => navigateTo(VoiceNavDestination.sessions),
      );
    }

    // 4. Schedule / Agenda / Timetable
    if (lower.contains('schedule') ||
        lower.contains('agenda') ||
        lower.contains('timeline') ||
        lower.contains('calendar') ||
        lower.contains('events today') ||
        lower.contains('day 1') ||
        lower.contains('day 2') ||
        lower.contains('timetable')) {
      return VoiceNavResult(
        isNavigation: true,
        destination: VoiceNavDestination.schedule,
        destinationName: 'Event Schedule',
        feedbackMessage: '📅 Opening 26–27 Nov 2026 Event Schedule & Agenda...',
        action: (context) => navigateTo(VoiceNavDestination.schedule),
      );
    }

    // 5. About / Conclave / Organisers
    if (lower.contains('about') ||
        lower.contains('organise') ||
        lower.contains('organize') ||
        lower.contains('cdac') ||
        lower.contains('sameer') ||
        lower.contains('cmet') ||
        lower.contains('conclave') ||
        lower.contains('shaping tomorrow')) {
      return VoiceNavResult(
        isNavigation: true,
        destination: VoiceNavDestination.about,
        destinationName: 'About TEC-VERSE',
        feedbackMessage: 'ℹ️ Opening About TEC-VERSE & Organisers...',
        action: (context) => navigateTo(VoiceNavDestination.about),
      );
    }

    // 6. Profile / Account / Settings / Interests
    if (lower.contains('profile') ||
        lower.contains('account') ||
        lower.contains('interest') ||
        lower.contains('settings') ||
        lower.contains('my details')) {
      return VoiceNavResult(
        isNavigation: true,
        destination: VoiceNavDestination.profile,
        destinationName: 'Profile',
        feedbackMessage: '👤 Opening your Delegate Profile & Preferences...',
        action: (context) => navigateTo(VoiceNavDestination.profile),
      );
    }

    // 6. Home / Dashboard
    if (lower.contains('home') ||
        lower.contains('main screen') ||
        lower.contains('dashboard') ||
        lower.contains('back to home')) {
      return VoiceNavResult(
        isNavigation: true,
        destination: VoiceNavDestination.home,
        destinationName: 'Home',
        feedbackMessage: '🏠 Taking you to the Home Dashboard...',
        action: (context) => navigateTo(VoiceNavDestination.home),
      );
    }

    // 7. Login / Logout
    if (lower.contains('login') || lower.contains('sign in') || lower.contains('logout')) {
      return VoiceNavResult(
        isNavigation: true,
        destination: VoiceNavDestination.login,
        destinationName: 'Login',
        feedbackMessage: '🔐 Navigating to Login Screen...',
        action: (context) => navigateTo(VoiceNavDestination.login),
      );
    }

    // Fallback if generic navigation phrase is used without matching destination
    if (isNavTrigger) {
      return VoiceNavResult(
        isNavigation: false,
        destinationName: '',
        feedbackMessage: '🤖 Which screen would you like to visit? You can say "Go to Home", "Go to Sessions", "Go to Schedule", "Go to Digital Pass", or "Go to Floor Plan".',
      );
    }

    return VoiceNavResult(isNavigation: false);
  }

  /// Execute navigation to a specific destination
  static void navigateTo(VoiceNavDestination destination, {String? targetId}) {
    final navState = navigatorKey.currentState;
    if (navState == null) return;

    switch (destination) {
      case VoiceNavDestination.home:
        navState.popUntil((route) => route.isFirst);
        if (onTabChangeRequested != null) {
          onTabChangeRequested!(0);
        } else {
          navState.pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
        }
        break;

      case VoiceNavDestination.sessions:
        navState.popUntil((route) => route.isFirst);
        if (onTabChangeRequested != null) {
          onTabChangeRequested!(1);
        } else {
          navState.push(MaterialPageRoute(builder: (_) => const SessionsScreen()));
        }
        break;

      case VoiceNavDestination.schedule:
        navState.popUntil((route) => route.isFirst);
        if (onTabChangeRequested != null) {
          onTabChangeRequested!(2);
        } else {
          navState.push(MaterialPageRoute(builder: (_) => const ScheduleScreen()));
        }
        break;

      case VoiceNavDestination.digitalPass:
        navState.popUntil((route) => route.isFirst);
        if (onTabChangeRequested != null) {
          onTabChangeRequested!(3);
        } else {
          navState.push(MaterialPageRoute(builder: (_) => const DigitalPassScreen()));
        }
        break;

      case VoiceNavDestination.about:
        navState.popUntil((route) => route.isFirst);
        if (onTabChangeRequested != null) {
          onTabChangeRequested!(4);
        } else {
          navState.push(MaterialPageRoute(builder: (_) => const AboutScreen()));
        }
        break;

      case VoiceNavDestination.profile:
        navState.popUntil((route) => route.isFirst);
        if (onTabChangeRequested != null) {
          onTabChangeRequested!(5);
        } else {
          navState.push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
        }
        break;

      case VoiceNavDestination.floorPlan:
        navState.push(
          MaterialPageRoute(
            builder: (_) => FloorPlanScreen(initialHallId: targetId),
          ),
        );
        break;

      case VoiceNavDestination.login:
        navState.pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
        break;
    }
  }
}

enum VoiceNavDestination {
  home,
  sessions,
  schedule,
  digitalPass,
  about,
  profile,
  floorPlan,
  login,
}

class VoiceNavResult {
  final bool isNavigation;
  final VoiceNavDestination? destination;
  final String destinationName;
  final String feedbackMessage;
  final Function(BuildContext context)? action;

  VoiceNavResult({
    required this.isNavigation,
    this.destination,
    this.destinationName = '',
    this.feedbackMessage = '',
    this.action,
  });
}
