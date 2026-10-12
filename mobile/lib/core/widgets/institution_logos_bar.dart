import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Institutional & Scientific Consortium Branding Bar
///
/// Layout:
/// - Consortium of scientific societies (CSC)
/// - MeitY
/// - C-DAC  SAMEER  C-MET
/// - Connect. Collaborate. Innovate
class InstitutionLogosBar extends StatelessWidget {
  final bool compact;

  const InstitutionLogosBar({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Consortium of scientific societies (CSC)
        Text(
          'Consortium of scientific societies (CSC)',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            fontSize: compact ? 12 : 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),

        // 2. MeitY
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          child: Text(
            'MeitY',
            style: AppTypography.labelLarge.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFB45309),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 3. C-DAC  SAMEER  CMET Badges
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: const [
            _InstitutionBadge(
              code: 'C-DAC',
              accentColor: AppColors.primaryOrange,
            ),
            _InstitutionBadge(
              code: 'SAMEER',
              accentColor: Color(0xFF6366F1),
            ),
            _InstitutionBadge(
              code: 'CMET',
              accentColor: Color(0xFF10B981),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 4. Connect. Collaborate. Innovate
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.borderSubtle,
              width: 0.9,
            ),
          ),
          child: Text(
            'Connect. Collaborate. Innovate',
            style: AppTypography.bodySmall.copyWith(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.primaryOrange,
            ),
          ),
        ),
      ],
    );
  }
}

class _InstitutionBadge extends StatelessWidget {
  final String code;
  final Color accentColor;

  const _InstitutionBadge({
    required this.code,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.45),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            code,
            style: AppTypography.labelLarge.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
