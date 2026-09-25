import 'package:flutter/material.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';

/// The standard lifted surface: a white card with a warm hairline border and a
/// soft warm shadow (depth from shadow + border, elevation 0 — the iOS-27 look).
///
/// The inner surface is a real [Material], so a [ListTile] child paints its ink
/// correctly (no "ListTile wrapped in a DecoratedBox" assert). Pass
/// `padding: EdgeInsets.zero` when the child is a ListTile (it brings its own).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin = const EdgeInsets.only(bottom: AppSpacing.sm),
    this.onTap,
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    Widget inner = Padding(padding: padding, child: child);
    if (onTap != null) {
      inner = InkWell(borderRadius: br, onTap: onTap, child: inner);
    }
    return Container(
      margin: margin,
      // Border + shadow only — NO background color here (the colored surface is
      // the Material below), so ListTile children don't trip the ink assert.
      decoration: BoxDecoration(
        borderRadius: br,
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: br,
        clipBehavior: Clip.antiAlias,
        child: inner,
      ),
    );
  }
}
