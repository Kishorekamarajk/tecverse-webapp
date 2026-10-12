import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/floor_plan_data.dart';

class DownloadFloorPlanDialog extends StatefulWidget {
  const DownloadFloorPlanDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const DownloadFloorPlanDialog(),
    );
  }

  @override
  State<DownloadFloorPlanDialog> createState() => _DownloadFloorPlanDialogState();
}

class _DownloadFloorPlanDialogState extends State<DownloadFloorPlanDialog> {
  bool _isOfflineCached = true;
  bool _isNotifiedOnPublish = false;

  @override
  Widget build(BuildContext context) {
    final hasOfficialPdf = FloorPlanData.officialFloorPlanUrl != null ||
        FloorPlanData.officialFloorPlanAsset != null;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyanAccent.withValues(alpha: 0.1),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with official badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cyanAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.cyanAccent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OFFICIAL FLOOR PLAN',
                          style: AppTypography.headlineMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Nandambakkam, Tamil Nadu 600089',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 16),

              if (hasOfficialPdf) ...[
                // Official PDF is configured and ready
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.emeraldSuccess, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Official PDF Available', style: AppTypography.headlineMedium.copyWith(fontSize: 13)),
                            Text('High-resolution architectural layout (6.4 MB)', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Downloading official floor plan for Nandambakkam, Tamil Nadu 600089...'),
                        backgroundColor: AppColors.surfaceElevated,
                      ),
                    );
                  },
                  icon: const Icon(Icons.file_download_rounded),
                  label: const Text('Download Official PDF', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyanAccent,
                    foregroundColor: const Color(0xFF030712),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else ...[
                // Status Placeholder: No official PDF released yet
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PENDING ORGANIZER RELEASE',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Official floor plan will be available soon.',
                        style: AppTypography.headlineMedium.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'The final MeitY and CTC exhibition layout document is undergoing final validation. Once released by event directors, the downloadable architectural blueprint will appear here automatically.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Offline caching status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.offline_pin_rounded, color: AppColors.cyanAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Digital Interactive Map Cached',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Full offline venue navigation is active and ready.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isOfflineCached,
                        activeThumbColor: AppColors.cyanAccent,
                        onChanged: (val) {
                          setState(() => _isOfflineCached = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val
                                  ? 'Venue map cached for offline access.'
                                  : 'Offline map cache cleared.'),
                              backgroundColor: AppColors.surfaceElevated,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _isNotifiedOnPublish = !_isNotifiedOnPublish);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isNotifiedOnPublish
                                  ? 'You will be notified when the official PDF is published.'
                                  : 'Notification preference updated.'),
                              backgroundColor: AppColors.surfaceElevated,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: Icon(
                          _isNotifiedOnPublish ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                          size: 16,
                          color: _isNotifiedOnPublish ? AppColors.cyanAccent : AppColors.textPrimary,
                        ),
                        label: Text(
                          _isNotifiedOnPublish ? 'Notified' : 'Notify Me',
                          style: TextStyle(
                            color: _isNotifiedOnPublish ? AppColors.cyanAccent : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: _isNotifiedOnPublish ? AppColors.cyanAccent : AppColors.borderCard,
                          ),
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: AppColors.borderCard),
                        ),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
