import 'package:flutter/material.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/utils/validation_helpers.dart';

/// Reusable password requirements list with animated show/hide.
///
/// Each requirement turns green with a check icon as it is met.
class PasswordRequirements extends StatefulWidget {
  const PasswordRequirements({super.key, required this.value});

  final String value;

  @override
  State<PasswordRequirements> createState() => _PasswordRequirementsState();
}

class _PasswordRequirementsState extends State<PasswordRequirements>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _size;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 180),
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _size = Tween<double>(begin: 0, end: 1).animate(curve);
    _controller.value = _isVisible ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant PasswordRequirements oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (_isVisible && _controller.status != AnimationStatus.forward) {
        _controller.forward();
      } else if (!_isVisible && _controller.status != AnimationStatus.reverse) {
        _controller.reverse();
      }
    }
  }

  bool get _isVisible => widget.value.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _RequirementItem(label: 'At least 8 characters', met: hasMinLength(widget.value, min: 8)),
      _RequirementItem(label: 'One uppercase letter', met: hasUppercase(widget.value)),
      _RequirementItem(label: 'One lowercase letter', met: hasLowercase(widget.value)),
      _RequirementItem(label: 'One special character', met: hasSpecialCharacter(widget.value)),
    ];

    return ClipRect(
      child: SizeTransition(
        sizeFactor: _size,
        alignment: Alignment.topLeft,
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: items[0]), const SizedBox(width: AppSpacing.lg), Expanded(child: items[1])]),
                const SizedBox(height: AppSpacing.sm),
                Row(children: [Expanded(child: items[2]), const SizedBox(width: AppSpacing.lg), Expanded(child: items[3])]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequirementItem extends StatelessWidget {
  const _RequirementItem({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.success : AppColors.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_rounded, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            softWrap: true,
            style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
