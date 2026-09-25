import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/review/presentation/session_actuals_screen.dart';
import 'package:lynx_app/features/review/providers/review_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/collapsing_header.dart';

/// Staff Review tab: a recent feed of sessions clients have completed across the
/// tenant (review-on-login). Tap one to see the actuals.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(reviewFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.forest,
        onRefresh: () => ref.refresh(reviewFeedProvider.future),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverCollapsingHeader(title: l.reviewTitle, controller: _scroll),
            async.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.forest)),
              ),
              error: (_, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Text(l.somethingWentWrong,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall),
                  ),
                ),
              ),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 44, color: AppColors.textTertiary),
                            const SizedBox(height: AppSpacing.md),
                            Text(l.reviewEmpty,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
                  sliver: SliverList.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, i) {
                      final s = sessions[i];
                      return AppCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          title: Text(
                            s.personName.isEmpty
                                ? s.assignmentName
                                : s.personName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${s.assignmentName} · ${s.label} — '
                            '${MaterialLocalizations.of(context).formatShortDate(s.completedAt.toLocal())}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall,
                          ),
                          trailing: const Icon(Icons.chevron_right,
                              color: AppColors.textTertiary),
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
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
