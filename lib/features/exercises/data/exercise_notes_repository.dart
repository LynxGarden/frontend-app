import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';

/// Data access for a client's global per-exercise notes.
class ExerciseNotesRepository {
  const ExerciseNotesRepository._();

  /// The person's note text for an exercise (empty string when none).
  static Future<String> noteFor({
    required String tenantId,
    required String personId,
    required String exerciseId,
  }) async {
    try {
      final row = await SupabaseClientWrapper.db('exercise_notes')
          .select('note')
          .eq('tenant_id', tenantId)
          .eq('person_id', personId)
          .eq('exercise_id', exerciseId)
          .maybeSingle();
      return (row?['note'] as String?) ?? '';
    } catch (e) {
      throw AppException('Could not load your note.', cause: e);
    }
  }

  /// Creates or updates the person's note for an exercise.
  static Future<void> saveNote({
    required String tenantId,
    required String personId,
    required String exerciseId,
    required String note,
  }) async {
    try {
      await SupabaseClientWrapper.db('exercise_notes').upsert(
        {
          'tenant_id': tenantId,
          'person_id': personId,
          'exercise_id': exerciseId,
          'note': note.trim(),
        },
        onConflict: 'tenant_id,person_id,exercise_id',
      );
    } catch (e) {
      throw AppException('Could not save your note.', cause: e);
    }
  }
}
