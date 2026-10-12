import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// GSAP-Inspired Kinetic Quantum Loader for TEC-VERSE.
///
/// Replicates GreenSock (GSAP) high-precision timeline physics:
/// - Staggered multi-axis kinetic rotation
/// - Elastic bezier easing curves (`power3.inOut` & `elastic.out`)
/// - Orbiting quantum photon satellites with glowing luminescence trails
/// - Breathing central quantum nucleus
class GsapQuantumLoader extends StatefulWidget {
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;
  final String? message;
  final bool showGlow;

  const GsapQuantumLoader({
    super.key,
    this.size = 54.0,
    this.primaryColor,
    this.secondaryColor,
    this.message,
    this.showGlow = true,
  });

  @override
  State<GsapQuantumLoader> createState() => _GsapQuantumLoaderState();
}

class _GsapQuantumLoaderState extends State<GsapQuantumLoader>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _satelliteController;

  late Animation<double> _rotationAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _satelliteAnim;

  @override
  void initState() {
    super.initState();

    // 1. GSAP Power3-style kinetic rotation controller (1800ms)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _rotationAnim = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOutCubic,
    );

    // 2. GSAP Elastic breathing pulse controller (1400ms)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );

    // 3. Staggered Satellite Orbital controller (2400ms)
    _satelliteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _satelliteAnim = CurvedAnimation(
      parent: _satelliteController,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _satelliteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectivePrimary = widget.primaryColor ?? AppColors.primaryOrange;
    final effectiveSecondary = widget.secondaryColor ?? AppColors.emeraldSuccess;

    Widget loader = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationController,
          _pulseController,
          _satelliteController,
        ]),
        builder: (context, _) {
          return CustomPaint(
            painter: _GsapQuantumPainter(
              rotationProgress: _rotationAnim.value,
              pulseProgress: _pulseAnim.value,
              satelliteProgress: _satelliteAnim.value,
              primaryColor: effectivePrimary,
              secondaryColor: effectiveSecondary,
              showGlow: widget.showGlow,
            ),
          );
        },
      ),
    );

    if (widget.message != null && widget.message!.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          loader,
          const SizedBox(height: 16),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }

    return loader;
  }
}

class _GsapQuantumPainter extends CustomPainter {
  final double rotationProgress;
  final double pulseProgress;
  final double satelliteProgress;
  final Color primaryColor;
  final Color secondaryColor;
  final bool showGlow;

