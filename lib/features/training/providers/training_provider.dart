import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/features/training/data/models/active_assignment.dart';
import 'package:lynx_app/features/training/data/training_repository.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// The signed-in client's active assignment (menu of sessions), **live**: when a
/// coach assigns or (re)activates a program, the Train tab updates without a
/// refresh. Null when nothing is assigned yet.
///
/// `.stream()` can't express the sessions/exercises join, so it's used purely as
/// a change trigger on this client's `assignments` rows (RLS-scoped to them); each
/// trigger re-runs the rich fetch. An initial REST load is yielded first so the
/// tab still works if realtime isn't enabled. Still invalidatable after
/// complete/swap.
final activeAssignmentProvider =
    StreamProvider<ActiveAssignment?>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield null;
    return;
  }

  Future<ActiveAssignment?> load() => TrainingRepository.loadActiveAssignment(
        tenantId: user.tenantId,
        personId: user.personId,
      );

  // Initial snapshot up front (works even if the table isn't in the realtime
  // publication yet), then re-fetch on every realtime change.
  yield await load();

  // Realtime is a best-effort enhancement, not a requirement. On some networks
  // — and reliably on the iOS simulator — the realtime websocket can't connect
  // even when plain HTTP works fine. A subscription failure must NOT tear the
  // tab down into an error ("You're offline") state: keep serving the REST
  // snapshot above. Pull-to-refresh and provider invalidation still update it.
  try {
    final trigger = SupabaseClientWrapper
        .stream('assignments', primaryKey: ['id']).eq('person_id', user.personId);
    await for (final _ in trigger) {
      yield await load();
    }
  } catch (_) {
    // Realtime unavailable — stay on the last good snapshot.
  }
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
