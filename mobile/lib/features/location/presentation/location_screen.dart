// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animation_utils.dart';
import '../domain/location_models.dart';
import '../data/venue_location_data.dart';
import 'widgets/manual_location_dialog.dart';

/// Dedicated Event Location & Navigation screen for TEC-VERSE 2026.
///
/// Features:
/// - Destination: Chennai Trade Centre (CTC), Nandambakkam (13.0148, 80.1909)
/// - Modern, attractive mobile app map design with natural terrain, road networks & Adyar river
/// - Interactive pan/zoom map preview with road and metro arteries
/// - Dynamic distance & travel time estimation across 4 transport modes
/// - Turn-by-turn route steps
/// - Native navigation trigger (Google Maps / Apple Maps directions)
class LocationScreen extends StatefulWidget {
  final GeoLocation? initialOrigin;

  const LocationScreen({
    super.key,
    this.initialOrigin,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late GeoLocation _currentOrigin;
  TransportMode _selectedMode = TransportMode.driving;
  bool _isGpsPermissionGranted = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _currentOrigin = widget.initialOrigin ?? VenueLocationData.defaultOrigin;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _openManualOriginDialog() {
    ManualLocationDialog.show(
      context: context,
      currentSelected: _currentOrigin,
      onLocationSelected: (loc) {
        setState(() {
          _currentOrigin = loc;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting point set to ${loc.name}'),
            backgroundColor: AppColors.surfaceElevated,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  void _handleGetDirections() {
    VenueLocationData.openNativeDirections(
      origin: _isGpsPermissionGranted ? _currentOrigin : null,
      mode: _selectedMode,
    );
  }

  void _handleOpenGoogleMaps() {
    VenueLocationData.openInGoogleMaps();
  }

  void _handleShareLocation() {
    final text = 'TEC-VERSE 2026 Venue: ${VenueLocationData.venue.name}, ${VenueLocationData.venue.fullAddress}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location copied: $text'),
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routes = VenueLocationData.calculateRoutes(origin: _currentOrigin);
    final activeRoute = routes[_selectedMode]!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HEADER
            _buildTopHeader(),

            // 2. TRANSPORT MODE TABS (Driving, Two-Wheeler, Transit, Walking)
            _buildTransportModeSelector(routes),

            // 3. INTERACTIVE MAP VIEWPORT
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.5,
                      maxScale: 3.0,
                      boundaryMargin: const EdgeInsets.all(200),
                      clipBehavior: Clip.hardEdge,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(800, 600),
                            painter: _CityNavigationMapPainter(
                              origin: _currentOrigin,
                              venue: VenueLocationData.venue,
                              selectedMode: _selectedMode,
                              pulseValue: _pulseController.value,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Floating Map Controls (Recenter, Origin Picker, GPS toggle)
                  Positioned(
                    right: 16,
                    top: 16,
                    child: _buildMapQuickActions(),
                  ),

                  // Current Origin Banner
                  Positioned(
                    left: 16,
                    top: 16,
                    child: _buildOriginPill(),
                  ),
                ],
              ),
            ),

            // 4. BOTTOM INFORMATION & ROUTE SUMMARY CARD
            _buildBottomVenueCard(activeRoute),
          ],
        ),
      ),
    );
  }

