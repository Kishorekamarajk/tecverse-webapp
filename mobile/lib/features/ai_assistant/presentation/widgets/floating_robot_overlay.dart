import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/navigation/voice_navigation_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animation_utils.dart';
import '../ai_assistant_screen.dart';
import 'voice_assistant_modal.dart';

/// Global Draggable & Floating Robot Chatbot Widget rendered persistently across all screens.
///
/// Provides:
/// - Glowing animated robot avatar with pulsing acoustic aura and glowing eye lights
/// - Free-form dragging and edge docking across screen bounds
/// - One-tap Voice Assistant launcher & full Chatbot Copilot screen
/// - Dynamic voice navigation trigger ("Go to...")
class FloatingRobotOverlay extends StatefulWidget {
  final Widget child;

  const FloatingRobotOverlay({
    super.key,
    required this.child,
  });

  @override
  State<FloatingRobotOverlay> createState() => _FloatingRobotOverlayState();
}

class _FloatingRobotOverlayState extends State<FloatingRobotOverlay>
    with SingleTickerProviderStateMixin {
  // Draggable position coordinates (defaults to bottom-right corner above profile navigation)
  Offset? _position;
  bool _isDragging = false;
  bool _showTooltip = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Auto-hide tooltip after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _showTooltip = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openVoiceAssistant() {
    final context = VoiceNavigationService.navigatorKey.currentContext;
    if (context != null) {
      VoiceAssistantModal.show(context);
    }
  }

  void _openChatScreen() {
    final nav = VoiceNavigationService.navigatorKey.currentState;
    if (nav != null) {
      nav.push(
        MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
      );
    }
  }

  void _showRobotOptionsSheet() {
    final context = VoiceNavigationService.navigatorKey.currentContext;
    if (context == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TEC-VERSE AI Robot',
                        style: AppTypography.headlineMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Hands-free Voice Navigation & Delegate Q&A',
                        style: AppTypography.metaTag.copyWith(
                          fontSize: 10,
                          color: AppColors.cyanAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ScaleOnPress(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _openVoiceAssistant();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryOrange, Color(0xFFFF9E66)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryOrange.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Voice Assistant',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ScaleOnPress(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _openChatScreen();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.4), width: 1.2),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, color: AppColors.cyanAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Chat Support',
                              style: TextStyle(
                                color: AppColors.cyanAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The entire app content
        widget.child,

        // Persistent Floating Robot Symbol
        ValueListenableBuilder<bool>(
          valueListenable: VoiceNavigationService.isRobotVisible,
          builder: (context, visible, _) {
            if (!visible) return const SizedBox.shrink();

            final screenSize = MediaQuery.of(context).size;
            // Default position: bottom-right corner directly above the profile navigation tab
            final currentPos = _position ?? Offset(screenSize.width - 76.0, screenSize.height - 148.0);
            final clampedX = currentPos.dx.clamp(12.0, math.max(12.0, screenSize.width - 76.0)).toDouble();
            final clampedY = currentPos.dy.clamp(60.0, math.max(60.0, screenSize.height - 130.0)).toDouble();

            return Positioned(
              left: clampedX,
              top: clampedY,
              child: _buildDraggableRobotBody(screenSize, clampedX, clampedY),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDraggableRobotBody(Size screenSize, double posX, double posY) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulseVal = _pulseController.value;

        return GestureDetector(
          onPanStart: (_) {
            setState(() {
              _position ??= Offset(posX, posY);
              _isDragging = true;
              _showTooltip = false;
            });
          },
          onPanUpdate: (details) {
            setState(() {
              final cur = _position ?? Offset(posX, posY);
              _position = Offset(
                cur.dx + details.delta.dx,
                cur.dy + details.delta.dy,
              );
            });
          },
          onPanEnd: (_) {
            setState(() {
              _isDragging = false;
            });
          },
          onTap: _showRobotOptionsSheet,
          onDoubleTap: _openVoiceAssistant,
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: posX > screenSize.width / 2
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Speech Tooltip Banner (Auto-dismissed or toggled)
                if (_showTooltip && !_isDragging)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mic_rounded, size: 12, color: AppColors.primaryOrange),
                        const SizedBox(width: 4),
                        Text(
                          'Say "Go to sessions"',
                          style: AppTypography.metaTag.copyWith(
                            fontSize: 9.5,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Futuristic Robot Orb Avatar
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Pulsing Glow Wave Ring
                    Container(
                      width: 64 + (pulseVal * 8),
                      height: 64 + (pulseVal * 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryOrange.withValues(alpha: 0.35 * (1.0 - pulseVal)),
                          width: 1.6,
                        ),
                      ),
                    ),

                    // Central Robot Shell
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0F2B48),
                            Color(0xFF1E3A5F),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.primaryOrange.withValues(alpha: 0.8 + (pulseVal * 0.2)),
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withValues(alpha: 0.35 + (pulseVal * 0.2)),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: AppColors.cyanAccent.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Robot Face Icon
                          const Icon(
                            Icons.smart_toy_rounded,
                            color: Colors.white,
                            size: 28,
                          ),

                          // Live status beacon on top right of robot
                          Positioned(
                            top: 5,
                            right: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.emeraldSuccess,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.emeraldSuccess.withValues(alpha: 0.8),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Mic badge indicator on bottom right
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryOrange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mic_rounded,
                                color: Colors.white,
                                size: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
