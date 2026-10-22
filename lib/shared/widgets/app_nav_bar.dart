import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';

/// Detail/sub-page navigation bar (kaddy pattern): a circular bordered back
/// button, a centered title, and an optional trailing action. Handles its own
/// top [SafeArea] — drop it as the FIRST child of the Scaffold body [Column]
/// (don't wrap the body in an extra top SafeArea).
///
/// Set [blurred] to overlay it on scrolling content: a translucent, blurred
/// background (iOS-Settings style) with a hairline bottom edge, so content is
/// visible through it. Use it as the top layer of a [Stack] and give the body a
/// top padding of [AppNavBar.estimatedHeight] so nothing starts hidden.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.showBack = true,
    this.blurred = false,
    this.frost = 0,
    this.scale = 1.0,
  });

  final String title;

  /// Tapped on back; defaults to `Navigator.maybePop`.
  final VoidCallback? onBack;

  /// Optional trailing widget. Defaults to a 40px spacer so the title stays
  /// centered when there's no action.
  final Widget? trailing;

  final bool showBack;

  /// Frosted, translucent overlay style (content shows through it).
  final bool blurred;

  /// Frost intensity 0→1: 0 = fully transparent (no container, content crisp);
  /// 1 = full blur + translucent fade. Chats pass 1 (content is always under
  /// the bar); scroll screens ramp it from the scroll offset.
  final double frost;

  /// Bar scale (1.0 default). Scroll screens shrink to 0.9 as they scroll.
  final double scale;

  /// Content height below the status bar (SafeArea top handled separately).
  static const double barHeight = 56;

  /// Total height incl. the status-bar inset — use as body top padding when
  /// overlaying a [blurred] bar.
  static double estimatedHeight(BuildContext context) =>
      MediaQuery.of(context).padding.top + barHeight;

  @override
  Widget build(BuildContext context) {
    final leading = showBack
        ? _CircleButton(
            icon: Icons.chevron_left,
            onTap: () {
              HapticFeedback.lightImpact();
              (onBack ?? () => Navigator.of(context).maybePop()).call();
            },
          )
        : const SizedBox(width: 40);

    final bar = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
        // Stack (not Row) so the title is centered on the full width regardless
        // of how wide the leading/trailing slots are (e.g. two trailing actions).
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Horizontal inset keeps a long title from colliding with the
            // buttons on either side.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl * 2),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading3.copyWith(fontSize: 18),
              ),
            ),
            Align(alignment: Alignment.centerLeft, child: leading),
            if (trailing != null)
              Align(alignment: Alignment.centerRight, child: trailing!),
          ],
        ),
      ),
    );

    final scaled = scale == 1.0
        ? bar
        : Transform.scale(
            scale: scale, alignment: Alignment.topCenter, child: bar);
    if (!blurred) return scaled;

    // Floating frosted overlay: at frost 0 it's fully transparent with no blur
    // (content crisp, controls float); as frost → 1 a soft blur fades in from
    // opaque top to transparent bottom — never a bordered container box.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18 * frost, sigmaY: 18 * frost),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.92 * frost),
                AppColors.background.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: scaled,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Icon(icon, size: 22, color: AppColors.primary),
      ),
    );
  }
}

/// A trailing action styled to match [AppNavBar]'s circular back button.
class AppNavBarAction extends StatelessWidget {
  const AppNavBarAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tint,
    this.tooltip,
  });

  final IconData icon;

  /// Null disables the action — it dims and stops responding to taps.
  final VoidCallback? onTap;
  final Color? tint;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final iconColor =
        (tint ?? AppColors.primary).withValues(alpha: enabled ? 1.0 : 0.35);
    final button = GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
