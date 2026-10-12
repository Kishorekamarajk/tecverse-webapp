import 'package:flutter/material.dart';
import '../core/navigation/voice_navigation_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/animation_utils.dart';
import '../features/about/presentation/about_screen.dart';
import '../features/digital_pass/presentation/digital_pass_screen.dart';
import '../features/floor_plan/presentation/floor_plan_screen.dart';
import '../features/home/presentation/personalized_home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/schedule/presentation/schedule_screen.dart';
import '../features/sessions/presentation/sessions_screen.dart';

/// Adaptive Navigation Shell for TEC-VERSE 2026.
///
/// Responsive Behavior:
/// - Mobile: Compact, floating-style bottom navigation bar with frosted glass blur.
/// - Desktop/Windows/Tablet (>840px): Elegant navigation rail with brand emblem and multi-column workspace.
class MainScaffold extends StatefulWidget {
  final int initialIndex;

  const MainScaffold({super.key, this.initialIndex = 0});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    VoiceNavigationService.onTabChangeRequested = _onTabSelected;
  }

  @override
  void dispose() {
    if (VoiceNavigationService.onTabChangeRequested == _onTabSelected) {
      VoiceNavigationService.onTabChangeRequested = null;
    }
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 840;

        final screens = [
          PersonalizedHomeScreen(onNavigateTab: _onTabSelected),
          SessionsScreen(onBackPressed: () => _onTabSelected(0), onNavigateTab: _onTabSelected),
          ScheduleScreen(onBackPressed: () => _onTabSelected(0)),
          DigitalPassScreen(onBackPressed: () => _onTabSelected(0)),
          AboutScreen(onBackPressed: () => _onTabSelected(0), onNavigateTab: _onTabSelected),
          ProfileScreen(onBackPressed: () => _onTabSelected(0)),
        ];

        if (isDesktop) {
          return _buildDesktopLayout(screens);
        }

        return _buildMobileLayout(screens);
      },
    );
  }

  /// Mobile layout with fixed, docked bottom navigation bar and PopScope back handling
  Widget _buildMobileLayout(List<Widget> screens) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar: _buildFixedBottomNav(),
      ),
    );
  }

  /// Desktop / Tablet layout with sleek navigation rail
  Widget _buildDesktopLayout(List<Widget> screens) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Desktop Navigation Rail
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(color: AppColors.borderCard, width: 1.0),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/tecverselogo.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TEC-VERSE',
                              style: AppTypography.headlineMedium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              '2026 EXPO',
                              style: AppTypography.metaTag.copyWith(
                                fontSize: 9.5,
                                color: AppColors.cyanAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Nav Rail Items
                  _railItem(0, Icons.home_rounded, 'Home'),
                  _railItem(1, Icons.category_rounded, 'Sessions'),
                  _railItem(2, Icons.calendar_today_rounded, 'Schedule'),
                  _railItem(3, Icons.qr_code_2_rounded, 'Digital Pass'),
                  _railItem(4, Icons.info_outline_rounded, 'About'),
                  _railItem(5, Icons.person_rounded, 'Profile'),

                  // Nav Rail Floor Plan Action
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FloorPlanScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cyanAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.25), width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.map_rounded, size: 19, color: AppColors.cyanAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Floor Plan',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cyanAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom Venue Info Pill
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FloorPlanScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NANDAMBAKKAM, TAMIL NADU 600089',
                              style: AppTypography.metaTag.copyWith(fontSize: 9.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '26–27 NOV 2026',
                              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Workspace
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
        ],
      ),
    );
  }

  Widget _railItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => _onTabSelected(index),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.cyanAccent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.3), width: 0.8) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: isSelected ? AppColors.cyanAccent : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderCard, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _navTabItem(4, Icons.info_outline_rounded, 'About')),
              // Expanded(child: _navTabItem(1, Icons.category_rounded, 'Sessions')),
              // Expanded(child: _navTabItem(2, Icons.calendar_today_rounded, 'Schedule')),
              // Expanded(child: _navTabItem(3, Icons.qr_code_2_rounded, 'Pass')),
              Expanded(child: _navTabItem(0, Icons.home_rounded, 'Home')),
              Expanded(child: _navTabItem(5, Icons.person_rounded, 'Profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navTabItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return ScaleOnPress(
      onTap: () => _onTabSelected(index),
      scaleFactor: 0.92,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyanAccent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected ? AppColors.cyanAccent : AppColors.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
