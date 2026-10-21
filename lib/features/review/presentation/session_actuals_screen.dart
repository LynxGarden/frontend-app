import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/review/data/feedback_repository.dart';
import 'package:lynx_app/features/review/data/models/review_feedback.dart';
import 'package:lynx_app/features/review/data/models/review_models.dart';
import 'package:lynx_app/features/review/presentation/exercise_comments_sheet.dart';
import 'package:lynx_app/features/review/providers/review_feedback_provider.dart';
import 'package:lynx_app/features/review/providers/review_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/frosted_nav_scaffold.dart';
import 'package:lynx_app/shared/widgets/skeleton_list.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// Drill-in for one completed session: each exercise + the actuals the client
/// logged, plus the coach's per-exercise feedback (difficulty rating, likes,
/// comments) and the client's personal bests.
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
    final key = (sessionId: sessionId, personId: personId);
    final async = ref.watch(sessionActualsProvider(key));
    final feedback =
        ref.watch(sessionFeedbackProvider(key)).valueOrNull ?? SessionFeedback.empty;
    final rating = ref.watch(sessionRatingProvider(sessionId)).valueOrNull;

    return FrostedNavScaffold(
      title: title,
      builder: (context, topInset) => async.when(
        loading: () => SessionActualsSkeleton(topInset: topInset),
        error: (_, _) => Center(
            child: Text(l.somethingWentWrong, style: AppTextStyles.bodySmall)),
        data: (items) {
          final headerCount = rating != null ? 1 : 0;
          return SafeArea(
            top: false,
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, topInset + AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              itemCount: items.length + headerCount,
              itemBuilder: (context, i) {
                if (rating != null && i == 0) {
                  return _SessionRatingBanner(rating: rating);
                }
                final ex = items[i - headerCount];
                final aeId = ex.assignmentExerciseId;
                return _ExerciseCard(
                  personId: personId,
                  sessionKey: key,
                  ex: ex,
                  feedback: feedback.feedbackByAe[aeId],
                  liked: feedback.likedAes.contains(aeId),
                  commentCount: feedback.commentCounts[aeId] ?? 0,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Header banner with the client's 1–10 session difficulty (smiley matches the
/// runner's finish-card slider; accent shifts success → error with the rating).
class _SessionRatingBanner extends StatelessWidget {
  const _SessionRatingBanner({required this.rating});

  final int rating;

  static String _emojiFor(int r) {
    if (r <= 2) return '😄';
    if (r <= 4) return '🙂';
    if (r <= 6) return '😐';
    if (r <= 8) return '😣';
    return '🥵';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = (rating - 1) / 9.0;
    final accent =
        Color.lerp(AppColors.success, AppColors.error, t) ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Text(_emojiFor(rating), style: const TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(l.sessionRatingLabel,
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          Text('$rating / 10',
              style: AppTextStyles.body
                  .copyWith(color: accent, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.personId,
    required this.sessionKey,
    required this.ex,
    required this.feedback,
    required this.liked,
    required this.commentCount,
  });

  final String personId;
  final ActualsKey sessionKey;
  final ExerciseActuals ex;
  final ExerciseFeedback? feedback;
  final bool liked;
  final int commentCount;

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    HapticFeedback.selectionClick();
    try {
      await FeedbackRepository.toggleLike(
        tenantId: user.tenantId,
        assignmentExerciseId: ex.assignmentExerciseId,
        authorId: user.personId,
        liked: !liked,
      );
      ref.invalidate(sessionFeedbackProvider(sessionKey));
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(ex.exerciseName,
                    style:
                        AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (feedback != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text('${l.difficulty} ${feedback!.difficulty}/5',
                      style: AppTextStyles.bodySmall),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: liked ? l.likedLabel : l.likeAction,
                icon: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: liked ? AppColors.error : AppColors.textTertiary,
                ),
                onPressed: () => _toggleLike(context, ref),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l.comments,
                icon: Icon(Icons.mode_comment_outlined,
                    size: 19, color: AppColors.textTertiary),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  showExerciseComments(context,
                      personId: personId,
                      assignmentExerciseId: ex.assignmentExerciseId);
                },
              ),
              if (commentCount > 0)
                Text('$commentCount',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary)),
            ],
          ),
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
          _PbLine(personId: personId, exerciseId: ex.exerciseId),
        ],
      ),
    );
  }
}

/// Compact personal-best line for one exercise (weight · reps · volume).
class _PbLine extends ConsumerWidget {
  const _PbLine({required this.personId, required this.exerciseId});

  final String personId;
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (exerciseId.isEmpty) return const SizedBox.shrink();
    final async = ref.watch(
        personalBestProvider((personId: personId, exerciseId: exerciseId)));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xs),
        child: SkeletonLoader(child: SkeletonBox(width: 140, height: 12)),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (pb) {
        if (pb.isEmpty) return const SizedBox.shrink();
        final parts = <String>[];
        if (pb.bestWeight != null) {
          parts.add('${l.bestWeight}: ${_trim(pb.bestWeight!)}');
        }
        if (pb.bestReps != null) parts.add('${l.bestReps}: ${pb.bestReps}');
        if (pb.bestVolume != null) {
          parts.add('${l.bestVolume}: ${_trim(pb.bestVolume!)}');
        }
        if (parts.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Row(
            children: [
              Icon(Icons.emoji_events_outlined,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(parts.join(' · '),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _trim(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
