import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/widgets/animation_utils.dart';
import '../../../authentication/domain/authenticated_user.dart';
import '../../../digital_pass/domain/digital_event_pass.dart';

/// Executive Digital Event Pass Credential Ticket Banner.
class DigitalPassBanner extends StatelessWidget {
  final DigitalEventPass? pass;
  final UserProfile? user;
  final VoidCallback onTap;

  const DigitalPassBanner({
    super.key,
    required this.pass,
    this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final passId = pass?.passId.isNotEmpty == true ? pass!.passId : 'TV26-PASS-000007';
    final refNo = pass?.attendeeId.isNotEmpty == true
        ? pass!.attendeeId
        : (user?.referenceNumber.isNotEmpty == true
            ? user!.referenceNumber
            : 'TV26CG000007');

    final userName = pass?.holderName.isNotEmpty == true
        ? pass!.holderName
        : (user?.officialName.isNotEmpty == true
            ? user!.officialName
            : 'kishore k');

    final designation = pass?.designation.isNotEmpty == true
        ? pass!.designation
        : (user?.designation.isNotEmpty == true ? user!.designation : 'P.A');

    final organization = pass?.organization.isNotEmpty == true
        ? pass!.organization
        : (user?.organization.isNotEmpty == true ? user!.organization : 'cdac');

    final qrToken = pass?.qrToken.isNotEmpty == true
        ? pass!.qrToken
        : 'TECVERSE26:$passId';

    return Hero(
      tag: 'digital-pass-credential',
      child: Material(
        color: Colors.transparent,
        child: ScaleOnPress(
          onTap: onTap,
          scaleFactor: 0.98,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFF1E6DF),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.07),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  // Left Orange Accent Notch Strip
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 12,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFEA580C),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  // Left Notch Cutout Circle
                  Positioned(
                    left: -10,
                    top: 48,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAF7F4),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Column: Attendee Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Tag
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      'DIGITAL EVENT PASS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFEA580C),
                                        letterSpacing: 0.6,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Ref No
                              Text(
                                refNo,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFEA580C),
                                  letterSpacing: 0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 4),

                              // Attendee Name
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF102A43),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 2),

                              // Designation • Org
                              Text(
                                '$designation • $organization',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Vertical Perforation Divider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: CustomPaint(
                            size: const Size(1, 80),
                            painter: _VerticalDashedLinePainter(),
                          ),
                        ),

                        // Right Column: QR Code + Tap Action
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // QR Frame with Orange Corners
                            _MiniQrCornerFrame(
                              child: QrImageView(
                                data: qrToken,
                                version: QrVersions.auto,
                                size: 54,
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
                            ),

                            const SizedBox(height: 6),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tap to view pass',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFEA580C),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 14,
                                  color: Color(0xFFEA580C),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalDashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.2;

    const dashHeight = 4.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniQrCornerFrame extends StatelessWidget {
  final Widget child;

  const _MiniQrCornerFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniQrCornerPainter(),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: child,
      ),
    );
  }
}

class _MiniQrCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEA580C)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 8.0;

    // Top-Left
    canvas.drawLine(const Offset(0, cornerLength), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width - cornerLength, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height - cornerLength), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width - cornerLength, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

