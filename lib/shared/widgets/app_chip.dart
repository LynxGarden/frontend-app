import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';

/// A selectable chip with a small spring-scale animation on toggle.
/// Use for filter bars, multi-select tags, onboarding preference pickers.
class AppChip extends StatefulWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<AppChip> createState() => _AppChipState();
}

class _AppChipState extends State<AppChip> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
    lowerBound: 0.94,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.selectionClick();
    await _controller.reverse();
    await _controller.forward();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: widget.selected ? AppColors.primary : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: widget.selected ? AppColors.primary : AppColors.surfaceBorder,
            ),
          ),
          child: Text(
            widget.label,
            style: AppTextStyles.bodySmall.copyWith(
              color: widget.selected ? Colors.white : AppColors.textSecondary,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
