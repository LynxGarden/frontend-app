import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/training/data/models/active_assignment.dart';
import 'package:lynx_app/features/training/data/training_repository.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// The signed-in client's active assignment (menu of sessions). Null when
/// nothing is assigned yet. Invalidate after complete/swap to refresh.
final activeAssignmentProvider = FutureProvider<ActiveAssignment?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  return TrainingRepository.loadActiveAssignment(
    tenantId: user.tenantId,
    personId: user.personId,
  );
});

/// Key for the session runner: which assignment + session to load.
typedef RunnerKey = ({String assignmentId, String sessionId});

/// The session (with its exercise snapshots) the runner shows. Loads the active
/// assignment and picks the session; null if not found. Invalidate after a swap.
/// Provider-backed so the screen is render-testable (override this in tests).
final sessionRunnerProvider =
    FutureProvider.family<TrainingAssignmentSession?, RunnerKey>((ref, key) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  final assignment = await TrainingRepository.loadActiveAssignment(
    tenantId: user.tenantId,
    personId: user.personId,
  );
  final matches =
      assignment?.sessions.where((s) => s.id == key.sessionId).toList();
  return (matches == null || matches.isEmpty) ? null : matches.first;
});

/// The "last time" sets for a given exercise (by `exercise_id`), for the
/// signed-in client. Empty when there's no prior history.
final lastEntriesProvider =
    FutureProvider.family<List<LoggedEntry>, String>((ref, exerciseId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return TrainingRepository.lastEntriesFor(
    personId: user.personId,
    exerciseId: exerciseId,
  );
});
