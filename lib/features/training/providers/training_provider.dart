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
