import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/review/data/feedback_repository.dart';
import 'package:lynx_app/features/review/data/models/review_feedback.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// Everything the coach deep-dive needs for one client, loaded together.
class ClientReviewData {
  const ClientReviewData({
    required this.tree,
    required this.feedbackByAe,
    required this.likedAes,
    required this.commentCounts,
  });

  final ReviewAssignmentTree? tree;
  final Map<String, ExerciseFeedback> feedbackByAe;
  final Set<String> likedAes;
  final Map<String, int> commentCounts;
}

/// The coach deep-dive bundle for a client (tree + ratings + likes + counts).
/// Invalidate after a like/comment/reset to refresh.
final clientReviewDataProvider =
    FutureProvider.family<ClientReviewData, String>((ref, personId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    return const ClientReviewData(
        tree: null, feedbackByAe: {}, likedAes: {}, commentCounts: {});
  }
  final tenantId = user.tenantId;
  final tree = await FeedbackRepository.loadClientAssignmentTree(
      tenantId: tenantId, personId: personId);
  if (tree == null) {
    return const ClientReviewData(
        tree: null, feedbackByAe: {}, likedAes: {}, commentCounts: {});
  }
  final aeIds = [
    for (final p in tree.phases)
      for (final s in p.sessions)
        for (final e in s.exercises) e.assignmentExerciseId
  ];
  final feedback = await FeedbackRepository.feedbackForAes(
      tenantId: tenantId, aeIds: aeIds);
  final liked = await FeedbackRepository.likedAes(
      tenantId: tenantId, authorId: user.personId, aeIds: aeIds);
  final counts = await FeedbackRepository.commentCountsForAes(
      tenantId: tenantId, aeIds: aeIds);
  return ClientReviewData(
    tree: tree,
    feedbackByAe: feedback,
    likedAes: liked,
    commentCounts: counts,
  );
});

typedef PbKey = ({String personId, String exerciseId});

/// A client's personal best for one exercise (lazy per row).
final personalBestProvider =
    FutureProvider.family<PersonalBest, PbKey>((ref, key) async {
  return FeedbackRepository.personalBestFor(
    personId: key.personId,
    exerciseId: key.exerciseId,
  );
});

/// Comments for one assignment-exercise (loaded when the sheet opens).
final exerciseCommentsProvider =
    FutureProvider.family<List<ExerciseComment>, String>((ref, aeId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return FeedbackRepository.listComments(
      tenantId: user.tenantId, assignmentExerciseId: aeId);
});
