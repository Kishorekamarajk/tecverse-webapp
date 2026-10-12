import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Three-color accent / progress bar: orange → green → navy.
///
/// Renders a thin, pill-shaped, fully rounded bar using the brand gradient.
/// Typically placed below section headers or at the top of a card/screen.
class AppAccentBar extends StatelessWidget {
  const AppAccentBar({
    super.key,
    this.height = 3.0,
    this.borderRadius = 999.0,
    this.gradient = AppColors.accentBarGradient,
    this.maxWidth = double.infinity,
    this.alignment = Alignment.centerLeft,
  });

  /// Thickness of the bar.
  final double height;

  /// Corner radius — defaults to pill shape.
  final double borderRadius;

  /// Override the default 3-color gradient.
  final LinearGradient gradient;

  /// Optional maximum width (use `double.infinity` to fill parent).
  final double maxWidth;

  /// How to align the bar within its parent when `maxWidth` is constrained.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
