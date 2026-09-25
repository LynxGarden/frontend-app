import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/review/presentation/session_actuals_screen.dart';
import 'package:lynx_app/features/review/providers/review_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';

/// Staff Review tab: a recent feed of sessions clients have completed across the
/// tenant (review-on-login). Tap one to see the actuals.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(reviewFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.reviewTitle, style: AppTextStyles.heading3),
        backgroundColor: AppColors.background,
      ),
      body: RefreshIndicator(
        color: AppColors.forest,
        onRefresh: () => ref.refresh(reviewFeedProvider.future),
        child: async.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.forest)),
          error: (_, _) => ListView(children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Text(l.somethingWentWrong,
                  textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
            ),
          ]),
          data: (sessions) {
            if (sessions.isEmpty) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.xxl * 2, AppSpacing.xl, 0),
                  child: Column(children: [
                    const Icon(Icons.check_circle_outline,
                        size: 44, color: AppColors.textTertiary),
                    const SizedBox(height: AppSpacing.md),
                    Text(l.reviewEmpty,
                        textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
                  ]),
                ),
              ]);
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: sessions.length,
              itemBuilder: (context, i) {
                final s = sessions[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: ListTile(
                    title: Text(
                      s.personName.isEmpty ? s.assignmentName : s.personName,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${s.assignmentName} · ${s.label} — '
                      '${MaterialLocalizations.of(context).formatShortDate(s.completedAt.toLocal())}',
                      style: AppTextStyles.bodySmall,
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => SessionActualsScreen(
                          sessionId: s.assignmentSessionId,
                          personId: s.personId,
                          title: '${s.label} · ${s.personName}',
                        ),
                      ));
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
