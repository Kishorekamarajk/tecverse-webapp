// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animation_utils.dart';
import '../../schedule/presentation/schedule_screen.dart';
import '../domain/venue_models.dart';
import '../data/floor_plan_data.dart';
import 'widgets/interactive_map_canvas.dart';
import 'widgets/hall_details_sheet.dart';
import 'widgets/floor_plan_search_sheet.dart';
import 'widgets/floor_plan_legend_sheet.dart';
import 'widgets/download_floor_plan_dialog.dart';

/// Professional, futuristic interactive venue Floor Plan screen for TEC-VERSE 2026.
///
/// Models Chennai Trade Centre (CTC), Nandambakkam:
/// - Halls 1 to 8, Convention Centre, Conference Halls 1-3
/// - Interactive pan & zoom with TransformationController
/// - Dynamic wayfinding route guidance with estimated walking time
/// - Technology domain filters, search, and official organizer download support
class FloorPlanScreen extends StatefulWidget {
  final String? initialHallId;

  const FloorPlanScreen({
    super.key,
    this.initialHallId,
  });

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> with TickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final Venue _venue;

  String? _selectedHallId;
  String? _selectedZoneId;
  NavigationRoute? _activeRoute;
  bool _showCurrentLocation = true;
  TechnologyZone? _focusedZone;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _venue = FloorPlanData.getVenue();

