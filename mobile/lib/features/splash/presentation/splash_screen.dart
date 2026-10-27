import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../../navigation/app_router.dart';

/// Cinematic Tec-Verse 2026 intro with a corridor, subtle T mark, live countdown, zoom reveal, and timed loading progress.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _zoomController;
  late Timer _countdownTimer;

  Duration _countdownRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Pulse / breathing glow animation (2.5s cycle)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    // Timed loading progress matches the cinematic intro duration.
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..forward();

    _updateCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );

    // Session restoration updates AuthController (a ChangeNotifier). Defer it
    // until the first frame is mounted so Provider dependents are not notified
    // while the widget tree is still being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startLoadingSequence();
    });
  }

  void _updateCountdown() {
    final untilEvent = DateTime(2026, 11, 26).difference(DateTime.now());
    if (mounted) {
      setState(() {
        _countdownRemaining = untilEvent.isNegative ? Duration.zero : untilEvent;
      });
    } else {
      _countdownRemaining = untilEvent.isNegative ? Duration.zero : untilEvent;
    }
  }

  Future<void> _startLoadingSequence() async {
    _progressController.forward();

    // Check auth session in background while smooth animation plays
    final authController = context.read<AuthController>();
    final sessionCheckFuture = authController.checkSession();

    // Hold the intro long enough for the zoom and countdown reveal to read.
    final minDelayFuture = Future.delayed(const Duration(milliseconds: 4000));

    final results = await Future.wait([sessionCheckFuture, minDelayFuture]);
    final isAuthenticated = results[0] as bool;

    if (!mounted) return;

    if (isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _zoomController.dispose();
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _countdownRemaining.inDays;
    final hours = _countdownRemaining.inHours.remainder(24);
    final minutes = _countdownRemaining.inMinutes.remainder(60);
    final seconds = _countdownRemaining.inSeconds.remainder(60);
    final countdown = [
      (days.toString().padLeft(2, '0'), 'DAYS'),
      (hours.toString().padLeft(2, '0'), 'HOURS'),
      (minutes.toString().padLeft(2, '0'), 'MINUTES'),
      (seconds.toString().padLeft(2, '0'), 'SECONDS'),
    ];

    final introOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 9),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 12,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 59),
    ]).animate(_zoomController);
    final introScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.72, end: 1.08).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 25,
      ),
      TweenSequenceItem(tween: ConstantTween(1.08), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.2), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.2), weight: 60),
    ]).animate(_zoomController);
    final tOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 22),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 58),
    ]).animate(_zoomController);
    final countdownOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 30),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 52),
    ]).animate(_zoomController);

    return Scaffold(
      backgroundColor: const Color(0xFF030907),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => CustomPaint(
                painter: _CinematicHallPainter(_pulseController.value),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: tOpacity,
              child: Text(
                'T',
                style: TextStyle(
                  fontSize: MediaQuery.sizeOf(context).height * 0.82,
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.075),
                  shadows: [
                    Shadow(
                      color: const Color(0xFF9BFF83).withValues(alpha: 0.16),
                      blurRadius: 55,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.24),
                    const Color(0xFF010403).withValues(alpha: 0.86),
                  ],
                  stops: const [0, 0.42, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                alignment: Alignment.center,
                children: [
                  FadeTransition(
                    opacity: countdownOpacity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'EVENT BEGINS IN',
                            style: TextStyle(
                              color: Color(0xFFD5E2D7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(countdown.length, (index) {
                              final item = countdown[index];
                              return Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              item.$1,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 34,
                                                fontWeight: FontWeight.w300,
                                                letterSpacing: 3,
                                                fontFeatures: [FontFeature.tabularFigures()],
                                                shadows: [
                                                  Shadow(
                                                    color: Color(0xFF9EFF85),
                                                    blurRadius: 16,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          Text(
                                            item.$2,
                                            maxLines: 1,
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.72),
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 2.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (index != countdown.length - 1)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 18),
                                        child: Text(
                                          ':',
                                          style: TextStyle(
                                            color: const Color(0xFFB6FF9C).withValues(alpha: 0.8),
                                            fontSize: 24,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '26 NOVEMBER 2026  ·  CHENNAI',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.56),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: introOpacity,
                    child: ScaleTransition(
                      scale: introScale,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(child: _buildBrandTitleSection()),
                            const SizedBox(height: 15),
                            Text(
                              'BRIDGING RESEARCH. BUILDING THE FUTURE.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 20,
                    child: FadeTransition(
                      opacity: countdownOpacity,
                      child: Text(
                        'Tec-Verse 2026  ·  CHENNAI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.58),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. BRAND TITLE SECTION (Tec-Verse 2026 + Golden Orbit Swoosh)
  // ===========================================================================
  Widget _buildBrandTitleSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Golden orbital swoosh arching over VERSE
        Positioned(
          top: -2,
          right: 32,
          child: CustomPaint(
            size: const Size(120, 32),
            painter: _GoldenSwooshPainter(),
          ),
        ),

        // Main Brand Row
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // "TEC-" in Deep Navy Blue
            const Text(
              'TEC-',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0B2265),
                letterSpacing: -0.5,
              ),
            ),

            // "VERSE" in Bright Gradient Orange
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'VERSE',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // "2026" Pill Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                '2026',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS FOR ORBITAL TRACKS & GOLDEN SWOOSH
// =============================================================================

/// Paints a moody, green-lit perspective corridor for the cinematic intro.
class _CinematicHallPainter extends CustomPainter {
  final double phase;

  const _CinematicHallPainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final vanishing = Offset(w * 0.5, h * 0.39);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(const Color(0xFFB9FF8B), const Color(0xFFE4FFD4), phase)!
              .withValues(alpha: 0.38),
          const Color(0xFF65B765).withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0, 0.32, 1],
      ).createShader(Rect.fromCircle(center: vanishing, radius: w * 0.7));
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF07110D));
    canvas.drawRect(Offset.zero & size, glow);

    final beamPaint = Paint()
      ..color = const Color(0xFFB7FF91).withValues(alpha: 0.14 + phase * 0.08)
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawLine(Offset(w * 0.27, 0), vanishing, beamPaint);
    canvas.drawLine(Offset(w * 0.73, 0), vanishing, beamPaint);

    final pillarPaint = Paint()..color = const Color(0xFF030806).withValues(alpha: 0.88);
    final leftPillar = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.28, 0)
      ..lineTo(w * 0.43, h * 0.43)
      ..lineTo(w * 0.31, h * 0.48)
      ..lineTo(w * 0.18, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(leftPillar, pillarPaint);
    final rightPillar = Path()
      ..moveTo(w, 0)
      ..lineTo(w * 0.72, 0)
      ..lineTo(w * 0.57, h * 0.43)
      ..lineTo(w * 0.69, h * 0.48)
      ..lineTo(w * 0.82, h)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(rightPillar, pillarPaint);

    final edgePaint = Paint()
      ..color = const Color(0xFFA5E979).withValues(alpha: 0.22 + phase * 0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawLine(Offset(w * 0.28, 0), Offset(w * 0.43, h * 0.43), edgePaint);
    canvas.drawLine(Offset(w * 0.72, 0), Offset(w * 0.57, h * 0.43), edgePaint);

    final floorPaint = Paint()
      ..color = const Color(0xFFB9F49B).withValues(alpha: 0.13)
      ..strokeWidth = 1.2;
    for (var i = 1; i <= 6; i++) {
      final t = i / 7;
      final y = h * (0.48 + t * t * 0.52);
      canvas.drawLine(Offset(w * (0.32 - t * 0.32), y), Offset(w * (0.68 + t * 0.32), y), floorPaint);
    }

    final windowPaint = Paint()
      ..color = const Color(0xFFC5FF9E).withValues(alpha: 0.2 + phase * 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.04, h * 0.1, w * 0.1, h * 0.17),
        const Radius.circular(30),
      ),
      windowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.86, h * 0.13, w * 0.1, h * 0.19),
        const Radius.circular(30),
      ),
      windowPaint,
    );

    final vignette = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.transparent, Color(0xCC000000)],
        stops: [0.35, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _CinematicHallPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

/// Custom painter for the golden orbital swoosh over "VERSE"
class _GoldenSwooshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF38BDF8),
          Color(0xFFF59E0B),
          Color(0xFFF97316),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(4, size.height - 4);
    path.quadraticBezierTo(
      size.width * 0.45,
      -6,
      size.width - 8,
      size.height * 0.4,
    );
    canvas.drawPath(path, paint);

    // Sparkle star at apex
    final starPaint = Paint()..color = const Color(0xFFF59E0B);
    canvas.drawCircle(Offset(size.width * 0.52, 2), 2.5, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
