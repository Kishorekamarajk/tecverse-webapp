import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/venue_models.dart';
import '../../data/floor_plan_data.dart';

/// Highly optimized, futuristic custom painted interactive floor plan canvas.
///
/// Visual styling:
/// - Dark navy cybernetic background with architectural grid
/// - Neon cyan glowing corridors and arterial walkways
/// - Electric blue hall boundaries with glassmorphism shading
/// - High-contrast technology zone accents
/// - Animated pulsating attendee position beacon
/// - Animated neon route polyline for live navigation
class InteractiveMapCanvas extends StatefulWidget {
  final Venue venue;
  final String? selectedHallId;
  final String? selectedZoneId;
  final NavigationRoute? activeRoute;
  final bool showCurrentLocation;
  final ValueChanged<Hall> onHallTap;
  final ValueChanged<FacilityItem>? onFacilityTap;

  const InteractiveMapCanvas({
    super.key,
    required this.venue,
    this.selectedHallId,
    this.selectedZoneId,
    this.activeRoute,
    this.showCurrentLocation = true,
    required this.onHallTap,
    this.onFacilityTap,
  });

  @override
  State<InteractiveMapCanvas> createState() => _InteractiveMapCanvasState();
}

class _InteractiveMapCanvasState extends State<InteractiveMapCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    final localPos = details.localPosition;

    // Check if user tapped a facility marker
    for (final facility in widget.venue.facilities) {
      if ((facility.position - localPos).distance <= 20) {
        widget.onFacilityTap?.call(facility);
        return;
      }
    }

    // Check if user tapped a hall
    for (final hall in widget.venue.halls) {
      if (hall.bounds.contains(localPos)) {
        widget.onHallTap(hall);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(FloorPlanData.canvasWidth, FloorPlanData.canvasHeight),
            painter: _FloorMapPainter(
              venue: widget.venue,
              selectedHallId: widget.selectedHallId,
              selectedZoneId: widget.selectedZoneId,
              activeRoute: widget.activeRoute,
              showCurrentLocation: widget.showCurrentLocation,
              pulseProgress: _pulseController.value,
            ),
          );
        },
      ),
    );
  }
}

class _FloorMapPainter extends CustomPainter {
  final Venue venue;
  final String? selectedHallId;
  final String? selectedZoneId;
  final NavigationRoute? activeRoute;
  final bool showCurrentLocation;
  final double pulseProgress;

  _FloorMapPainter({
    required this.venue,
    required this.selectedHallId,
    required this.selectedZoneId,
    required this.activeRoute,
    required this.showCurrentLocation,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Futuristic Dark Navy Background
    final bgPaint = Paint()..color = const Color(0xFF030712);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Subtle Cyber Architectural Grid
    _drawArchitecturalGrid(canvas, size);

    // 3. Central Concourse & Connecting Neon Walkway Arteries
    _drawConcourseNetwork(canvas);

    // 4. Exterior Venue Boundaries and Landscaping Accents
    _drawVenueBoundaryAccents(canvas, size);

    // 5. Exhibition Halls & Convention Buildings
    for (final hall in venue.halls) {
      _drawHall(canvas, hall);
    }

    // 6. Venue Facilities (Food, Restroom, Medical, Exit, Reg)
    _drawFacilities(canvas);

    // 8. Active Wayfinding Route Overlay
    if (activeRoute != null) {
      _drawNavigationRoute(canvas, activeRoute!);
    }

    // 9. Pulsing Attendee Current Location Beacon
    if (showCurrentLocation) {
      _drawCurrentLocationMarker(canvas);
    }
  }

  void _drawArchitecturalGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.35)
      ..strokeWidth = 0.6;