    _selectedHallId = widget.initialHallId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToScreen();
      if (widget.initialHallId != null) {
        _focusOnHall(widget.initialHallId!);
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// Auto-fit the canvas to the available viewport
  void _fitMapToScreen() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final availableHeight = size.height - 200; // Account for header and bottom controls
    final availableWidth = size.width;

    final scaleX = availableWidth / FloorPlanData.canvasWidth;
    final scaleY = availableHeight / FloorPlanData.canvasHeight;
    final scale = (scaleX < scaleY ? scaleX : scaleY) * 0.95;

    final dx = (availableWidth - (FloorPlanData.canvasWidth * scale)) / 2;
    // Align closer to lower half (entrance & main halls) initially
    final dy = 20.0;

    _transformationController.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale);
  }

  void _zoomIn() {
    final matrix = _transformationController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    if (currentScale < 3.2) {
      final size = MediaQuery.of(context).size;
      final focalPoint = Offset(size.width / 2, size.height / 2);
      final newScale = currentScale * 1.35;
      _animateScale(newScale, focalPoint);
    }
  }

  void _zoomOut() {
    final matrix = _transformationController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    if (currentScale > 0.4) {
      final size = MediaQuery.of(context).size;
      final focalPoint = Offset(size.width / 2, size.height / 2);
      final newScale = currentScale / 1.35;
      _animateScale(newScale, focalPoint);
    }
  }

  void _animateScale(double targetScale, Offset focalPoint) {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final factor = targetScale / currentScale;

    final newMatrix = currentMatrix.clone()
      ..translate(focalPoint.dx * (1 - factor), focalPoint.dy * (1 - factor))
      ..scale(factor);

    setState(() {
      _transformationController.value = newMatrix;
    });
  }

  void _resetMap() {
    setState(() {
      _selectedHallId = null;
      _selectedZoneId = null;
      _activeRoute = null;
      _focusedZone = null;
    });
    _fitMapToScreen();
  }

  void _focusOnHall(String hallId) {
    final hall = _venue.halls.firstWhere(
      (h) => h.id == hallId,
      orElse: () => _venue.halls.first,
    );

    final size = MediaQuery.of(context).size;
    const targetScale = 1.15;
    final center = hall.center;

    final dx = (size.width / 2) - (center.dx * targetScale);
    final dy = (size.height / 2) - (center.dy * targetScale) - 40;

    setState(() {
      _selectedHallId = hall.id;
      _transformationController.value = Matrix4.identity()
        ..translate(dx, dy)
        ..scale(targetScale);
    });

    _showHallDetails(hall);
  }

  void _focusOnCoordinates(Offset targetCoord, {String? hallId}) {
    final size = MediaQuery.of(context).size;
    const targetScale = 1.3;

    final dx = (size.width / 2) - (targetCoord.dx * targetScale);
    final dy = (size.height / 2) - (targetCoord.dy * targetScale) - 40;

    setState(() {
      if (hallId != null) _selectedHallId = hallId;
      _transformationController.value = Matrix4.identity()
        ..translate(dx, dy)
        ..scale(targetScale);
    });
  }

  void _showHallDetails(Hall hall) {
    HallDetailsSheet.show(
      context: context,
      hall: hall,
      onNavigateHere: () {
        _startNavigation(targetHallId: hall.id);
      },
      onShowSessions: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ScheduleScreen()),
        );
      },
    );
  }

  void _startNavigation({
    required String targetHallId,
    String? destinationTitle,
    Offset? targetCoordinates,
  }) {
    final route = FloorPlanData.calculateRouteTo(
      targetHallId: targetHallId,
      destinationTitle: destinationTitle,
      targetCoordinates: targetCoordinates,
    );

    setState(() {
      _activeRoute = route;
      _selectedHallId = targetHallId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Wayfinding active to ${route.destinationName} • ${route.distanceMeters.toInt()}m'),
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openSearch() {
    FloorPlanSearchSheet.show(
      context: context,
      onSelectTarget: (result) {
        _focusOnCoordinates(
          result.coordinates,
          hallId: result.hallId,
        );

        if (result.type == SearchResultType.hall && result.hallId != null) {
          final hall = _venue.halls.firstWhere((h) => h.id == result.hallId);
          _showHallDetails(hall);
        } else if (result.type == SearchResultType.zone) {
          _startNavigation(
            targetHallId: result.hallId ?? 'hall-1',
            destinationTitle: result.title,
            targetCoordinates: result.coordinates,
          );
        }
      },
    );
  }

  void _openDownloadDialog() {
    DownloadFloorPlanDialog.show(context);
  }

  void _openLegend() {
    FloorPlanLegendSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HEADER (Back button, Title, Subtitle, Search, Download)
            _buildTopHeader(),

            // 2. TECHNOLOGY ZONE HORIZONTAL QUICK FILTERS
            _buildTechnologyZoneFilters(),

            // 3. MAIN INTERACTIVE MAP VIEWPORT
            Expanded(
              child: Stack(
                children: [
                  // Pan & Zoom Interactive Map Surface
                  Positioned.fill(
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.35,
                      maxScale: 3.5,
                      boundaryMargin: const EdgeInsets.all(400),
                      clipBehavior: Clip.hardEdge,
                      child: InteractiveMapCanvas(
                        venue: _venue,
                        selectedHallId: _selectedHallId,
                        selectedZoneId: _selectedZoneId,
                        activeRoute: _activeRoute,
                        showCurrentLocation: _showCurrentLocation,
                        onHallTap: (hall) {
                          setState(() => _selectedHallId = hall.id);
                          _showHallDetails(hall);
                        },
                        onFacilityTap: (fac) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${fac.name} • ${fac.description}'),
                              backgroundColor: AppColors.surfaceElevated,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Floating Map Controls (Zoom +, Zoom -, Reset, Location, Legend)
                  Positioned(
                    right: 16,
                    bottom: _activeRoute != null || _focusedZone != null ? 140 : 20,
                    child: _buildFloatingMapControls(),
                  ),

                  // Active Route Navigation Guidance Banner
                  if (_activeRoute != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: FadeSlideTransition(
                        delay: Duration.zero,
                        child: _buildRouteGuidanceCard(_activeRoute!),
                      ),
                    )
                  else if (_focusedZone != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: FadeSlideTransition(
                        delay: Duration.zero,
                        child: _buildZoneFocusCard(_focusedZone!),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. TOP HEADER
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderCard, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Floor Plan',
                        style: AppTypography.headlineMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.cyanAccent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'CTC',
                        style: TextStyle(
                          color: AppColors.cyanAccent,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
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

          // Search Icon
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.cyanAccent, size: 22),
            onPressed: _openSearch,
            tooltip: 'Search Halls & Zones',
          ),

          // Download Floor Plan Button (Neon cyan outline per requirement 7)
          _buildDownloadButton(),
        ],
      ),
    );
  }

  /// Download Floor Plan button with neon cyan outline
  Widget _buildDownloadButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 380;

        if (isCompact) {
          return IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.cyanAccent, size: 22),
            tooltip: 'Download Floor Plan',
            onPressed: _openDownloadDialog,
          );
        }

        return ScaleOnPress(
          onTap: _openDownloadDialog,
          scaleFactor: 0.94,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cyanAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.cyanAccent,
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyanAccent.withValues(alpha: 0.15),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.file_download_outlined,
                  color: AppColors.cyanAccent,
                  size: 15,
                ),
                const SizedBox(width: 5),
                Text(
                  'Download',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cyanAccent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 2. TECHNOLOGY ZONE FILTERS
  Widget _buildTechnologyZoneFilters() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF070D19),
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 0.8),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: FloorPlanData.allTechnologyZones.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isAllSelected = _selectedZoneId == null;
            return ChoiceChip(
              label: const Text('All Zones'),
              selected: isAllSelected,
              onSelected: (_) {
                setState(() {
                  _selectedZoneId = null;
                  _focusedZone = null;
                });
              },
              backgroundColor: AppColors.surfaceElevated,
              selectedColor: AppColors.cyanAccent.withValues(alpha: 0.18),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isAllSelected ? FontWeight.w700 : FontWeight.w500,
                color: isAllSelected ? AppColors.cyanAccent : AppColors.textSecondary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isAllSelected ? AppColors.cyanAccent : AppColors.borderSubtle,
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            );
          }

          final zone = FloorPlanData.allTechnologyZones[index - 1];
          final isSelected = _selectedZoneId == zone.id;

          return ChoiceChip(
            avatar: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: zone.color, shape: BoxShape.circle),
            ),
            label: Text(zone.name),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedZoneId = zone.id;
                  _focusedZone = zone;
                  _focusOnHall(zone.hallId);
                } else {
                  _selectedZoneId = null;
                  _focusedZone = null;
                }
              });
            },
            backgroundColor: AppColors.surfaceElevated,
            selectedColor: zone.color.withValues(alpha: 0.22),
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected ? zone.color : AppColors.borderSubtle,
                width: 0.8,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          );
        },
      ),
    );
  }

  /// Floating Map Controls (Right Side)
  Widget _buildFloatingMapControls() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom In
          _controlButton(Icons.add_rounded, 'Zoom In', _zoomIn),
          const Divider(height: 1, color: AppColors.borderSubtle),

          // Zoom Out
          _controlButton(Icons.remove_rounded, 'Zoom Out', _zoomOut),
          const Divider(height: 1, color: AppColors.borderSubtle),

          // Reset Map View
          _controlButton(Icons.restart_alt_rounded, 'Reset Map', _resetMap),
          const Divider(height: 1, color: AppColors.borderSubtle),

          // Toggle Current Location
          _controlButton(
            _showCurrentLocation ? Icons.my_location_rounded : Icons.location_disabled_rounded,
            'My Location',
            () {
              setState(() => _showCurrentLocation = !_showCurrentLocation);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_showCurrentLocation
                      ? 'Current location beacon enabled (Registration Desk)'
                      : 'Current location marker hidden'),
                  backgroundColor: AppColors.surfaceElevated,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            color: _showCurrentLocation ? AppColors.cyanAccent : AppColors.textMuted,
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),

          // Legend Button
          _controlButton(Icons.legend_toggle_rounded, 'Legend', _openLegend, color: AppColors.cyanAccent),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, String tooltip, VoidCallback onTap, {Color? color}) {
    return IconButton(
      icon: Icon(icon, color: color ?? Colors.white70, size: 20),
      tooltip: tooltip,
      onPressed: onTap,
      constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
      padding: EdgeInsets.zero,
    );
  }

  /// Live Route Guidance Card
  Widget _buildRouteGuidanceCard(NavigationRoute route) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyanAccent.withValues(alpha: 0.15),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: AppColors.cyanAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_walk_rounded, color: AppColors.cyanAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROUTE TO ${route.destinationName.toUpperCase()}',
                      style: AppTypography.metaTag.copyWith(
                        fontSize: 10,
                        color: AppColors.cyanAccent,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${route.distanceMeters.toInt()} meters • ~${route.estimatedWalkingMinutes} min walk',
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                onPressed: () => setState(() => _activeRoute = null),
                tooltip: 'Clear Route',
              ),
            ],
          ),
          if (route.steps.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.borderSubtle),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.turn_right_rounded, color: AppColors.emeraldSuccess, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    route.steps.length > 2 ? route.steps[2] : route.steps.first,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Technology Zone Details Card (When a zone is selected from pills)
  Widget _buildZoneFocusCard(TechnologyZone zone) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: zone.color.withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: zone.color.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: zone.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  zone.name,
                  style: AppTypography.headlineMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                onPressed: () => setState(() {
                  _focusedZone = null;
                  _selectedZoneId = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${zone.sessions.length} Related Technical Sessions',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                    );
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 14),
                  label: const Text('View Sessions', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: zone.color.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: zone.color),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _startNavigation(targetHallId: zone.hallId, destinationTitle: zone.name),
                  icon: const Icon(Icons.navigation_rounded, size: 14),
                  label: const Text('Route Here', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.borderCard),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
