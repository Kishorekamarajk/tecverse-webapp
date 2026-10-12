import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/venue_models.dart';

class HallDetailsSheet extends StatelessWidget {
  final Hall hall;
  final VoidCallback onNavigateHere;
  final VoidCallback onShowSessions;

  const HallDetailsSheet({
    super.key,
    required this.hall,
    required this.onNavigateHere,
    required this.onShowSessions,
  });

  static void show({
    required BuildContext context,
    required Hall hall,
    required VoidCallback onNavigateHere,
    required VoidCallback onShowSessions,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => HallDetailsSheet(
        hall: hall,
        onNavigateHere: onNavigateHere,
        onShowSessions: onShowSessions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(color: AppColors.borderCard),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderCard,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Hall Title & Number badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: hall.accentColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: hall.accentColor.withValues(alpha: 0.6), width: 1.2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        hall.number,
                        style: TextStyle(
                          color: hall.accentColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hall.name,
                            style: AppTypography.headlineMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hall.subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.borderSubtle),
                const SizedBox(height: 14),

                // Technology Focus Zones
                Text(
                  'TECHNOLOGY FOCUS',
                  style: AppTypography.metaTag.copyWith(
                    fontSize: 10.5,
                    color: AppColors.cyanAccent,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: hall.zones.map((zone) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: zone.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: zone.color.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: zone.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            zone.name,
                            style: TextStyle(
                              color: zone.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Nearby Facilities
                Text(
                  'NEARBY FACILITIES',
                  style: AppTypography.metaTag.copyWith(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: hall.nearbyFacilities.map((fac) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me_outlined, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 5),
                          Text(
                            fac,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Primary Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onNavigateHere();
                    },
                    icon: const Icon(Icons.navigation_rounded, size: 16),
                    label: const Text('Show Route', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyanAccent,
                      foregroundColor: const Color(0xFF030712),
                      elevation: 0,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onShowSessions();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.cyanAccent,
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  child: const Text('Show Sessions at This Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
