import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../domain/digital_event_pass.dart';

/// Sophisticated digital event credential pass card matching official design.
class DigitalPassCard extends StatefulWidget {
  final DigitalEventPass pass;
  final bool showScanAnimation;

  const DigitalPassCard({
    super.key,
    required this.pass,
    this.showScanAnimation = true,
  });

  @override
  State<DigitalPassCard> createState() => _DigitalPassCardState();
}

class _DigitalPassCardState extends State<DigitalPassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    // Run scanning animation only once when pass card opens
    if (widget.showScanAnimation && widget.pass.status == PassStatus.active) {
      _scanController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant DigitalPassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pass.status != PassStatus.active && _scanController.isAnimating) {
      _scanController.stop();
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  String _formatVenue(String venue) {
    if (venue.trim().isEmpty) return 'CHENNAI TRADE CENTRE';
    if (venue.toUpperCase().contains('CHENNAI TRADE') ||
        venue.toUpperCase().contains('NANDAMBAKKAM')) {
      return 'CHENNAI TRADE CENTRE';
    }
    return venue.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final pass = widget.pass;

    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFF0E5DE),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Scanner Banner Header
            Image.asset(
              'assets/images/scanner_banner.jpeg',
              width: double.infinity,
              height: 135,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 135,
                color: const Color(0xFFFF6B00),
                alignment: Alignment.center,
                child: const Text(
                  'TEC-VERSE 2026',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // 2. Event Dates & Venue Meta Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  // Event Dates
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 22,
                          color: Color(0xFFEA580C),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pass.eventDates.isNotEmpty
                                    ? pass.eventDates.toUpperCase()
                                    : '26–27 NOVEMBER 2026',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF102A43),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'EVENT DATES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vertical Separator
                  Container(
                    height: 32,
                    width: 1,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),

                  // Venue
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 22,
                          color: Color(0xFFEA580C),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatVenue(pass.venue),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF102A43),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'VENUE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // 3. Attendee Identity Header (Clean without Avatar & Badges)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    pass.holderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF102A43),
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (pass.designation.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      pass.designation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                  if (pass.organization.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      pass.organization,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 5. Central QR Code with Orange Corner Brackets & Laser Scan
            Center(
              child: Column(
                children: [
                  Semantics(
                    label: 'Digital event pass QR code for ${pass.holderName}',
                    image: true,
                    child: _QrCornerFrame(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          QrImageView(
                            data: pass.scannableInfo,
                            version: QrVersions.auto,
                            size: 186,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0F172A),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0F172A),
                            ),
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                            padding: EdgeInsets.zero,
                          ),

                          // Glowing Laser Scanning Overlay Animation (runs only one time on open)
                          if (widget.showScanAnimation && pass.status == PassStatus.active)
                            AnimatedBuilder(
                              animation: _scanAnimation,
                              builder: (context, child) {
                                if (_scanController.isCompleted) {
                                  return const SizedBox.shrink();
                                }
                                final progress = _scanAnimation.value;
                                final opacity = progress < 0.08
                                    ? (progress / 0.08)
                                    : (progress > 0.88 ? ((1.0 - progress) / 0.12) : 1.0);

                                return Positioned(
                                  top: progress * 176,
                                  left: 0,
                                  right: 0,
                                  child: Opacity(
                                    opacity: opacity.clamp(0.0, 1.0),
                                    child: Container(
                                      height: 2.5,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Color(0xFFEA580C),
                                            Colors.transparent,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEA580C).withValues(alpha: 0.7),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Scan at Registration pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3EC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFFD4BE),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 16,
                          color: Color(0xFFEA580C),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Scan with Google Lens / Scanner App',
                          style: TextStyle(
                            color: Color(0xFFEA580C),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 6. Security Unique Pass ID & Ref No Box
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFE7DA),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Shield Icon
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECE0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Color(0xFFEA580C),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Details Table
                    Expanded(
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 65,
                            child: Text(
                              'Ref No',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const Text(
                            ':   ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              pass.attendeeId.isNotEmpty ? pass.attendeeId : '-',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF102A43),
                                letterSpacing: 0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 7. Consortium Logos Footer Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset(
                    'assets/images/meity.webp',
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: const Color(0xFFE2E8F0),
                  ),
                  Image.asset(
                    'assets/images/organized_by_logos.png',
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter rendering four rounded orange corner brackets around QR code.
class _QrCornerFrame extends StatelessWidget {
  final Widget child;

  const _QrCornerFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _QrCornerPainter(),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: child,
      ),
    );
  }
}

class _QrCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEA580C)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 22.0;
    const cornerRadius = 8.0;

    // Top-Left corner
    final pathTL = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, cornerRadius)
      ..quadraticBezierTo(0, 0, cornerRadius, 0)
      ..lineTo(cornerLength, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right corner
    final pathTR = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - cornerRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, cornerRadius)
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left corner
    final pathBL = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - cornerRadius)
      ..quadraticBezierTo(0, size.height, cornerRadius, size.height)
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right corner
    final pathBR = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width - cornerRadius, size.height)
      ..quadraticBezierTo(size.width, size.height, size.width, size.height - cornerRadius)
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
