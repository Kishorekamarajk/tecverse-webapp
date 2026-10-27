import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/storage/session_manager.dart';
import '../../../core/widgets/animation_utils.dart';
import '../../../navigation/app_router.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../digital_pass/presentation/digital_pass_controller.dart';
import '../../digital_pass/presentation/digital_pass_screen.dart';
import '../../floor_plan/presentation/floor_plan_screen.dart';
import '../../location/presentation/widgets/location_preview_card.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../schedule/presentation/schedule_screen.dart';
import 'widgets/digital_pass_banner.dart';
import 'widgets/latest_news_card.dart';
import 'widgets/latest_news_sheet.dart';
import '../../notifications/presentation/widgets/notifications_sheet.dart';
import '../data/event_repository.dart';
import '../domain/important_date_item.dart';

/// Tec-Verse 2026 Executive Home Screen matching the reference design.
class PersonalizedHomeScreen extends StatefulWidget {
  final void Function(int)? onNavigateTab;

  const PersonalizedHomeScreen({super.key, this.onNavigateTab});

  @override
  State<PersonalizedHomeScreen> createState() => _PersonalizedHomeScreenState();
}

class _PersonalizedHomeScreenState extends State<PersonalizedHomeScreen> {
  final EventRepository _eventRepository = EventRepository();
  List<ImportantDateItem> _importantDates = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initUserData();
      _fetchLiveEventData();
    });
  }

  Future<void> _fetchLiveEventData() async {
    try {
      final dates = await _eventRepository.fetchImportantDates();
      if (mounted && dates.isNotEmpty) {
        setState(() {
          _importantDates = dates;
        });
      }
    } catch (_) {}
  }

  void _initUserData() {
    final auth = context.read<AuthController>();
    final session = context.read<SessionManager>();
    final passCtrl = context.read<DigitalPassController>();

    if (auth.currentUser != null && session.accessToken != null) {
      passCtrl.loadPass(token: session.accessToken!, user: auth.currentUser!);
    }
  }

  void _navigateToSessions() {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(1);
    } else {
      Navigator.of(context).pushNamed(AppRouter.sessions);
    }
  }

  void _navigateToSchedule() {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(2);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ScheduleScreen()),
      );
    }
  }

  void _navigateToPass() {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(3);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DigitalPassScreen()),
      );
    }
  }

  void _navigateToProfile() {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(5);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  void _navigateToFloorPlan({String? hallId}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FloorPlanScreen(initialHallId: hallId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      body: Consumer2<AuthController, DigitalPassController>(
        builder: (context, auth, passCtrl, _) {
          final user = auth.currentUser;
          final pass = passCtrl.pass;

          final initials = user != null && user.officialName.isNotEmpty
              ? user.officialName
                  .trim()
                  .split(' ')
                  .map((s) => s.isNotEmpty ? s[0] : '')
                  .take(2)
                  .join()
                  .toUpperCase()
              : (pass != null && pass.holderName.isNotEmpty
                  ? pass.holderName
                      .trim()
                      .split(' ')
                      .map((s) => s.isNotEmpty ? s[0] : '')
                      .take(2)
                      .join()
                      .toUpperCase()
                  : 'KK');

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 840;
              final contentMaxWidth = isDesktop ? 1080.0 : 720.0;
              final horizontalPadding = isDesktop ? 32.0 : 16.0;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  // 1. TOP HEADER APP BAR
                  SliverAppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    pinned: true,
                    floating: true,
                    toolbarHeight: 68,
                    titleSpacing: isDesktop ? horizontalPadding : 16.0,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(1.0),
                      child: Container(
                        color: const Color(0xFFF1E6DF),
                        height: 1.0,
                      ),
                    ),
                    title: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Globe Logo Icon
                          Image.asset(
                            'assets/images/app_logo.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0284C7),
                              ),
                              child: const Icon(Icons.public, color: Colors.white, size: 24),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Tec-Verse',
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                      color: Color(0xFF102A43),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEA580C),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '2026',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'CHENNAI • NOV 26–27',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF64748B),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      // Notification Bell Button
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ScaleOnPress(
                          onTap: () {
                            NotificationsSheet.show(
                              context,
                              userRef: user?.referenceNumber,
                            );
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFF1E6DF),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_outlined,
                                  color: Color(0xFF102A43),
                                  size: 20,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 9,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEA580C),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Profile Avatar Button with KK initials
                      Padding(
                        padding: EdgeInsets.only(
                          right: isDesktop ? horizontalPadding : 16.0,
                        ),
                        child: ScaleOnPress(
                          onTap: _navigateToProfile,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7F2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFD4BE),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFEA580C),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // MAIN SCROLLABLE CONTENT BODY
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      14,
                      horizontalPadding,
                      96 + MediaQuery.of(context).padding.bottom,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentMaxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 2. HERO EVENT AREA
                              FadeSlideTransition(
                                delay: Duration.zero,
                                child: _buildHeroBannerCard(),
                              ),

                              const SizedBox(height: 16),

                              // 3. DIGITAL EVENT PASS TICKET CREDENTIAL
                              FadeSlideTransition(
                                delay: const Duration(milliseconds: 60),
                                child: DigitalPassBanner(
                                  pass: pass,
                                  user: user,
                                  onTap: _navigateToPass,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // 4. QUICK ACTION TILES (4 Horizontal Cards)
                              FadeSlideTransition(
                                delay: const Duration(milliseconds: 110),
                                child: _buildQuickActionTiles(),
                              ),

                              const SizedBox(height: 20),

                              // 5. EVENT LOCATION & MAP CARD
                              const FadeSlideTransition(
                                delay: Duration(milliseconds: 140),
                                child: LocationPreviewCard(),
                              ),

                              const SizedBox(height: 22),

                              // 6. LATEST NEWS & IMPORTANT DATES (only once live data has loaded)
                              if (_importantDates.isNotEmpty) ...[
                                FadeSlideTransition(
                                  delay: const Duration(milliseconds: 180),
                                  child: _buildLatestNewsHeader(),
                                ),
                                const SizedBox(height: 12),
                              ],

                              ..._importantDates.take(3).toList().asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;

                                return FadeSlideTransition(
                                  delay: Duration(milliseconds: 220 + (index * 40)),
                                  child: LatestNewsCard(
                                    item: item,
                                    onTap: () => LatestNewsSheet.showItemDetail(context, item),
                                  ),
                                );
                              }),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// 2. HERO BANNER CARD matching screenshot
  Widget _buildHeroBannerCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1E6DF), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Right Side Background Illustration / Glow
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 180,
              child: Opacity(
                opacity: 0.35,
                child: Image.asset(
                  'assets/images/trade.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Warm Gradient Lighting Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.96),
                      Colors.white.withValues(alpha: 0.70),
                      const Color(0xFFFFF3EC).withValues(alpha: 0.45),
                    ],
                    stops: const [0.0, 0.45, 0.75, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title: Tec-Verse 2026
                  const Text.rich(
                    TextSpan(
                      text: 'Tec-Verse',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: Color(0xFF102A43),
                      ),
                      children: [
                        WidgetSpan(child: SizedBox(width: 8)),
                        TextSpan(
                          text: '2026',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Tagline
                  const Text(
                    'Connect. Collaborate.Innovate',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Meta Dates & Location
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Color(0xFFEA580C),
                      ),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          '26–27 NOVEMBER 2026',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: Color(0xFFEA580C),
                      ),
                      const SizedBox(width: 5),
                      const Flexible(
                        child: Text(
                          'CHENNAI TRADE CENTRE, CHENNAI, TAMIL NADU',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Floating Live Countdown / "LIVE NOW" pill on bottom right
                  Align(
                    alignment: Alignment.bottomRight,
                    child: HeroLiveCountdownWidget(
                      onTap: _navigateToSchedule,
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

  /// 4. QUICK ACTION TILES: compact, elegant cards matching reference design
  Widget _buildQuickActionTiles() {
    return Row(
      children: [
        Expanded(
          child: _quickTile(
            icon: Icons.hub_rounded,
            label: 'Sessions',
            onTap: _navigateToSessions,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickTile(
            icon: Icons.calendar_month_outlined,
            label: 'Schedule',
            onTap: _navigateToSchedule,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _quickTile(
            icon: Icons.map_outlined,
            label: 'Floor Plan',
            onTap: () => _navigateToFloorPlan(),
          ),
        ),
      ],
    );
  }

  Widget _quickTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ScaleOnPress(
      onTap: onTap,
      scaleFactor: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1E6DF), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.05),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(0xFF102A43).withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFEA580C), size: 24),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF102A43),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 12,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 5. LATEST NEWS HEADER (Matches reference design)
  Widget _buildLatestNewsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3EC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  size: 18,
                  color: Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Tec-Verse Latest News',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => LatestNewsSheet.showAllNews(context, _importantDates),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See All',
                  style: TextStyle(
                    color: Color(0xFFEA580C),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: Color(0xFFEA580C),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Dynamic Live Countdown / LIVE NOW widget for Hero Event Banner
class HeroLiveCountdownWidget extends StatefulWidget {
  final VoidCallback? onTap;

  const HeroLiveCountdownWidget({super.key, this.onTap});

  @override
  State<HeroLiveCountdownWidget> createState() => _HeroLiveCountdownWidgetState();
}

class _HeroLiveCountdownWidgetState extends State<HeroLiveCountdownWidget> {
  static final DateTime _eventStart = DateTime.parse('2026-11-26T09:00:00+05:30');
  static final DateTime _eventEnd = DateTime.parse('2026-11-27T18:00:00+05:30');

  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isLive = false;
  bool _isConcluded = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    if (now.isBefore(_eventStart)) {
      final diff = _eventStart.difference(now);
      if (mounted) {
        setState(() {
          _isLive = false;
          _isConcluded = false;
          _remaining = diff.isNegative ? Duration.zero : diff;
        });
      }
    } else if (now.isBefore(_eventEnd)) {
      if (mounted) {
        setState(() {
          _isLive = true;
          _isConcluded = false;
          _remaining = Duration.zero;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLive = false;
          _isConcluded = true;
          _remaining = Duration.zero;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    if (_isLive) {
      // 🔴 LIVE NOW animated pulsing badge
      return ScaleOnPress(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeroPulseDot(color: Color(0xFFDC2626)),
              SizedBox(width: 6),
              Text(
                'LIVE NOW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFDC2626),
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: Color(0xFFDC2626),
              ),
            ],
          ),
        ),
      );
    }

    if (_isConcluded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
        ),
        child: const Text(
          'EVENT CONCLUDED',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    // ⏳ Active Live Countdown Ticking Timer
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return ScaleOnPress(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD4BE), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _HeroPulseDot(color: Color(0xFFEA580C)),
            const SizedBox(width: 6),
            Text(
              '${days}d : ${_twoDigits(hours)}h : ${_twoDigits(minutes)}m : ${_twoDigits(seconds)}s',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF102A43),
                letterSpacing: 0.3,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 13,
              color: Color(0xFFEA580C),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPulseDot extends StatefulWidget {
  final Color color;

  const _HeroPulseDot({required this.color});

  @override
  State<_HeroPulseDot> createState() => _HeroPulseDotState();
}

class _HeroPulseDotState extends State<_HeroPulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        width: 6.5,
        height: 6.5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _anim.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _anim.value * 0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
