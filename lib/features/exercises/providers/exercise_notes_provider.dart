import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/exercises/data/exercise_notes_repository.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// The current user's global note for an exercise (empty string when none).
/// Invalidate after saving to refresh.
final exerciseNoteProvider =
    FutureProvider.family<String, String>((ref, exerciseId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return '';
  return ExerciseNotesRepository.noteFor(
    tenantId: user.tenantId,
    personId: user.personId,
    exerciseId: exerciseId,
  );
});
