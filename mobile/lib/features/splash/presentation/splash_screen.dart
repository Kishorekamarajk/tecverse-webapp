import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../../navigation/app_router.dart';

/// Cinematic TEC-VERSE 2026 intro with a corridor, subtle T mark, live countdown, zoom reveal, and timed loading progress.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Continuous rotation for orbital rings and floating tech badges
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _zoomController;
  late Timer _countdownTimer;

  double _currentProgress = 0.0;
  Duration _countdownRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();

    // 1. Smooth slow rotation for orbital tracks (16s cycle)
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    // 2. Pulse / breathing glow animation (2.5s cycle)
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

    _progressController.addListener(() {
      if (mounted) {
        setState(() {
          _currentProgress = _progressController.value;
        });
      }
    });

    _startLoadingSequence();
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
    _orbitController.dispose();
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
                        'TEC-VERSE 2026  ·  CHENNAI',
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
  // 1. TOP GLOBE + HOLOGRAPHIC PEDESTAL + 6 ORBITING TECH NODES
  // ===========================================================================
  Widget _buildGlobeWithOrbitalNodes() {
    return SizedBox(
      width: 320,
      height: 290,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background subtle concentric orbit guide rings
          CustomPaint(
            size: const Size(320, 280),
            painter: _OrbitalTrackPainter(
              pulseValue: _pulseController,
            ),
          ),

          // Glowing Holographic Pedestal at the bottom
          Positioned(
            bottom: 4,
            child: _buildHolographicPedestal(),
          ),

          // Central 3D Globe with atmosphere glow & planetary rings
          Positioned(
            top: 28,
            child: _buildCentralGlobe(),
          ),

          // Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬ 6 Orbiting Tech Domain Badges Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
          // 1. Chip / Microprocessor Node (Top Center-Left - Orange)
          _buildFloatingBadge(
            left: 78,
            top: 10,
            icon: Icons.memory_rounded,
            badgeColor: const Color(0xFFEA580C),
            bgLight: const Color(0xFFFFF7ED),
            orbitAngleOffset: 0.0,
          ),

          // 2. Settings / Cog Node (Top Right - Blue)
          _buildFloatingBadge(
            right: 68,
            top: 24,
            icon: Icons.settings_rounded,
            badgeColor: const Color(0xFF0284C7),
            bgLight: const Color(0xFFEFF6FF),
            orbitAngleOffset: math.pi / 3,
          ),

          // 3. Satellite / Radar Comms Node (Middle Left - Blue)
          _buildFloatingBadge(
            left: 32,
            top: 76,
            icon: Icons.satellite_alt_rounded,
            badgeColor: const Color(0xFF1D4ED8),
            bgLight: const Color(0xFFEFF6FF),
            orbitAngleOffset: 2 * math.pi / 3,
          ),

          // 4. Analytics / Growth Chart Node (Middle Right - Orange)
          _buildFloatingBadge(
            right: 36,
            top: 106,
            icon: Icons.bar_chart_rounded,
            badgeColor: const Color(0xFFF97316),
            bgLight: const Color(0xFFFFF7ED),
            orbitAngleOffset: math.pi,
          ),

          // 5. Cloud Computing Node (Bottom Left - Sky Blue)
          _buildFloatingBadge(
            left: 34,
            top: 154,
            icon: Icons.cloud_rounded,
            badgeColor: const Color(0xFF0EA5E9),
            bgLight: const Color(0xFFF0F9FF),
            orbitAngleOffset: 4 * math.pi / 3,
          ),

          // 6. Eco / Green Deep-Tech Node (Bottom Right - Teal Green)
          _buildFloatingBadge(
            right: 40,
            top: 148,
            icon: Icons.eco_rounded,
            badgeColor: const Color(0xFF059669),
            bgLight: const Color(0xFFECFDF5),
            orbitAngleOffset: 5 * math.pi / 3,
          ),
        ],
      ),
    );
  }

  /// Central 3D Globe with planetary orbital glow rings
  Widget _buildCentralGlobe() {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbitController, _pulseController]),
      builder: (context, child) {
        final pulse = _pulseController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer atmospheric neon aura
            Container(
              width: 174 + (pulse * 10),
              height: 174 + (pulse * 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.35),
                    const Color(0xFF0284C7).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Globe Image / Shader Sphere
            Container(
              width: 154,
              height: 154,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF1E40AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.public, color: Colors.white, size: 76),
                    ),
                  ),
                ),
              ),
            ),

            // Planetary Holographic Orbit Ring with Light Streaks
            Transform.rotate(
              angle: -0.35 + (math.sin(_orbitController.value * 2 * math.pi) * 0.08),
              child: Container(
                width: 200,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.75),
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),

            // Secondary Golden Glowing Orbit Ring
            Transform.rotate(
              angle: 0.28 + (math.cos(_orbitController.value * 2 * math.pi) * 0.06),
              child: Container(
                width: 184,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: const Color(0xFFF97316).withValues(alpha: 0.7),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Holographic Pedestal at the bottom of the globe
  Widget _buildHolographicPedestal() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top glowing light plate
        Container(
          width: 130,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.6),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
        ),

        const SizedBox(height: 2),

        // Stepped metallic blue platform rings
        Container(
          width: 180,
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0284C7),
                Color(0xFF38BDF8),
                Color(0xFF0284C7),
              ],
            ),
            border: Border.all(color: const Color(0xFFBAE6FD), width: 1.0),
          ),
        ),

        const SizedBox(height: 2),

        // Base broad reflective glow ring
        Container(
          width: 240,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0C4A6E).withValues(alpha: 0.8),
                const Color(0xFF0284C7),
                const Color(0xFF38BDF8),
                const Color(0xFF0284C7),
                const Color(0xFF0C4A6E).withValues(alpha: 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Individual Floating Badge on Orbit
  Widget _buildFloatingBadge({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required IconData icon,
    required Color badgeColor,
    required Color bgLight,
    required double orbitAngleOffset,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: _orbitController,
        builder: (context, child) {
          final t = _orbitController.value * 2 * math.pi + orbitAngleOffset;
          final dy = math.sin(t) * 3.5;
          final dx = math.cos(t) * 2.0;

          return Transform.translate(
            offset: Offset(dx, dy),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bgLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 2. BRAND TITLE SECTION (TEC-VERSE 2026 + Golden Orbit Swoosh)
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

  // ===========================================================================
  // 3. TAGLINE
  // ===========================================================================
  Widget _buildTagline() {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF475569),
          letterSpacing: 0.2,
        ),
        children: [
          TextSpan(
            text: 'Bridging Research. ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: 'Building the Future.',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. VENUE & DATE CAPSULE
  // ===========================================================================
  Widget _buildVenueDateCapsule() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Location Pin + Chennai Trade Centre
          const Icon(
            Icons.location_on_rounded,
            color: Color(0xFFEA580C),
            size: 16,
          ),
          const SizedBox(width: 5),
          const Text(
            'CHENNAI TRADE CENTRE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: 0.4,
            ),
          ),

          const SizedBox(width: 10),

          // Divider
          Container(
            width: 1,
            height: 14,
            color: const Color(0xFFCBD5E1),
          ),

          const SizedBox(width: 10),

          // Calendar Icon + Nov 26-27, 2026
          const Icon(
            Icons.calendar_month_rounded,
            color: Color(0xFFEA580C),
            size: 16,
          ),
          const SizedBox(width: 5),
          const Text(
            'NOV 26Ã¢â‚¬â€œ27, 2026',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. LOADING PROGRESS BAR WITH GLOWING KNOB & PERCENTAGE
  // ===========================================================================
  Widget _buildLoadingProgressBar() {
    final percentInt = (_currentProgress * 100).clamp(0, 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Glowing Gradient Capsule Progress Track
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                // Filled progress bar
                FractionallySizedBox(
                  widthFactor: _currentProgress.clamp(0.02, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0284C7),
                          Color(0xFF06B6D4),
                          Color(0xFFF97316),
                          Color(0xFFEA580C),
                        ],
                        stops: [0.0, 0.4, 0.8, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.45),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),

                // Glowing Leading Knob
                Align(
                  alignment: Alignment(-1.0 + (2.0 * _currentProgress.clamp(0.02, 1.0)), 0.0),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEA580C),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Loading Text & Percentage Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Loading TEC-VERSE 2026...',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                '$percentInt%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFEA580C),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. BOTTOM BACKDROP (Panoramic Convention Centre Architecture + Light Trails)
  // ===========================================================================
  Widget _buildBottomBackdrop() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Panoramic Convention Centre Architecture Image
        Image.asset(
          'assets/images/conbanner.png',
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            'assets/images/banner.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),

        // Gradient overlay to blend seamlessly into white top background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white.withValues(alpha: 0.85),
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.65),
                Colors.white.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.18, 0.5, 0.85, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 7. FOOTER ATTRIBUTION (C-DAC Badge & CSC Consortium)
  // ===========================================================================
  Widget _buildFooterAttribution() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pill: Designed and Developed by C-DAC
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFEA580C),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(text: 'Designed and Developed by '),
                    TextSpan(
                      text: 'C-DAC',
                      style: TextStyle(
                        color: Color(0xFFEA580C),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Consortium Subtitle
        const Text(
          'Consortium of scientific societies (CSC) Ã¢â‚¬Â¢ MeitY Ã¢â‚¬Â¢ C-DAC Ã¢â‚¬Â¢ SAMEER Ã¢â‚¬Â¢ C-MET',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

/// Custom painter for the orbital dotted rings and constellation connection arcs
class _OrbitalTrackPainter extends CustomPainter {
  final Animation<double> pulseValue;

  _OrbitalTrackPainter({required this.pulseValue})
      : super(repaint: pulseValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 10);

    // Inner orbital circle
    final innerPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 90, innerPaint);

    // Middle orbital dotted track
    final middlePaint = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, 120, middlePaint);

    // Outer faint orbital track
    final outerPaint = Paint()
      ..color = const Color(0xFFF97316).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 142, outerPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitalTrackPainter oldDelegate) => true;
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
