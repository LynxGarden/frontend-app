import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/review/data/feedback_repository.dart';
import 'package:lynx_app/features/review/data/models/review_feedback.dart';
import 'package:lynx_app/features/review/providers/review_provider.dart';
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

/// Coach feedback (ratings/likes/comment counts) for the exercises of ONE
/// reviewed session — the lighter counterpart to [ClientReviewData] used by the
/// per-session actuals screen. Invalidate after a like/comment to refresh.
class SessionFeedback {
  const SessionFeedback({
    required this.feedbackByAe,
    required this.likedAes,
    required this.commentCounts,
  });

  final Map<String, ExerciseFeedback> feedbackByAe;
  final Set<String> likedAes;
  final Map<String, int> commentCounts;

  static const empty =
      SessionFeedback(feedbackByAe: {}, likedAes: {}, commentCounts: {});
}

final sessionFeedbackProvider =
    FutureProvider.family<SessionFeedback, ActualsKey>((ref, key) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return SessionFeedback.empty;
  final actuals = await ref.watch(sessionActualsProvider(key).future);
  final aeIds = actuals.map((e) => e.assignmentExerciseId).toList();
  if (aeIds.isEmpty) return SessionFeedback.empty;
  final feedback = await FeedbackRepository.feedbackForAes(
      tenantId: user.tenantId, aeIds: aeIds);
  final liked = await FeedbackRepository.likedAes(
      tenantId: user.tenantId, authorId: user.personId, aeIds: aeIds);
  final counts = await FeedbackRepository.commentCountsForAes(
      tenantId: user.tenantId, aeIds: aeIds);
  return SessionFeedback(
      feedbackByAe: feedback, likedAes: liked, commentCounts: counts);
});

/// The client's 1–10 session difficulty rating (null = not rated / older
/// backend), keyed by assignment_sessions id.
final sessionRatingProvider = FutureProvider.family<int?, String>(
    (ref, sessionId) => FeedbackRepository.sessionRating(sessionId));

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