  _GsapQuantumPainter({
    required this.rotationProgress,
    required this.pulseProgress,
    required this.satelliteProgress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    // ─── 1. Outer Cybernetic Kinetic Arc Brackets ───
    final outerRadius = baseRadius * 0.88;
    final bracketPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, size.width * 0.05)
      ..strokeCap = StrokeCap.round;

    if (showGlow) {
      bracketPaint.maskFilter = MaskFilter.blur(BlurStyle.solid, size.width * 0.04);
    }

    final rotationAngle = rotationProgress * 2 * math.pi;

    // Primary Orange Arc
    bracketPaint.shader = SweepGradient(
      startAngle: 0.0,
      endAngle: math.pi,
      colors: [
        primaryColor.withValues(alpha: 0.05),
        primaryColor,
      ],
      transform: GradientRotation(rotationAngle),
    ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      rotationAngle,
      math.pi * 0.82,
      false,
      bracketPaint,
    );

    // Secondary Green Arc (Counter-rotated for GSAP opposing momentum)
    final opposingAngle = -rotationAngle * 1.35;
    bracketPaint.shader = SweepGradient(
      startAngle: 0.0,
      endAngle: math.pi,
      colors: [
        secondaryColor.withValues(alpha: 0.05),
        secondaryColor,
      ],
      transform: GradientRotation(opposingAngle),
    ).createShader(Rect.fromCircle(center: center, radius: outerRadius * 0.74));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius * 0.74),
      opposingAngle,
      math.pi * 0.75,
      false,
      bracketPaint,
    );

    // ─── 2. Orbiting Quantum Photons (Satellites) ───
    final numSatellites = 3;
    for (int i = 0; i < numSatellites; i++) {
      final angle = (satelliteProgress * 2 * math.pi) + (i * (2 * math.pi / numSatellites));
      final orbitRadius = outerRadius * (0.65 + (i * 0.08) * math.sin(pulseProgress * math.pi));
      final satX = center.dx + orbitRadius * math.cos(angle);
      final satY = center.dy + orbitRadius * math.sin(angle);
      final satPos = Offset(satX, satY);

      final satColor = i.isEven ? primaryColor : secondaryColor;
      final satSize = math.max(2.2, size.width * 0.055);

      if (showGlow) {
        final glowPaint = Paint()
          ..color = satColor.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, satSize * 1.8);
        canvas.drawCircle(satPos, satSize * 1.6, glowPaint);
      }

      final satPaint = Paint()
        ..color = satColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(satPos, satSize, satPaint);
    }

    // ─── 3. Breathing Central Quantum Nucleus ───
    final coreRadius = baseRadius * (0.20 + (pulseProgress * 0.08));
    final coreGlowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35 + (pulseProgress * 0.35))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, coreRadius * 1.4);
    canvas.drawCircle(center, coreRadius * 1.4, coreGlowPaint);

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          primaryColor,
          primaryColor.withValues(alpha: 0.8),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius));
    canvas.drawCircle(center, coreRadius, corePaint);
  }

  @override
  bool shouldRepaint(covariant _GsapQuantumPainter oldDelegate) {
    return oldDelegate.rotationProgress != rotationProgress ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.satelliteProgress != satelliteProgress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}

/// GSAP Staggered Elastic Wave Bar Loader (Compact & Neat for Buttons / Headers).
///
/// Simulates GSAP `gsap.to('.bar', { scaleY: 2.2, stagger: 0.12, ease: 'sine.inOut' })`
class GsapElasticWaveLoader extends StatefulWidget {
  final double height;
  final int barCount;
  final Color? color;
  final double spacing;

  const GsapElasticWaveLoader({
    super.key,
    this.height = 18.0,
    this.barCount = 4,
    this.color,
    this.spacing = 3.5,
  });

  @override
  State<GsapElasticWaveLoader> createState() => _GsapElasticWaveLoaderState();
}

class _GsapElasticWaveLoaderState extends State<GsapElasticWaveLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.primaryOrange;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.barCount, (index) {
            // Calculate GSAP staggered phase shift
            final progress = (_controller.value + (index * 0.18)) % 1.0;
            // Elastic sine wave calculation
            final wave = math.sin(progress * math.pi);
            final scale = 0.35 + (wave * 0.65);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              width: math.max(3.0, widget.height * 0.18),
              height: widget.height * scale,
              decoration: BoxDecoration(
                color: effectiveColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: 0.3 * wave),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

/// GSAP Fullscreen & Modal Glassmorphism Loading Overlay.
///
/// Smoothly displays a futuristic backdrop blur and kinetic GSAP Quantum loader
/// during long-running async tasks (Auth, Pass generation, Payment, Sync).
class GsapLoadingOverlay {
  GsapLoadingOverlay._();

  /// Show a modal GSAP loading dialog
  static Future<T?> show<T>({
    required BuildContext context,
    String message = 'Processing Request...',
    String? subMessage,
    bool barrierDismissible = false,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Loading',
      barrierColor: const Color(0xFF0F172A).withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curvedAnim),
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withValues(alpha: 0.18),
                    blurRadius: 32,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF102A43).withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GsapQuantumLoader(
                        size: 64,
                        showGlow: true,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subMessage != null && subMessage.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subMessage,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const GsapElasticWaveLoader(
                        height: 12,
                        barCount: 5,
                        spacing: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Dismiss the active loading overlay
  static void hide(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