  /// 1. TOP HEADER
  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(color: AppColors.borderCard, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              tooltip: 'Back',
            ),
          ),
          const SizedBox(width: 12),
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
                        'Event Location',
                        style: AppTypography.headlineMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'TAMIL NADU',
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  VenueLocationData.venue.fullAddress,
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
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.primaryOrange, size: 19),
              onPressed: _handleShareLocation,
              tooltip: 'Share Location',
            ),
          ),
        ],
      ),
    );
  }

  /// 2. TRANSPORT MODE SELECTOR
  Widget _buildTransportModeSelector(Map<TransportMode, RouteOption> routes) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 0.8),
        ),
      ),
      child: Row(
        children: TransportMode.values.map((mode) {
          final isSelected = _selectedMode == mode;
          final opt = routes[mode]!;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ScaleOnPress(
                onTap: () => setState(() => _selectedMode = mode),
                scaleFactor: 0.96,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryOrange.withValues(alpha: 0.12)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryOrange : AppColors.borderSubtle,
                      width: isSelected ? 1.2 : 0.6,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        mode.icon,
                        size: 16,
                        color: isSelected ? AppColors.primaryOrange : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${opt.durationMinutes}m',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.primaryOrange : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Floating map actions
  Widget _buildMapQuickActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderCard),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt_rounded, color: AppColors.primaryOrange, size: 20),
            tooltip: 'Change Starting Location',
            onPressed: _openManualOriginDialog,
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            padding: EdgeInsets.zero,
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          IconButton(
            icon: Icon(
              _isGpsPermissionGranted ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
              color: _isGpsPermissionGranted ? const Color(0xFF1A73E8) : AppColors.textMuted,
              size: 20,
            ),
            tooltip: _isGpsPermissionGranted ? 'GPS Location Enabled' : 'GPS Disabled',
            onPressed: () {
              setState(() => _isGpsPermissionGranted = !_isGpsPermissionGranted);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isGpsPermissionGranted
                      ? 'GPS origin enabled (${_currentOrigin.name})'
                      : 'Enable location access to get directions from your current location.'),
                  backgroundColor: AppColors.surfaceElevated,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            padding: EdgeInsets.zero,
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, color: AppColors.textSecondary, size: 20),
            tooltip: 'Recenter Map',
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  /// Current Origin Pill
  Widget _buildOriginPill() {
    return InkWell(
      onTap: _openManualOriginDialog,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderCard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trip_origin_rounded, color: Color(0xFF1A73E8), size: 12),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                'From: ${_currentOrigin.name}',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  /// 4. BOTTOM INFORMATION & ROUTE SUMMARY CARD
  Widget _buildBottomVenueCard(RouteOption activeRoute) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.borderCard),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Destination Info Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.primaryOrange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            VenueLocationData.venue.name,
                            style: AppTypography.headlineMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldSuccess.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CONFIRMED VENUE',
                            style: TextStyle(
                              color: AppColors.emeraldSuccess,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      VenueLocationData.venue.fullAddress,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dates: ${VenueLocationData.venue.eventDates} • ${VenueLocationData.venue.nearestAirport}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 10),

          // Route Details Strip
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(activeRoute.mode.icon, size: 14, color: AppColors.primaryOrange),
                    const SizedBox(width: 5),
                    Text(
                      '${activeRoute.distanceKm} km • ~${activeRoute.durationMinutes} mins',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  activeRoute.routeSummary,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Buttons: Get Directions, Open in Google Maps
          Row(
            children: [
              // Primary Get Directions button
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _handleGetDirections,
                  icon: const Icon(Icons.navigation_rounded, size: 16),
                  label: const Text('Get Directions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Open in Google Maps
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _handleOpenGoogleMaps,
                  icon: const Icon(Icons.map_outlined, size: 15),
                  label: const Text('Google Maps', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderCard),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

/// Custom painted interactive city navigation map around Chennai Trade Centre
/// using attractive, clean Google/Apple Maps vector styling.
class _CityNavigationMapPainter extends CustomPainter {
  final GeoLocation origin;
  final EventVenue venue;
  final TransportMode selectedMode;
  final double pulseValue;

  _CityNavigationMapPainter({
    required this.origin,
    required this.venue,
    required this.selectedMode,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Natural Land Base Background
    final bgPaint = Paint()..color = const Color(0xFFEEF3F8);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. City Blocks & Urban Land Uses
    _drawCityParcels(canvas, size);

    // 3. Green Parks & Adyar River
    _drawNaturalFeatures(canvas, size);

    // 4. Chennai Key Corridors (Mount Poonamallee Road, GST Road, Metro Line)
    _drawCityRoads(canvas, size);

    // 5. Origin Marker: Selected attendee start location
    const originCenter = Offset(180, 160);
    _drawOriginMarker(canvas, originCenter);

    // 6. Destination Pin: Chennai Trade Centre
    const ctcCenter = Offset(520, 310);
    _drawDestinationMarker(canvas, ctcCenter);

    // 7. Connecting Route Polyline with Directional Pulse
    _drawRoutePolyline(canvas, originCenter, ctcCenter);
  }

  void _drawCityParcels(Canvas canvas, Size size) {
    final parcelPaint = Paint()..color = const Color(0xFFE2E8F0);
    final parcelBorder = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    final parcels = [
      Rect.fromLTWH(40, 60, 110, 80),
      Rect.fromLTWH(180, 40, 130, 90),
      Rect.fromLTWH(340, 70, 100, 110),
      Rect.fromLTWH(60, 220, 90, 120),
      Rect.fromLTWH(180, 280, 110, 90),
      Rect.fromLTWH(320, 410, 80, 100),
      Rect.fromLTWH(580, 80, 120, 110),
      Rect.fromLTWH(630, 260, 110, 120),
    ];

    for (final p in parcels) {
      final rrect = RRect.fromRectAndRadius(p, const Radius.circular(6));
      canvas.drawRRect(rrect, parcelPaint);
      canvas.drawRRect(rrect, parcelBorder);
    }
  }

  void _drawNaturalFeatures(Canvas canvas, Size size) {
    // Green Parkland (Guindy & CTC Grounds)
    final parkPaint = Paint()..color = const Color(0xFFD8F3DC);
    final parkBorder = Paint()
      ..color = const Color(0xFFB7E4C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final park1 = Path()
      ..moveTo(420, 60)
      ..quadraticBezierTo(540, 40, 560, 180)
      ..quadraticBezierTo(480, 220, 410, 160)
      ..close();
    canvas.drawPath(park1, parkPaint);
    canvas.drawPath(park1, parkBorder);

    // Adyar River
    final waterPaint = Paint()..color = const Color(0xFFC7E2FE);
    final waterBorder = Paint()
      ..color = const Color(0xFFA5D0FC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final riverPath = Path()
      ..moveTo(0, 520)
      ..quadraticBezierTo(260, 490, 520, 540)
      ..quadraticBezierTo(680, 570, 800, 500)
      ..lineTo(800, 600)
      ..lineTo(0, 600)
      ..close();
    canvas.drawPath(riverPath, waterPaint);
    canvas.drawPath(riverPath, waterBorder);
  }

  void _drawCityRoads(Canvas canvas, Size size) {
    // Secondary streets
    final secCasing = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final secFill = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final secPath1 = Path()
      ..moveTo(160, 0)
      ..lineTo(160, 600);
    canvas.drawPath(secPath1, secCasing);
    canvas.drawPath(secPath1, secFill);

    final secPath2 = Path()
      ..moveTo(0, 200)
      ..lineTo(800, 200);
    canvas.drawPath(secPath2, secCasing);
    canvas.drawPath(secPath2, secFill);

    // Mount Poonamallee High Road
    final arterialCasing = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final arterialFill = Paint()
      ..color = Colors.white
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final roadPath = Path()
      ..moveTo(60, 480)
      ..quadraticBezierTo(320, 380, 520, 310)
      ..quadraticBezierTo(680, 260, 780, 120);
    canvas.drawPath(roadPath, arterialCasing);
    canvas.drawPath(roadPath, arterialFill);

    // GST Road
    final gstPath = Path()
      ..moveTo(420, 560)
      ..lineTo(480, 420)
      ..lineTo(560, 200)
      ..lineTo(620, 40);
    canvas.drawPath(gstPath, arterialCasing);
    canvas.drawPath(gstPath, arterialFill);

    // Kathipara Flyover Cloverleaf
    final cloverPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(const Offset(480, 420), 24, cloverPaint);

    final cloverInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(const Offset(480, 420), 24, cloverInner);

    // Chennai Metro Corridor
    final metroPaint = Paint()
      ..color = const Color(0xFF6366F1).withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(490, 580), const Offset(570, 80), metroPaint);

    // Landmark text labels
    _drawLabel(canvas, 'MOUNT POONAMALLEE ROAD', const Offset(180, 410));
    _drawLabel(canvas, 'KATHIPARA JUNCTION', const Offset(430, 452));
    _drawLabel(canvas, 'ALANDUR METRO INTERCHANGE', const Offset(510, 390));
    _drawLabel(canvas, 'CHENNAI AIRPORT (MAA) ✈', const Offset(430, 550));
    _drawLabel(canvas, 'ADYAR RIVER', const Offset(340, 560));
  }

  void _drawRoutePolyline(Canvas canvas, Offset start, Offset end) {
    final routePath = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(260, 290, 420, 320)
      ..lineTo(end.dx, end.dy);

    // Route Outer Casing
    final casingPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, casingPaint);

    // Sharp Core Royal Blue Route Line
    final corePaint = Paint()
      ..color = const Color(0xFF1A73E8)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(routePath, corePaint);
  }

  void _drawDestinationMarker(Canvas canvas, Offset pos) {
    // Pulse ring
    final waveRadius = 14.0 + (pulseValue * 22.0);
    final waveAlpha = (1.0 - pulseValue).clamp(0.0, 1.0) * 0.45;
    final wavePaint = Paint()
      ..color = AppColors.primaryOrange.withValues(alpha: waveAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(pos, waveRadius, wavePaint);

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 2), width: 18, height: 7),
      shadowPaint,
    );

    // 3D Teardrop Pin
    final pinPath = Path()
      ..moveTo(pos.dx, pos.dy)
      ..cubicTo(pos.dx - 10, pos.dy - 12, pos.dx - 12, pos.dy - 22, pos.dx, pos.dy - 30)
      ..cubicTo(pos.dx + 12, pos.dy - 22, pos.dx + 10, pos.dy - 12, pos.dx, pos.dy)
      ..close();

    final pinGradient = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6B1A), Color(0xFFEA4335)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(pos.dx - 12, pos.dy - 30, 24, 30));
    canvas.drawPath(pinPath, pinGradient);

    final innerCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(pos.dx, pos.dy - 18), 5.0, innerCore);

    final innerDot = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(pos.dx, pos.dy - 18), 2.5, innerDot);

    // Floating Badge "Chennai Trade Centre"
    final badgeRect = Rect.fromLTWH(pos.dx - 80, pos.dy - 64, 160, 28);
    final badgeRRect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(10));

    final badgeShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(badgeRRect.shift(const Offset(0, 2)), badgeShadow);

    final badgeFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(badgeRRect, badgeFill);

    final badgeBorder = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(badgeRRect, badgeBorder);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Chennai Trade Centre',
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        badgeRect.left + (badgeRect.width - textPainter.width) / 2,
        badgeRect.top + (badgeRect.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawOriginMarker(Canvas canvas, Offset pos) {
    // Origin GPS Dot
    final halo = Paint()
      ..color = const Color(0xFF1A73E8).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 10, halo);

    final outerRing = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 6, outerRing);

    final innerCore = Paint()
      ..color = const Color(0xFF1A73E8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 4, innerCore);

    // Origin Badge
    final badgeRect = Rect.fromLTWH(pos.dx - 60, pos.dy - 34, 120, 22);
    final badgeRRect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(8));

    final badgeFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(badgeRRect, badgeFill);

    final badgeBorder = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(badgeRRect, badgeBorder);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'START: ${origin.name}',
        style: const TextStyle(
          color: Color(0xFF1A73E8),
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '..',
    )..layout(maxWidth: 110);

    textPainter.paint(
      canvas,
      Offset(
        badgeRect.left + (badgeRect.width - textPainter.width) / 2,
        badgeRect.top + (badgeRect.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 8.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _CityNavigationMapPainter oldDelegate) {
    return oldDelegate.origin != origin ||
        oldDelegate.selectedMode != selectedMode ||
        oldDelegate.pulseValue != pulseValue;
  }
}
