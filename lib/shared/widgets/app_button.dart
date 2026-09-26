import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';

/// App-wide button. Three variants, all the **same fixed height** so stacked
/// buttons line up perfectly:
/// - [primary]   — forest fill, white label.
/// - [secondary] — white fill, forest border + label.
/// - [ghost]     — transparent, forest label, no border.
enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.loadingLabel,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isExpanded = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final String? loadingLabel;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isExpanded;

  /// Shared height for every variant — the fix for mis-aligned stacked buttons.
  static const double height = 52;

  bool get _isDisabled => onPressed == null || isLoading;

  Color get _backgroundColor {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.surface;
      case AppButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color get _foregroundColor {
    switch (variant) {
      case AppButtonVariant.primary:
        return Colors.white;
      case AppButtonVariant.secondary:
      case AppButtonVariant.ghost:
        return AppColors.primary;
    }
  }

  /// Every variant carries a 1px border of the SAME width so their box metrics
  /// are identical — the primary's border just matches its fill (invisible).
  Color get _borderColor {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.primary;
      case AppButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayLabel =
        isLoading && loadingLabel != null ? loadingLabel! : label;

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? Row(
              key: const ValueKey('loading'),
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _foregroundColor,
                  ),
                ),
                if (loadingLabel != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    loadingLabel!,
                    style: AppTextStyles.button.copyWith(color: _foregroundColor),
                  ),
                ],
              ],
            )
          : Text(
              displayLabel,
              key: ValueKey(displayLabel),
              style: AppTextStyles.button.copyWith(color: _foregroundColor),
            ),
    );

    final button = Opacity(
      opacity: (_isDisabled && !isLoading) ? 0.5 : 1.0,
      child: SizedBox(
        height: height,
        child: Material(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: _isDisabled
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onPressed?.call();
                  },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: _borderColor),
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
