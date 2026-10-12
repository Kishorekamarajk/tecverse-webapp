import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized Inter Typography for TEC-VERSE 2026.
/// Apple-level typographic clarity, strong hierarchy, and restrained uppercase usage.
class AppTypography {
  AppTypography._();

  // Displays (Hero & Major Titles)
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  // Headlines
  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  // Body
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: AppColors.textPrimary,
        height: 1.45,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: AppColors.textSecondary,
        height: 1.45,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // Labels & Small Upper/Tags
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get metaTag => GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.cyanAccent,
      );

  // Monospace (Reserved for Digital Pass ID and Registration Codes)
  static TextStyle get monoCode => GoogleFonts.spaceMono(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.cyanAccent,
      );
}
