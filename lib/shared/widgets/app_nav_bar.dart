import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';

/// Detail/sub-page navigation bar (kaddy pattern): a circular bordered back
/// button, a centered title, and an optional trailing action. Handles its own
/// top [SafeArea] — drop it as the FIRST child of the Scaffold body [Column]
/// (don't wrap the body in an extra top SafeArea).
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.showBack = true,
  });

  final String title;

  /// Tapped on back; defaults to `Navigator.maybePop`.
  final VoidCallback? onBack;

  /// Optional trailing widget. Defaults to a 40px spacer so the title stays
  /// centered when there's no action.
  final Widget? trailing;

  final bool showBack;

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

    return SafeArea(
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
  final VoidCallback onTap;
  final Color? tint;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Icon(icon, size: 20, color: tint ?? AppColors.primary),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
