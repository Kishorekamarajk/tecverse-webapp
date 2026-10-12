import 'package:flutter/material.dart';
import '../../data/venue_location_data.dart';
import '../location_screen.dart';

/// Attractive, modern mobile app Event Location Card featuring an authentic
/// Google Maps viewport with a tagged Chennai Trade Centre location pin.
class LocationPreviewCard extends StatelessWidget {
  const LocationPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    const venue = VenueLocationData.venue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1E6DF), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Badge Row: Location Pin, "EVENT LOCATION", "Full Map >"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3EC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFEA580C),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'EVENT LOCATION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFEA580C),
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LocationScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Full Map',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFFEA580C),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Venue Title & Physical Address Details
          Text(
            venue.name,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF102A43),
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 3),

          const Text(
            'Mount Poonamallee Rd, CTC Complex, Nandambakkam, Chennai 600089',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),

          const SizedBox(height: 10),

          // Transit Distance Badges (Metro, Bus Stand, Airport)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMiniPill(Icons.directions_subway_rounded, 'Metro: 4.2 km Alandur'),
              const SizedBox(height: 8),
              _buildMiniPill(Icons.directions_bus_rounded, 'Bus Stand: 1.2 km Nandambakkam'),
              const SizedBox(height: 8),
              _buildMiniPill(Icons.flight_takeoff_rounded, 'Airport: 6.5 km MAA'),
            ],
          ),

          const SizedBox(height: 14),

          // 3. Google Maps Viewport with Tagged Location Pin
          GestureDetector(
            onTap: () {
              VenueLocationData.openGoogleMapsDirections();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                ),
                child: Stack(
                  children: [
                    // Custom Google Maps Canvas Renderer
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GoogleMapCanvasPainter(),
                      ),
                    ),

                    // Top Right Google Map Controls (+ / - / Layers)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              child: const Icon(Icons.layers_outlined, size: 16, color: Color(0xFF475569)),
                            ),
                            Container(width: 20, height: 1, color: const Color(0xFFE2E8F0)),
                            Container(
                              padding: const EdgeInsets.all(5),
                              child: const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFF0284C7)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Center: Red Google Maps Pin & Tag Bubble
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tag Bubble above Pin
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.business_rounded, color: Color(0xFFEA580C), size: 13),
                                    SizedBox(width: 4),
                                    Text(
                                      'Chennai Trade Centre',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1),
                                Text(
                                  'Convention & Exhibition Centre',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 2),

                          // Google Maps Red Pin
                          Container(
                            width: 32,
                            height: 38,
                            alignment: Alignment.topCenter,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 36,
                                  color: Color(0xFFDC2626), // Google Maps Red
                                ),
                                Positioned(
                                  top: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Left "Google" Maps Watermark & Road Label
                    Positioned(
                      left: 10,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png',
                              height: 12,
                              errorBuilder: (context, error, stackTrace) => const Text(
                                'Google',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF4285F4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '• Mount Poonamallee Rd',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
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
          ),

          const SizedBox(height: 14),

          // 4. Primary Action Button: Get Directions on Google Maps
          ElevatedButton.icon(
            onPressed: () {
              VenueLocationData.openGoogleMapsDirections();
            },
            icon: const Icon(Icons.navigation_rounded, size: 16),
            label: const Text(
              'Get Directions on Google Maps',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD4BE), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: const Color(0xFFD9480F)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF102A43),
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for rendering authentic Google Maps vector terrain,
/// arterial roads, river waterways, and parks.
class _GoogleMapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base Terrain (Google Maps light beige)
    final bgPaint = Paint()..color = const Color(0xFFF3EFE9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Green Parks / Natural Areas (Guindy & St. Thomas Mount)
    final parkPaint = Paint()..color = const Color(0xFFCEE6C3);
    // Park 1 (Top Left)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, 10, size.width * 0.28, size.height * 0.4),
        const Radius.circular(16),
      ),
      parkPaint,
    );
    // Park 2 (Bottom Right)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.65, size.height * 0.55, size.width * 0.3, size.height * 0.4),
        const Radius.circular(16),
      ),
      parkPaint,
    );

    // 3. Adyar River Waterway (Light cyan-blue curve)
    final riverPaint = Paint()
      ..color = const Color(0xFFA5C9EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final riverPath = Path();
    riverPath.moveTo(0, size.height * 0.25);
    riverPath.cubicTo(
      size.width * 0.35,
      size.height * 0.1,
      size.width * 0.6,
      size.height * 0.4,
      size.width,
      size.height * 0.2,
    );
    canvas.drawPath(riverPath, riverPaint);

    // 4. Secondary Residential Roads (White roads)
    final secRoadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    // Horizontal secondary grid
    for (int i = 1; i <= 3; i++) {
      canvas.drawLine(
        Offset(0, size.height * (i * 0.25)),
        Offset(size.width, size.height * (i * 0.25)),
        secRoadPaint,
      );
    }
    // Vertical secondary grid
    for (int i = 1; i <= 4; i++) {
      canvas.drawLine(
        Offset(size.width * (i * 0.2), 0),
        Offset(size.width * (i * 0.2), size.height),
        secRoadPaint,
      );
    }

    // 5. Primary Arterial Highways (Mount Poonamallee Rd & GST Rd - Golden Yellow / Orange)
    final highwayPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    final highwayOutline = Paint()
      ..color = const Color(0xFFD6A820)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5
      ..strokeCap = StrokeCap.round;

    // Mount Poonamallee Road Diagonal
    final mountRd = Path();
    mountRd.moveTo(0, size.height * 0.85);
    mountRd.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.55,
      size.width,
      size.height * 0.45,
    );
    canvas.drawPath(mountRd, highwayOutline);
    canvas.drawPath(mountRd, highwayPaint);

    // Inner Ring Road
    final innerRing = Path();
    innerRing.moveTo(size.width * 0.55, 0);
    innerRing.lineTo(size.width * 0.55, size.height);
    canvas.drawPath(innerRing, highwayOutline);
    canvas.drawPath(innerRing, highwayPaint);

    // 6. Metro Line (Blue dashed track)
    final metroPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(size.width * 0.72, 0),
      Offset(size.width * 0.72, size.height),
      metroPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
