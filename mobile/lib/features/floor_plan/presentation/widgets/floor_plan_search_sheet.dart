import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/venue_models.dart';
import '../../data/floor_plan_data.dart';

enum SearchResultType { hall, facility, zone }

class SearchResultItem {
  final SearchResultType type;
  final String title;
  final String subtitle;
  final String tag;
  final String? hallId;
  final Offset coordinates;
  final Color accentColor;

  const SearchResultItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.tag,
    this.hallId,
    required this.coordinates,
    this.accentColor = const Color(0xFF00F2FE),
  });
}

class FloorPlanSearchSheet extends StatefulWidget {
  final ValueChanged<SearchResultItem> onSelectTarget;

  const FloorPlanSearchSheet({
    super.key,
    required this.onSelectTarget,
  });

  static void show({
    required BuildContext context,
    required ValueChanged<SearchResultItem> onSelectTarget,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FloorPlanSearchSheet(onSelectTarget: onSelectTarget),
    );
  }

  @override
  State<FloorPlanSearchSheet> createState() => _FloorPlanSearchSheetState();
}

class _FloorPlanSearchSheetState extends State<FloorPlanSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<SearchResultItem> _computeResults() {
    final query = _query.trim().toLowerCase();
    final results = <SearchResultItem>[];

    // 2. Search Halls
    for (final hall in FloorPlanData.allHalls) {
      if (query.isEmpty ||
          hall.name.toLowerCase().contains(query) ||
          hall.number.toLowerCase().contains(query) ||
          hall.subtitle.toLowerCase().contains(query)) {
        results.add(SearchResultItem(
          type: SearchResultType.hall,
          title: hall.name,
          subtitle: hall.subtitle,
          tag: 'Hall ${hall.number}',
          hallId: hall.id,
          coordinates: hall.center,
          accentColor: hall.accentColor,
        ));
      }
    }

    // 3. Search Facilities
    for (final fac in FloorPlanData.allFacilities) {
      if (query.isEmpty ||
          fac.name.toLowerCase().contains(query) ||
          fac.type.displayName.toLowerCase().contains(query) ||
          fac.description.toLowerCase().contains(query)) {
        results.add(SearchResultItem(
          type: SearchResultType.facility,
          title: fac.name,
          subtitle: fac.description,
          tag: fac.type.displayName,
          coordinates: fac.position,
          accentColor: fac.type.color,
        ));
      }
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final results = _computeResults();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.78,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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

              // Search Bar Field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (val) => setState(() => _query = val),
                  decoration: InputDecoration(
                    hintText: 'Search halls, zones, or facilities...',
                    hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.cyanAccent, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Suggestion chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _filterChip('AI'),
                    const SizedBox(width: 6),
                    _filterChip('Robotics'),
                    const SizedBox(width: 6),
                    _filterChip('Quantum'),
                    const SizedBox(width: 6),
                    _filterChip('Hall 1'),
                    const SizedBox(width: 6),
                    _filterChip('Hall 2'),
                    const SizedBox(width: 6),
                    _filterChip('Food Court'),
                    const SizedBox(width: 6),
                    _filterChip('Semiconductor'),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 8),

              // Results Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RESULTS (${results.length})',
                    style: AppTypography.metaTag.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (_query.isNotEmpty)
                    Text(
                      'Filtering for "$_query"',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.cyanAccent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Results List
              Expanded(
                child: results.isNotEmpty
                    ? ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: item.accentColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: item.accentColor.withValues(alpha: 0.4)),
                                  ),
                                  child: Icon(
                                    item.type == SearchResultType.hall
                                        ? Icons.domain_rounded
                                        : Icons.place_rounded,
                                    color: item.accentColor,
                                    size: 18,
                                  ),
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle,
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
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    widget.onSelectTarget(item);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.cyanAccent.withValues(alpha: 0.15),
                                    foregroundColor: AppColors.cyanAccent,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: AppColors.cyanAccent, width: 0.8),
                                    ),
                                  ),
                                  child: const Text('Show on Map', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              'No matching location found',
                              style: AppTypography.headlineMedium.copyWith(fontSize: 14, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try searching for "Hall 1", "AI", or "C-DAC"',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    return InkWell(
      onTap: () {
        _controller.text = label;
        setState(() => _query = label);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 11,
            color: AppColors.cyanAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
