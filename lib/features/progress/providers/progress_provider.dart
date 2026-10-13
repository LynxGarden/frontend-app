import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/progress/data/models/progress_models.dart';
import 'package:lynx_app/features/progress/data/progress_repository.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// Activity summary (visits this week + streak). Invalidate to refresh.
final progressSummaryProvider = FutureProvider<ProgressSummary>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return ProgressSummary.empty;
  return ProgressRepository.loadSummary(
    tenantId: user.tenantId,
    personId: user.personId,
  );
});

/// Exercises the client can view progress for (from their assignments).
final trackedExercisesProvider =
    FutureProvider<List<TrackedExercise>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return ProgressRepository.trackedExercises(
    tenantId: user.tenantId,
    personId: user.personId,
  );
});

/// The exercise currently selected in the progress picker (null → first).
final selectedProgressExerciseProvider = StateProvider<String?>((ref) => null);

/// Per-exercise progress aggregates for [exerciseId].
final exerciseProgressProvider =
    FutureProvider.family<ExerciseProgress, String>((ref, exerciseId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return ExerciseProgress.empty;
  return ProgressRepository.exerciseProgress(
    tenantId: user.tenantId,
    personId: user.personId,
    exerciseId: exerciseId,
  );
});
