import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Organizing Institutions Branding Card (C-DAC • SAMEER • C-MET).
/// Displayed prominently on the Home Screen before the Event Location card.
class OrganizingInstitutionsCard extends StatelessWidget {
  const OrganizingInstitutionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderCard,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.04),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'ORGANIZED BY',
                style: AppTypography.metaTag.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.cyanAccent,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Three Logos Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.7)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/organized_by_logos.png',
                height: 68,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _fallbackLogosRow(),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Label under logos
          Center(
            child: Text(
              'C-DAC  •  SAMEER  •  C-MET',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackLogosRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _logoBadge('C-DAC', const Color(0xFF102A43)),
        _logoBadge('SAMEER', const Color(0xFF0284C7)),
        _logoBadge('C-MET', const Color(0xFF1E40AF)),
      ],
    );
  }

  Widget _logoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
