import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/review/data/models/review_models.dart';
import 'package:lynx_app/features/review/data/review_repository.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// Recent completed sessions across the tenant's clients (the Review tab feed).
final reviewFeedProvider = FutureProvider<List<CompletedSession>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return ReviewRepository.recentCompleted(tenantId: user.tenantId);
});

/// Completed sessions for one client.
final clientCompletedProvider =
    FutureProvider.family<List<CompletedSession>, String>((ref, personId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return ReviewRepository.clientCompleted(
    tenantId: user.tenantId,
    personId: personId,
  );
});

/// Key for a session's actuals: which session, and whose logs.
typedef ActualsKey = ({String sessionId, String personId});

/// Per-exercise logged actuals for a reviewed session.
final sessionActualsProvider =
    FutureProvider.family<List<ExerciseActuals>, ActualsKey>((ref, key) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return ReviewRepository.sessionActuals(
    tenantId: user.tenantId,
    assignmentSessionId: key.sessionId,
    personId: key.personId,
  );
});
