import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';

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

  bool get _isDisabled => onPressed == null || isLoading;

  Color get _backgroundColor {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
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

  BorderSide get _border {
    switch (variant) {
      case AppButtonVariant.secondary:
        return const BorderSide(color: AppColors.primary, width: 1);
      case AppButtonVariant.primary:
      case AppButtonVariant.ghost:
        return BorderSide.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayLabel = isLoading && loadingLabel != null ? loadingLabel! : label;
    final disabledAndNotLoading = _isDisabled && !isLoading;

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
                const SizedBox(width: 8),
                Text(
                  loadingLabel ?? 'Loading...',
                  style: AppTextStyles.button.copyWith(color: _foregroundColor),
                ),
              ],
            )
          : Text(
              displayLabel,
              key: ValueKey(displayLabel),
              style: AppTextStyles.button.copyWith(color: _foregroundColor),
            ),
    );

    final button = Opacity(
      opacity: disabledAndNotLoading ? 0.5 : 1.0,
      child: Material(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _isDisabled
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed?.call();
                },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.fromBorderSide(_border),
            ),
            alignment: Alignment.center,
            child: child,
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
