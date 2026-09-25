import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/review/providers/review_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';

/// Drill-in for one completed session: each exercise + the actuals the client
/// logged (their most recent occasion for that movement).
class SessionActualsScreen extends ConsumerWidget {
  const SessionActualsScreen({
    super.key,
    required this.sessionId,
    required this.personId,
    required this.title,
  });

  final String sessionId;
  final String personId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async =
        ref.watch(sessionActualsProvider((sessionId: sessionId, personId: personId)));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.heading3),
        backgroundColor: AppColors.background,
      ),
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.forest)),
        error: (_, _) =>
            Center(child: Text(l.somethingWentWrong, style: AppTextStyles.bodySmall)),
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final ex = items[i];
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ex.exerciseName,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  if (ex.entries.isEmpty)
                    Text(l.noneLogged,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textTertiary))
                  else
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: 2,
                      children: [
                        for (var s = 0; s < ex.entries.length; s++)
                          Text('${s + 1}. ${ex.entries[s].summary}',
                              style: AppTextStyles.bodySmall
                                  .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
