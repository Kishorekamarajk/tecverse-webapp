import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// TEC-VERSE Premium Light Ambient Background.
///
/// Features:
/// - Very light lavender / off-white base
/// - Soft radial glows: warm orange (top-right), fresh green (bottom-left), 
///   and cool navy (center-right) — all extremely subtle (< 8% opacity)
/// - Barely-visible dot-grid texture for depth
/// - Slow, gentle floating nodes for life
/// - Isolated via [RepaintBoundary] & [IgnorePointer] for 60/120 FPS.
class TecVerseAmbientBackground extends StatefulWidget {
  final Widget child;

  const TecVerseAmbientBackground({super.key, required this.child});

  @override
  State<TecVerseAmbientBackground> createState() =>
      _TecVerseAmbientBackgroundState();
}

class _TecVerseAmbientBackgroundState extends State<TecVerseAmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Lavender base
        Container(color: AppColors.background),

        // 2. Subtle atmospheric ambient glows
        IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Warm orange glow — top-right
              Positioned(
                top: -180,
                right: -120,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryOrange.withValues(alpha: 0.055),
                        AppColors.primaryOrangeLight.withValues(alpha: 0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Fresh green glow — bottom-left
              Positioned(
                bottom: -160,
                left: -100,
                child: Container(
                  width: 480,
                  height: 480,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondaryGreen.withValues(alpha: 0.05),
                        AppColors.secondaryGreen.withValues(alpha: 0.015),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Cool navy glow — mid right
              Positioned(
                top: 300,
                right: -80,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.darkNavy.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Dot-grid & slow floating nodes
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _LightAmbientPainter(_controller.value),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // 3. Foreground UI
        widget.child,
      ],
    );
  }
}

class _LightAmbientPainter extends CustomPainter {
  final double progress;

  _LightAmbientPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Very faint dot grid
    final dotPaint = Paint()
      ..color = const Color(0xFF102A43).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const double step = 48.0;
    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }

    // Calm floating micro-nodes
    final nodePaint = Paint()..style = PaintingStyle.fill;
    const int count = 8;
    for (int i = 0; i < count; i++) {
      final double seed = i * 2.618;
      final double x =
          (math.sin(seed + progress * 2 * math.pi) * 0.40 + 0.5) * size.width;
      final double y =
          (math.cos(seed * 1.3 + progress * 2 * math.pi) * 0.40 + 0.5) *
              size.height;
      final double opacity =
          (0.06 + 0.08 * math.sin(progress * 2 * math.pi + i))
              .clamp(0.03, 0.12);

      if (i % 3 == 0) {
        nodePaint.color = AppColors.primaryOrange.withValues(alpha: opacity);
      } else if (i % 3 == 1) {
        nodePaint.color = AppColors.secondaryGreen.withValues(alpha: opacity);
      } else {
        nodePaint.color = AppColors.darkNavy.withValues(alpha: opacity * 0.6);
      }

      canvas.drawCircle(Offset(x, y), 1.6, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LightAmbientPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Backward compatibility alias.
typedef FuturisticBackground = TecVerseAmbientBackground;