    const double step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Coordinate intersections
    final dotPaint = Paint()
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    for (double x = 0; x <= size.width; x += step * 3) {
      for (double y = 0; y <= size.height; y += step * 3) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  void _drawConcourseNetwork(Canvas canvas) {
    // Glowing Neon Cyan Arteries
    final spineGlowPaint = Paint()
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.10)
      ..strokeWidth = 32.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final spineMainPaint = Paint()
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.28)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final spineCenterLine = Paint()
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.8)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Main Central Spine running from Entrance up to Convention Centre
    const startP = Offset(500, 1340);
    const endP = Offset(500, 220);

    canvas.drawLine(startP, endP, spineGlowPaint);
    canvas.drawLine(startP, endP, spineMainPaint);
    canvas.drawLine(startP, endP, spineCenterLine);

    // Lateral walkway connectors to Hall clusters
    const lateralYPositions = [1060.0, 825.0, 595.0, 365.0];
    final branchPaint = Paint()
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.22)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke;

    for (final y in lateralYPositions) {
      // Left branch into Halls 1, 3, 5, 7
      canvas.drawLine(Offset(450, y), Offset(500, y), branchPaint);
      // Right branch into Halls 2, 4, 6, 8
      canvas.drawLine(Offset(500, y), Offset(550, y), branchPaint);
    }
  }

  void _drawVenueBoundaryAccents(Canvas canvas, Size size) {
    // Elegant boundary trim for Chennai Trade Centre Complex
    final outerBorder = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const r = Rect.fromLTWH(20, 20, 960, 1360);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(20)), outerBorder);

    // Watermark branding at center
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'NANDAMBAKKAM, TAMIL NADU 600089',
        style: TextStyle(
          color: Color(0x18FFFFFF),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 4.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(500 - (textPainter.width / 2), 690);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _drawHall(Canvas canvas, Hall hall) {
    final isSelected = hall.id == selectedHallId;
    final rrect = RRect.fromRectAndRadius(hall.bounds, const Radius.circular(14));

    // Hall Glass Fill
    final fillPaint = Paint()
      ..color = isSelected
          ? hall.accentColor.withValues(alpha: 0.22)
          : const Color(0xFF0F172A).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // Selected Glowing Halo
    if (isSelected) {
      final glowPaint = Paint()
        ..color = hall.accentColor.withValues(alpha: 0.35 + (math.sin(pulseProgress * math.pi * 2) * 0.15))
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawRRect(rrect, glowPaint);
    }

    // Border (Electric Blue or Accent Color)
    final borderPaint = Paint()
      ..color = isSelected ? hall.accentColor : const Color(0xFF0A84FF).withValues(alpha: 0.55)
      ..strokeWidth = isSelected ? 2.5 : 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    // Render Technology Zone Blocks inside the hall
    _drawZonesInsideHall(canvas, hall);

    // Hall Header Badge
    _drawHallHeader(canvas, hall, isSelected);
  }

  void _drawZonesInsideHall(Canvas canvas, Hall hall) {
    if (hall.zones.isEmpty) return;

    final innerRect = hall.bounds.deflate(10);
    final count = hall.zones.length;
    final zoneWidth = (innerRect.width - (count - 1) * 6) / count;

    for (int i = 0; i < count; i++) {
      final zone = hall.zones[i];
      final isZoneSelected = zone.id == selectedZoneId;
      final zoneRect = Rect.fromLTWH(
        innerRect.left + (i * (zoneWidth + 6)),
        innerRect.bottom - 46,
        zoneWidth,
        36,
      );

      final zoneRRect = RRect.fromRectAndRadius(zoneRect, const Radius.circular(6));

      final zoneFill = Paint()
        ..color = isZoneSelected
            ? zone.color.withValues(alpha: 0.40)
            : zone.color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(zoneRRect, zoneFill);

      final zoneBorder = Paint()
        ..color = isZoneSelected ? zone.color : zone.color.withValues(alpha: 0.35)
        ..strokeWidth = isZoneSelected ? 1.5 : 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(zoneRRect, zoneBorder);

      // Zone Label
      final tp = TextPainter(
        text: TextSpan(
          text: zone.name,
          style: TextStyle(
            color: isZoneSelected ? Colors.white : zone.color,
            fontSize: 9.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '..',
      )..layout(maxWidth: zoneWidth - 6);

      tp.paint(
        canvas,
        Offset(
          zoneRect.left + (zoneWidth - tp.width) / 2,
          zoneRect.top + (36 - tp.height) / 2,
        ),
      );
    }
  }

  void _drawHallHeader(Canvas canvas, Hall hall, bool isSelected) {
    // Hall Number Pill
    final pillRect = Rect.fromLTWH(hall.bounds.left + 12, hall.bounds.top + 10, 32, 22);
    final pillRRect = RRect.fromRectAndRadius(pillRect, const Radius.circular(6));
    final pillPaint = Paint()
      ..color = hall.accentColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(pillRRect, pillPaint);

    final pillBorder = Paint()
      ..color = hall.accentColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(pillRRect, pillBorder);

    final numPainter = TextPainter(
      text: TextSpan(
        text: hall.number,
        style: TextStyle(
          color: hall.accentColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    numPainter.paint(
      canvas,
      Offset(
        pillRect.left + (pillRect.width - numPainter.width) / 2,
        pillRect.top + (pillRect.height - numPainter.height) / 2,
      ),
    );

    // Hall Name & Subtitle
    final namePainter = TextPainter(
      text: TextSpan(
        text: hall.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: hall.bounds.width - 60);
    namePainter.paint(canvas, Offset(hall.bounds.left + 52, hall.bounds.top + 12));

    // Hall Subtitle description
    final subPainter = TextPainter(
      text: TextSpan(
        text: hall.subtitle,
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.85),
          fontSize: 9.5,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    )..layout(maxWidth: hall.bounds.width - 24);
    subPainter.paint(canvas, Offset(hall.bounds.left + 14, hall.bounds.top + 38));
  }

  void _drawFacilities(Canvas canvas) {
    for (final facility in venue.facilities) {
      final pos = facility.position;
      final color = facility.type.color;

      // Icon Pin Base
      final pinBg = Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 12, pinBg);

      final pinBorder = Paint()
        ..color = color
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, 12, pinBorder);

      // Symbol
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(facility.type.icon.codePoint),
          style: TextStyle(
            inherit: false,
            color: color,
            fontSize: 12,
            fontFamily: facility.type.icon.fontFamily,
            package: facility.type.icon.fontPackage,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      iconPainter.paint(
        canvas,
        Offset(pos.dx - (iconPainter.width / 2), pos.dy - (iconPainter.height / 2)),
      );

      // Facility Name Label
      final namePainter = TextPainter(
        text: TextSpan(
          text: facility.name,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Avoid drawing labels off-canvas
      final labelX = (pos.dx - (namePainter.width / 2)).clamp(10.0, 980.0 - namePainter.width);
      namePainter.paint(canvas, Offset(labelX, pos.dy + 14));
    }
  }

  void _drawNavigationRoute(Canvas canvas, NavigationRoute route) {
    if (route.waypoints.length < 2) return;

    final path = Path();
    path.moveTo(route.waypoints.first.dx, route.waypoints.first.dy);
    for (int i = 1; i < route.waypoints.length; i++) {
      path.lineTo(route.waypoints[i].dx, route.waypoints[i].dy);
    }

    // Glowing Wide Route Underlay
    final glowPaint = Paint()
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.45)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    // Sharp Core Route Line
    final corePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, corePaint);

    // Draw waypoints as glowing stepping stones
    final stepPaint = Paint()
      ..color = const Color(0xFF00F2FE)
      ..style = PaintingStyle.fill;
    final stepBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final pt in route.waypoints) {
      canvas.drawCircle(pt, 5, stepPaint);
      canvas.drawCircle(pt, 5, stepBorder);
    }

    // Destination Pin Flag
    final dest = route.waypoints.last;
    final destHalo = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(dest, 18, destHalo);

    final destPin = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dest, 10, destPin);

    final destIcon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.flag_rounded.codePoint),
        style: TextStyle(
          inherit: false,
          color: Colors.white,
          fontSize: 12,
          fontFamily: Icons.flag_rounded.fontFamily,
          package: Icons.flag_rounded.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    destIcon.paint(canvas, Offset(dest.dx - (destIcon.width / 2), dest.dy - (destIcon.height / 2)));
  }

  void _drawCurrentLocationMarker(Canvas canvas) {
    const pos = FloorPlanData.registrationCoord;

    // Expanding Radar Ripple Waves
    final waveRadius1 = 14.0 + (pulseProgress * 28.0);
    final waveAlpha1 = (1.0 - pulseProgress).clamp(0.0, 1.0) * 0.4;
    final ripplePaint1 = Paint()
      ..color = const Color(0xFF00F2FE).withValues(alpha: waveAlpha1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(pos, waveRadius1, ripplePaint1);

    final waveRadius2 = 14.0 + (((pulseProgress + 0.5) % 1.0) * 28.0);
    final waveAlpha2 = (1.0 - ((pulseProgress + 0.5) % 1.0)).clamp(0.0, 1.0) * 0.4;
    final ripplePaint2 = Paint()
      ..color = const Color(0xFF00F2FE).withValues(alpha: waveAlpha2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(pos, waveRadius2, ripplePaint2);

    // Inner Solid Beacon
    final beaconPaint = Paint()
      ..color = const Color(0xFF00F2FE)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 8.0, beaconPaint);

    final beaconCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 3.5, beaconCore);

    // Floating Badge "YOU ARE HERE"
    final badgeRect = Rect.fromLTWH(pos.dx - 45, pos.dy - 32, 90, 20);
    final badgeRRect = RRect.fromRectAndRadius(badgeRect, const Radius.circular(10));

    final badgeFill = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(badgeRRect, badgeFill);

    final badgeBorder = Paint()
      ..color = const Color(0xFF00F2FE)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(badgeRRect, badgeBorder);

    final youPainter = TextPainter(
      text: const TextSpan(
        text: 'YOU ARE HERE',
        style: TextStyle(
          color: Color(0xFF00F2FE),
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    youPainter.paint(
      canvas,
      Offset(
        badgeRect.left + (badgeRect.width - youPainter.width) / 2,
        badgeRect.top + (badgeRect.height - youPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _FloorMapPainter oldDelegate) {
    return oldDelegate.selectedHallId != selectedHallId ||
        oldDelegate.selectedZoneId != selectedZoneId ||
        oldDelegate.activeRoute != activeRoute ||
        oldDelegate.showCurrentLocation != showCurrentLocation ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}
