import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/exercises/data/exercise_repository.dart';
import 'package:lynx_app/features/exercises/data/models/exercise.dart';
import 'package:lynx_app/features/exercises/data/models/exercise_tag.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// The signed-in coach's own exercises (tenant-scoped). Invalidate after a
/// create/update/delete to refresh the library.
final exercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return ExerciseRepository.listForOwner(
    tenantId: user.tenantId,
    ownerId: user.personId,
  );
});

/// All tags in the tenant (for the filter chips + editor).
final exerciseTagsProvider = FutureProvider<List<ExerciseTag>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return ExerciseRepository.listTags(user.tenantId);
});
