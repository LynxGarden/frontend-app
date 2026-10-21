import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';

/// One row in an [showActionSheet] — an icon + label that resolves to [value].
class AppSheetAction<T> {
  const AppSheetAction({
    required this.value,
    required this.label,
    required this.icon,
    this.destructive = false,
  });

  final T value;
  final String label;
  final IconData icon;
  final bool destructive;
}

/// A design-system bottom sheet of actions — the house replacement for the stock
/// [PopupMenuButton]. Pops with the chosen action's `value` (or null if
/// dismissed). Dark-mode aware, responsive, uses the shared radius tokens.
Future<T?> showActionSheet<T>(
  BuildContext context, {
  String? title,
  required List<AppSheetAction<T>> actions,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading3,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.xs),
            for (final action in actions)
              _ActionRow<T>(action: action),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    },
  );
}

class _ActionRow<T> extends StatelessWidget {
  const _ActionRow({required this.action});

  final AppSheetAction<T> action;

  @override
  Widget build(BuildContext context) {
    final color =
        action.destructive ? AppColors.error : AppColors.textPrimary;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop(action.value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(action.icon, size: 22, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                action.label,
                style: AppTextStyles.body.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
