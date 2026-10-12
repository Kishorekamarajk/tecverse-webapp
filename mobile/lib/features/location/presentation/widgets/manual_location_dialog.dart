import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/location_models.dart';
import '../../data/venue_location_data.dart';

class ManualLocationDialog extends StatefulWidget {
  final GeoLocation? currentSelected;
  final ValueChanged<GeoLocation> onLocationSelected;

  const ManualLocationDialog({
    super.key,
    this.currentSelected,
    required this.onLocationSelected,
  });

  static void show({
    required BuildContext context,
    GeoLocation? currentSelected,
    required ValueChanged<GeoLocation> onLocationSelected,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => ManualLocationDialog(
        currentSelected: currentSelected,
        onLocationSelected: onLocationSelected,
      ),
    );
  }

  @override
  State<ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<ManualLocationDialog> {
  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderCard),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cyanAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.my_location_rounded, color: AppColors.cyanAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECT STARTING LOCATION',
                          style: AppTypography.headlineMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          'Choose your origin to calculate route & time',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 14),

              Text(
                'POPULAR CHENNAI ARRIVAL HUBS',
                style: AppTypography.metaTag.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: VenueLocationData.popularOrigins.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final origin = VenueLocationData.popularOrigins[index];
                    final isSelected = widget.currentSelected?.name == origin.name;
                    final dist = origin.distanceTo(VenueLocationData.venue.location);

                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onLocationSelected(origin);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.cyanAccent.withValues(alpha: 0.12) : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.cyanAccent : AppColors.borderSubtle,
                            width: isSelected ? 1.0 : 0.6,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              origin.name.contains('Airport')
                                  ? Icons.flight_rounded
                                  : origin.name.contains('Metro') || origin.name.contains('Railway')
                                      ? Icons.train_rounded
                                      : origin.name.contains('Bus')
                                          ? Icons.directions_bus_rounded
                                          : Icons.place_outlined,
                              color: isSelected ? AppColors.cyanAccent : AppColors.textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                origin.name,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(dist * 1.28).toStringAsFixed(1)} km',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: isSelected ? AppColors.cyanAccent : AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // Custom origin field
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: TextField(
                        controller: _customController,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter area or hotel (e.g. Porur, Guindy)',
                          hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                          prefixIcon: const Icon(Icons.edit_location_alt_rounded, size: 16, color: AppColors.cyanAccent),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final text = _customController.text.trim();
                      if (text.isNotEmpty) {
                        Navigator.of(context).pop();
                        // Use simulated coordinates near the entered area
                        widget.onLocationSelected(GeoLocation(
                          name: text,
                          latitude: 13.030000,
                          longitude: 80.180000,
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyanAccent,
                      foregroundColor: const Color(0xFF030712),
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Set', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
