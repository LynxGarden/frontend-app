import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/training/data/models/active_assignment.dart';

/// Data access for the client daily loop (CP4). Reads the per-client instance
/// (`assignment_*`) and the generic `logged_entries` history; writes go through
/// the SECURITY DEFINER RPCs for the staff-write-only assignment rows.
class TrainingRepository {
  const TrainingRepository._();

  /// The client's active assignment (most recent active instance) with its
  /// sessions + exercise snapshots. Null when nothing is assigned yet.
  static Future<ActiveAssignment?> loadActiveAssignment({
    required String tenantId,
    required String personId,
  }) async {
    try {
      final row = await SupabaseClientWrapper.db('assignments')
          .select(
            'id, name, description, '
            'assignment_sessions(id, label, order_index, last_completed_at, '
            'assignment_exercises(id, exercise_id, swapped_from_exercise_id, '
            'exercise_name, description, video_url, video_storage_path, thumbnail_storage_path, '
            'metric_schema, order_index, sets, reps, weight, '
            'load_intensity, rpe, rir, time_seconds, tempo, rest_seconds, '
            'set_type_note, coach_note, method, method_group_id, group_order, '
            'method_config))',
          )
          .eq('tenant_id', tenantId)
          .eq('person_id', personId)
          .eq('is_active', true)
          .order('assigned_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      return ActiveAssignment.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException('Could not load your training.', cause: e);
    }
  }

  /// The sets logged the **last time** this person did this exercise: the most
  /// recent logging occasion (entries within 6h of the newest), oldest-set
  /// first. Empty when there's no history. Keyed on `exerciseId` so history
  /// follows the movement across programs and survives swaps.
  static Future<List<LoggedEntry>> lastEntriesFor({
    required String personId,
    required String exerciseId,
  }) async {
    try {
      final rows = await SupabaseClientWrapper.db('logged_entries')
          .select('id, logged_at, set_index, reps, weight, time_seconds, data')
          .eq('person_id', personId)
          .eq('exercise_id', exerciseId)
          .order('logged_at', ascending: false)
          .limit(20);
      final all = (rows as List)
          .map((r) => LoggedEntry.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
      if (all.isEmpty) return const [];

      // Keep only the most recent occasion (entries near the newest timestamp).
      final newest = all.first.loggedAt;
      final occasion = all
          .where((e) => newest.difference(e.loggedAt).inHours.abs() <= 6)
          .toList()
        ..sort((a, b) {
          final si = (a.setIndex ?? 0).compareTo(b.setIndex ?? 0);
          return si != 0 ? si : a.loggedAt.compareTo(b.loggedAt);
        });
      return occasion;
    } catch (e) {
      throw AppException('Could not load last-time history.', cause: e);
    }
  }

  /// Records one set the client did today and returns the new entry id (so the
  /// UI can later edit that exact set). `logged_by` = the client themselves.
  static Future<String> logSet({
    required String tenantId,
    required String personId,
    required String exerciseId,
    required String assignmentExerciseId,
    required int setIndex,
    int? reps,
    num? weight,
    int? timeSeconds,
    Map<String, dynamic>? data,
  }) async {
    try {
      final row = await SupabaseClientWrapper.db('logged_entries')
          .insert({
            'tenant_id': tenantId,
            'person_id': personId,
            'exercise_id': exerciseId,
            'assignment_exercise_id': assignmentExerciseId,
            'set_index': setIndex,
            'reps': reps,
            'weight': weight,
            'time_seconds': timeSeconds,
            'data': ?data,
            'logged_by': personId,
          })
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      throw AppException('Could not save the set.', cause: e);
    }
  }

  /// Updates an already-logged set (the client edits their own entry — allowed
  /// directly under RLS: `person_id = logged_by = me`).
  static Future<void> updateSet({
    required String tenantId,
    required String entryId,
    int? reps,
    num? weight,
    int? timeSeconds,
    Map<String, dynamic>? data,
  }) async {
    try {
      await SupabaseClientWrapper.db('logged_entries')
          .update({
            'reps': reps,
            'weight': weight,
            'time_seconds': timeSeconds,
            'data': ?data,
          })
          .eq('id', entryId)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not update the set.', cause: e);
    }
  }

  /// Marks a session complete (stamps `last_completed_at`). Definer RPC —
  /// the client owns the assignment but can't write `assignment_sessions`.
  static Future<void> completeSession(String assignmentSessionId) async {
    try {
      await SupabaseClientWrapper.rpc<void>(
        'complete_session',
        params: {'p_assignment_session': assignmentSessionId},
      );
    } catch (e) {
      throw AppException('Could not mark the session complete.', cause: e);
    }
  }

  /// Swaps an exercise for a different library exercise in this instance.
  /// Definer RPC; keeps `exercise_id`-keyed history clean via swapped_from.
  static Future<void> swapExercise({
    required String assignmentExerciseId,
    required String newExerciseId,
  }) async {
    try {
      await SupabaseClientWrapper.rpc<void>(
        'swap_assignment_exercise',
        params: {
          'p_ae': assignmentExerciseId,
          'p_new_exercise': newExerciseId,
        },
      );
    } catch (e) {
      throw AppException('Could not swap the exercise.', cause: e);
    }
  }
}
