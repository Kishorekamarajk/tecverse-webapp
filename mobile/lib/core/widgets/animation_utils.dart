import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Staggered Fade and Slide-Up Entrance Transition.
/// Respects accessibility reduced-motion preferences.
class FadeSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset offset;
  final Curve curve;

  const FadeSlideTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 550),
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.08),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _slideAnimation = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Tactile Scale-On-Press Micro-Interaction.
/// Adds a gentle, subtle spring bounce when interactive cards/buttons are pressed.
class ScaleOnPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;
  final BorderRadius? borderRadius;

  const ScaleOnPress({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.97,
    this.duration = const Duration(milliseconds: 140),
    this.borderRadius,
  });

  @override
  State<ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<ScaleOnPress> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animatedScale = AnimatedScale(
      scale: _isPressed ? widget.scaleFactor : 1.0,
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: widget.child,
    );

    if (widget.onTap == null) {
      return animatedScale;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: animatedScale,
    );
  }
}

/// Modern Glassmorphic Container with Subtle Glow & Border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.borderWidth = 1.0,
    this.gradient,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(18);
    final effectiveBorderColor = borderColor ?? AppColors.borderSubtle;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        gradient: gradient ?? AppColors.cardGradient,
        border: Border.all(color: effectiveBorderColor, width: borderWidth),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: const Color(0xFF102A43).withValues(alpha: 0.07),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            color: Colors.transparent,
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return ScaleOnPress(
        onTap: onTap,
        borderRadius: effectiveRadius,
        child: card,
      );
    }

    return card;
  }
}

/// Modern Reusable Section Header with Category Pill, Title, and Optional Action.
class ModernSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ModernSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.cyanAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.cyanAccent.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Icon(icon, size: 14, color: AppColors.cyanAccent),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              visualDensity: VisualDensity.compact,
              foregroundColor: AppColors.cyanAccent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.cyanAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.cyanAccent),
              ],
            ),
          ),
      ],
    );
  }
}

/// Consistent Technology Domain Chip.
class DomainPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const DomainPill({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.cyanAccent.withValues(alpha: 0.14)
            : AppColors.surfaceElevated.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? AppColors.cyanAccent.withValues(alpha: 0.45)
              : AppColors.borderSubtle,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) ...[
            const Icon(Icons.check_rounded, size: 13, color: AppColors.cyanAccent),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return ScaleOnPress(
        onTap: onTap,
        scaleFactor: 0.96,
        child: child,
      );
    }

    return child;
  }
}
