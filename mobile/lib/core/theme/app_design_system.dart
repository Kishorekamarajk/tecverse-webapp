import 'package:flutter/material.dart';

/// Centralized Spacing System for TEC-VERSE 2026.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  static const EdgeInsets screenPaddingMobile = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets screenPaddingDesktop = EdgeInsets.symmetric(horizontal: 36, vertical: 24);
}

/// Centralized Border Radius Tokens.
class AppRadius {
  AppRadius._();

  static const double xs = 6.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double round = 999.0;

  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get credential => BorderRadius.circular(xl);
  static BorderRadius get button => BorderRadius.circular(md);
  static BorderRadius get pill => BorderRadius.circular(sm);
}

/// Centralized Soft Elevation & Shadows (light-theme, soft navy tones).
class AppShadows {
  AppShadows._();

  /// Subtle drop shadow for content cards.
  static List<BoxShadow> get subtleCard => [
        BoxShadow(
          color: const Color(0xFF102A43).withValues(alpha: 0.07),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: const Color(0xFF102A43).withValues(alpha: 0.04),
          blurRadius: 4,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];

  /// Deeper shadow for modals, bottom sheets, and dialogs.
  static List<BoxShadow> get elevatedModal => [
        BoxShadow(
          color: const Color(0xFF102A43).withValues(alpha: 0.12),
          blurRadius: 32,
          spreadRadius: 0,
          offset: const Offset(0, 10),
        ),
      ];

  /// Upward shadow for bottom navigation bars.
  static List<BoxShadow> get bottomNav => [
        BoxShadow(
          color: const Color(0xFF102A43).withValues(alpha: 0.06),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, -2),
        ),
      ];
}

/// Centralized Motion & Animation Durations.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration entrance = Duration(milliseconds: 650);

  static const Curve defaultCurve = Curves.easeOutCubic;
}
