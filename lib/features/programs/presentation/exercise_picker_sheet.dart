import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/exercises/data/models/exercise.dart';
import 'package:lynx_app/features/exercises/providers/exercises_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';

/// Bottom sheet listing the coach's library; returns the chosen [Exercise].
Future<Exercise?> showExercisePicker(BuildContext context) {
  return showModalBottomSheet<Exercise>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => const _ExercisePicker(),
  );
}

class _ExercisePicker extends ConsumerWidget {
  const _ExercisePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final exercisesAsync = ref.watch(exercisesProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(l.pickExercise, style: AppTextStyles.heading3),
          ),
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.forest)),
              error: (_, _) => Center(
                  child: Text(l.somethingWentWrong, style: AppTextStyles.bodySmall)),
              data: (items) => items.isEmpty
                  ? Center(child: Text(l.exercisesEmpty, style: AppTextStyles.bodySmall))
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.line),
                      itemBuilder: (_, i) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(items[i].name, style: AppTextStyles.body),
                        subtitle: items[i].tags.isEmpty
                            ? null
                            : Text(items[i].tags.map((t) => t.label).join(' · '),
                                style: AppTextStyles.bodySmall),
                        trailing: const Icon(Icons.add, color: AppColors.forest),
                        onTap: () => Navigator.of(context).pop(items[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
