import 'package:flutter/material.dart';

/// App Footer placeholder (footers removed per user preference).
class AppFooter extends StatelessWidget {
  final bool compact;
  final EdgeInsetsGeometry? padding;

  const AppFooter({
    super.key,
    this.compact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

