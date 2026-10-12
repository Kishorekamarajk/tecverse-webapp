import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

import 'gsap_loader.dart';

/// Premium high-tech action button with loading spinner state,
/// glowing active border, and accessible touch target.
class TechButton extends StatefulWidget {
  final String text;
  final String? loadingText;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isSecondary;
  final double? width;
  final Color? customColor;

  const TechButton({
    super.key,
    required this.text,
    this.loadingText,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isSecondary = false,
    this.width,
    this.customColor,
  });

  @override
  State<TechButton> createState() => _TechButtonState();
}

class _TechButtonState extends State<TechButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onPressed == null || widget.isLoading;
    final bool hasCustom = widget.customColor != null;

    final loadingColor = hasCustom
        ? Colors.white
        : (widget.isSecondary ? AppColors.cyanAccent : AppColors.textOnAccent);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width ?? double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: hasCustom || widget.isSecondary
              ? null
              : (disabled
                  ? LinearGradient(
                      colors: [
                        AppColors.cyanAccent.withValues(alpha: 0.3),
                        AppColors.bluePrimary.withValues(alpha: 0.3),
                      ],
                    )
                  : AppColors.primaryGradient),
          color: hasCustom
              ? (disabled ? widget.customColor!.withValues(alpha: 0.5) : widget.customColor)
              : (widget.isSecondary ? AppColors.surfaceElevated : null),
          border: widget.isSecondary && !hasCustom
              ? Border.all(
                  color: _isHovered ? AppColors.cyanAccent : AppColors.borderSubtle,
                  width: 1,
                )
              : null,
          boxShadow: (!disabled && _isHovered)
              ? [
                  BoxShadow(
                    color: (hasCustom ? widget.customColor! : AppColors.cyanAccent).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: disabled ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: hasCustom ? Colors.white : (widget.isSecondary ? AppColors.textPrimary : AppColors.textOnAccent),
            disabledForegroundColor: AppColors.textMuted,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: widget.isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GsapElasticWaveLoader(
                      height: 14,
                      barCount: 4,
                      color: loadingColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.loadingText ?? 'AUTHENTICATING...',
                      style: AppTypography.labelLarge.copyWith(
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                        color: loadingColor,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: hasCustom ? Colors.white : null),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: AppTypography.labelLarge.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: hasCustom ? Colors.white : (widget.isSecondary ? AppColors.textPrimary : AppColors.textOnAccent),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
