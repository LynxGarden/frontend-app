import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/review/data/feedback_repository.dart';
import 'package:lynx_app/features/review/data/models/review_feedback.dart';
import 'package:lynx_app/features/review/presentation/exercise_comments_sheet.dart';
import 'package:lynx_app/features/review/providers/review_feedback_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// Coach deep-dive for one client: Program → Phase → Session → Exercise, with
/// personal bests, the client's difficulty ratings, likes and comments, plus a
/// per-phase reset.
class ClientReviewDetailScreen extends ConsumerWidget {
  const ClientReviewDetailScreen({
    super.key,
    required this.personId,
    required this.clientName,
  });

  final String personId;
  final String clientName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(clientReviewDataProvider(personId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppNavBar(title: clientName),
            Expanded(child: _body(context, ref, l, async)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, AppLocalizations l,
      AsyncValue<ClientReviewData> async) {
    return async.when(
        loading: () => const _DetailSkeleton(),
        error: (_, _) => Center(
          child: Text(l.somethingWentWrong, style: AppTextStyles.bodySmall),
        ),
        data: (bundle) {
          final tree = bundle.tree;
          if (tree == null || tree.phases.isEmpty) {
            return Center(
              child: Text(
                l.reviewEmpty,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiary),
              ),
            );
          }
          return SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(tree.name,
                    style: AppTextStyles.heading3
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.md),
                for (final phase in tree.phases)
                  _PhaseSection(
                    personId: personId,
                    phase: phase,
                    bundle: bundle,
                  ),
              ],
            ),
          );
        },
    );
  }
}

class _PhaseSection extends ConsumerWidget {
  const _PhaseSection({
    required this.personId,
    required this.phase,
    required this.bundle,
  });

  final String personId;
  final ReviewPhase phase;
  final ClientReviewData bundle;

  Future<void> _resetPhase(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l.resetPhaseTitle, style: AppTextStyles.heading3),
        content: Text(l.resetPhaseBody, style: AppTextStyles.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.resetPhase,
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FeedbackRepository.resetPhase(phase.id);
      ref.invalidate(clientReviewDataProvider(personId));
      if (context.mounted) {
        AppToast.show(context, title: l.phaseReset);
      }
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              top: AppSpacing.sm, bottom: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  phase.name,
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context).resetPhase,
                icon: Icon(Icons.restart_alt,
                    size: 20, color: AppColors.textTertiary),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _resetPhase(context, ref);
                },
              ),
            ],
          ),
        ),
        for (final session in phase.sessions)
          _SessionBlock(
            personId: personId,
            session: session,
            bundle: bundle,
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _SessionBlock extends StatelessWidget {
  const _SessionBlock({
    required this.personId,
    required this.session,
    required this.bundle,
  });

  final String personId;
  final ReviewSession session;
  final ClientReviewData bundle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(session.label,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
              if (session.isCompleted)
                Icon(Icons.check_circle, size: 18, color: AppColors.success),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l.exerciseCount(session.exercises.length),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: AppSpacing.sm),
          for (final ex in session.exercises)
            _ExerciseRow(
              personId: personId,
              exercise: ex,
              feedback: bundle.feedbackByAe[ex.assignmentExerciseId],
              liked: bundle.likedAes.contains(ex.assignmentExerciseId),
              commentCount: bundle.commentCounts[ex.assignmentExerciseId] ?? 0,
            ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends ConsumerWidget {
  const _ExerciseRow({
    required this.personId,
    required this.exercise,
    required this.feedback,
    required this.liked,
    required this.commentCount,
  });

  final String personId;
  final ReviewExercise exercise;
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
        assignmentExerciseId: exercise.assignmentExerciseId,
        authorId: user.personId,
        liked: !liked,
      );
      ref.invalidate(clientReviewDataProvider(personId));
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: AppColors.surfaceBorder, height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(exercise.name, style: AppTextStyles.body),
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
                tooltip: liked ? l.likedLabel : l.likeAction,
                icon: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: liked ? AppColors.error : AppColors.textTertiary,
                ),
                onPressed: () => _toggleLike(context, ref),
              ),
              IconButton(
                tooltip: l.comments,
                icon: Icon(Icons.mode_comment_outlined,
                    size: 19, color: AppColors.textTertiary),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _showComments(context, ref, exercise.assignmentExerciseId);
                },
              ),
              if (commentCount > 0)
                Text('$commentCount',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary)),
            ],
          ),
          _PbLine(personId: personId, exerciseId: exercise.exerciseId),
        ],
      ),
    );
  }

  void _showComments(BuildContext context, WidgetRef ref, String aeId) {
    showExerciseComments(context,
        personId: personId, assignmentExerciseId: aeId);
  }
}

class _PbLine extends ConsumerWidget {
  const _PbLine({required this.personId, required this.exerciseId});

  final String personId;
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(
        personalBestProvider((personId: personId, exerciseId: exerciseId)));
    return async.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: SkeletonLoader(child: SkeletonBox(width: 160, height: 12)),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (pb) {
        if (pb.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(l.noPersonalBest,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiary)),
          );
        }
        final parts = <String>[];
        if (pb.bestWeight != null) {
          parts.add('${l.bestWeight}: ${_trim(pb.bestWeight!)}');
        }
        if (pb.bestReps != null) parts.add('${l.bestReps}: ${pb.bestReps}');
        if (pb.bestVolume != null) {
          parts.add('${l.bestVolume}: ${_trim(pb.bestVolume!)}');
        }
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
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

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SkeletonLoader(child: SkeletonBox(width: 180, height: 22)),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: SkeletonLoader(
                child: SkeletonBox(
                    width: double.infinity, height: 120, borderRadius: AppRadius.lg),
              ),
            ),
        ],
      ),
    );
  }
}
