import 'package:flutter/material.dart';

/// TEC-VERSE 2026 Premium Exhibition Color System.
/// Light lavender base, orange primary, green secondary, dark navy accent.
class AppColors {
  AppColors._();

  // ─── Background & Surface ───────────────────────────────────────────────────
  /// Very light lavender page background.
  static const Color background = Color(0xFFF7F6FC);

  /// Slightly deeper lavender — used for elevated surfaces / sheet backgrounds.
  static const Color backgroundSecondary = Color(0xFFEFEEFA);

  /// White card / dialog surface.
  static const Color surface = Color(0xFFFFFFFF);

  /// Slightly elevated white — used for input fields and inner containers.
  static const Color surfaceElevated = Color(0xFFF1F0FA);

  /// White card surface (alias kept for widget compatibility).
  static const Color surfaceCard = Color(0xFFFFFFFF);

  /// Light lavender — section fills, selected chip backgrounds.
  static const Color lightLavender = Color(0xFFEFEEFA);

  // ─── Borders & Dividers ─────────────────────────────────────────────────────
  /// Very subtle border for cards and containers.
  static const Color borderSubtle = Color(0xFFE5E7EB);

  /// Standard card border.
  static const Color borderCard = Color(0xFFE5E7EB);

  /// Focused element border (orange).
  static const Color borderFocused = Color(0xFFFF6B1A);

  /// Slightly stronger divider (used in dense lists).
  static const Color borderGlow = Color(0xFFD1D5DB);

  // ─── Primary Accent — Orange ─────────────────────────────────────────────────
  static const Color primaryOrange = Color(0xFFFF6B1A);

  /// Lighter orange for soft highlights.
  static const Color primaryOrangeLight = Color(0xFFFF8A4C);

  /// Dark pressed orange.
  static const Color primaryOrangeDark = Color(0xFFE55A0D);

  /// Requested Sign Out button orange (#FF7200).
  static const Color signoutOrange = Color(0xFFFF7200);

  /// Backward-compatibility alias used throughout existing widgets.
  static const Color cyanAccent = Color(0xFFFF6B1A);
  static const Color cyanLight = Color(0xFFFF8A4C);
  static const Color bluePrimary = Color(0xFF102A43);

  // ─── Secondary Accent — Green ────────────────────────────────────────────────
  static const Color secondaryGreen = Color(0xFF20A67A);
  static const Color emeraldSuccess = Color(0xFF20A67A);

  // ─── Tertiary / Text Accent — Dark Navy ─────────────────────────────────────
  static const Color darkNavy = Color(0xFF102A43);
  static const Color primaryNavy = Color(0xFF102A43);
  static const Color indigoAccent = Color(0xFF2D4A6B);

  // ─── Semantic ───────────────────────────────────────────────────────────────
  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color crimsonError = Color(0xFFEF4444);

  // ─── Typography ─────────────────────────────────────────────────────────────
  /// Dark navy — primary headings and important content.
  static const Color textPrimary = Color(0xFF0F172A);

  /// Deep slate/navy — secondary captions and supporting text (high contrast & crisp).
  static const Color textSecondary = Color(0xFF334155);

  /// Medium slate — labels, metadata, and hints (clearly visible and legible).
  static const Color textMuted = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF64748B);

  /// Text placed on colored (orange/green) backgrounds.
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ─── Status ─────────────────────────────────────────────────────────────────
  static const Color statusActive = Color(0xFF20A67A);
  static const Color statusUsed = Color(0xFF9CA3AF);
  static const Color statusRevoked = Color(0xFFEF4444);
  static const Color statusPending = Color(0xFFF59E0B);

  // ─── Glassmorphism / Hover tokens ───────────────────────────────────────────
  static Color get glassFill => const Color(0xFFFFFFFF).withValues(alpha: 0.80);
  static Color get glassBorder => const Color(0xFFE5E7EB).withValues(alpha: 0.85);
  static Color get glowCyan => const Color(0xFFFF6B1A).withValues(alpha: 0.10);
  static Color get glowIndigo => const Color(0xFF102A43).withValues(alpha: 0.06);
  static Color get glowBlue => const Color(0xFF20A67A).withValues(alpha: 0.08);

  // ─── Gradients ──────────────────────────────────────────────────────────────

  /// Orange → amber: primary CTA gradient.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B1A), Color(0xFFE55A0D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft lavender hero gradient — page header fills.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [
      Color(0xFFEFEEFA),
      Color(0xFFF7F6FC),
      Color(0xFFFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle white-to-lavender card gradient.
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F6FC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Digital pass executive gradient — white with very soft lavender tint.
  static const LinearGradient passCredentialGradient = LinearGradient(
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF7F6FC),
      Color(0xFFEFEEFA),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft orange glow for focus states and selection highlights.
  static const LinearGradient accentGlowGradient = LinearGradient(
    colors: [
      Color(0x26FF6B1A), // orange 15%
      Color(0x1020A67A), // green 6%
      Color(0x00F7F6FC),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 3-color accent bar gradient: orange → green → navy.
  static const LinearGradient accentBarGradient = LinearGradient(
    colors: [
      Color(0xFFFF6B1A), // orange
      Color(0xFF20A67A), // green
      Color(0xFF102A43), // navy
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
