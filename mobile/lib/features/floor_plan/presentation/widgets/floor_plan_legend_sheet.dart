import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/venue_models.dart';

class FloorPlanLegendSheet extends StatelessWidget {
  const FloorPlanLegendSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const FloorPlanLegendSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final legendItems = [
      _LegendEntry(
        icon: Icons.domain_rounded,
        color: const Color(0xFF0A84FF),
        title: 'Exhibition Hall',
        description: 'Halls 1 to 8 housing 80+ technology booths and live demonstrations.',
      ),
      _LegendEntry(
        icon: Icons.campaign_rounded,
        color: const Color(0xFF00F2FE),
        title: 'Conference Hall',
        description: 'Plenary and breakout halls for keynotes, workshops, and panels.',
      ),
      _LegendEntry(
        icon: Icons.layers_rounded,
        color: const Color(0xFFA855F7),
        title: 'Technology Zone',
        description: 'Color-coded domains (AI, Quantum, Semiconductors, Cyber, etc.).',
      ),
      _LegendEntry(
        icon: FacilityType.registrationDesk.icon,
        color: FacilityType.registrationDesk.color,
        title: 'Registration Desk',
        description: 'QR credential validation and delegate badge collection counters.',
      ),
      _LegendEntry(
        icon: FacilityType.foodCourt.icon,
        color: FacilityType.foodCourt.color,
        title: 'Food Court / Cafeteria',
        description: 'North and South concourse dining areas and espresso bars.',
      ),
      _LegendEntry(
        icon: FacilityType.restroom.icon,
        color: FacilityType.restroom.color,
        title: 'Restrooms',
        description: 'Wheelchair-accessible washroom facilities throughout all halls.',
      ),
      _LegendEntry(
        icon: FacilityType.emergencyExit.icon,
        color: FacilityType.emergencyExit.color,
        title: 'Emergency Exit',
        description: 'Egress paths leading immediately to open-air assembly points.',
      ),
      _LegendEntry(
        icon: FacilityType.infoDesk.icon,
        color: FacilityType.infoDesk.color,
        title: 'Information Desk',
        description: 'Central help desk, venue guides, and translation assistance.',
      ),
      _LegendEntry(
        icon: Icons.my_location_rounded,
        color: const Color(0xFF00F2FE),
        title: 'Current Location',
        description: 'Your live estimated beacon inside the CTC concourse.',
      ),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.borderCard),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderCard,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cyanAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.legend_toggle_rounded, color: AppColors.cyanAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FLOOR PLAN LEGEND',
                            style: AppTypography.headlineMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Map symbols, icons & zones at Nandambakkam, Tamil Nadu 600089',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.borderSubtle),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: legendItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = legendItems[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: item.color.withValues(alpha: 0.4)),
                            ),
                            child: Icon(item.icon, color: item.color, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: AppTypography.headlineMedium.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.description,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceElevated,
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.borderCard),
                  ),
                  child: const Text('DISMISS LEGEND', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendEntry {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _LegendEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}
