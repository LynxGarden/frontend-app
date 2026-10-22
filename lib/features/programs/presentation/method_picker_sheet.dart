import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/programs/data/models/training_method.dart';
import 'package:lynx_app/features/programs/presentation/method_labels.dart';
import 'package:lynx_app/l10n/app_localizations.dart';

/// Bottom sheet listing every [TrainingMethod] with its spec description.
/// The coach picks the method FIRST — before choosing the exercise — so the
/// prescription editor opens prefilled with the method's defaults.
Future<TrainingMethod?> showMethodPicker(
  BuildContext context, {
  TrainingMethod? current,
}) {
  return showModalBottomSheet<TrainingMethod>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetCtx) {
      final l = AppLocalizations.of(sheetCtx);
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
                child: Text(l.trainingMethod, style: AppTextStyles.heading3),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(l.chooseMethodFirst,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  children: [
                    for (final m in TrainingMethod.values)
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(sheetCtx).pop(m);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm + 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(methodLabel(l, m),
                                        style: AppTextStyles.body.copyWith(
                                            color: m == current
                                                ? AppColors.primary
                                                : AppColors.textPrimary,
                                            fontWeight: m == current
                                                ? FontWeight.w600
                                                : FontWeight.w500)),
                                    const SizedBox(height: 2),
                                    Text(methodDescription(l, m),
                                        style: AppTextStyles.bodySmall
                                            .copyWith(
                                                color:
                                                    AppColors.textTertiary)),
                                  ],
                                ),
                              ),
                              if (m == current) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Icon(Icons.check, color: AppColors.primary),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
