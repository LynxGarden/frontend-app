import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/review/data/models/review_feedback.dart';

/// Data access for coach review feedback (difficulty ratings, comments, likes),
/// personal bests, the per-client assignment tree, and phase reset.
class FeedbackRepository {
  const FeedbackRepository._();

  // --- client difficulty rating ---------------------------------------------
  static Future<void> saveFeedback({
    required String tenantId,
    required String personId,
    required String assignmentExerciseId,
    required String exerciseId,
    required int difficulty,
    String? note,
  }) async {
    try {
      await SupabaseClientWrapper.db('exercise_feedback').upsert(
        {
          'tenant_id': tenantId,
          'person_id': personId,
          'assignment_exercise_id': assignmentExerciseId,
          'exercise_id': exerciseId,
          'difficulty': difficulty,
          'note': note,
        },
        onConflict: 'assignment_exercise_id,person_id',
      );
    } catch (e) {
      throw AppException('Could not save your rating.', cause: e);
    }
  }

  static Future<ExerciseFeedback?> feedbackFor({
    required String tenantId,
    required String assignmentExerciseId,
  }) async {
    try {
      final row = await SupabaseClientWrapper.db('exercise_feedback')
          .select('id, assignment_exercise_id, difficulty, note')
          .eq('tenant_id', tenantId)
          .eq('assignment_exercise_id', assignmentExerciseId)
          .maybeSingle();
      return row == null
          ? null
          : ExerciseFeedback.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException('Could not load the rating.', cause: e);
    }
  }

  /// Ratings for many assignment-exercise ids, keyed by ae id.
  static Future<Map<String, ExerciseFeedback>> feedbackForAes({
    required String tenantId,
    required List<String> aeIds,
  }) async {
    if (aeIds.isEmpty) return const {};
    try {
      final rows = await SupabaseClientWrapper.db('exercise_feedback')
          .select('id, assignment_exercise_id, difficulty, note')
          .eq('tenant_id', tenantId)
          .inFilter('assignment_exercise_id', aeIds);
      final map = <String, ExerciseFeedback>{};
      for (final r in rows as List) {
        final f = ExerciseFeedback.fromJson(Map<String, dynamic>.from(r as Map));
        map[f.assignmentExerciseId] = f;
      }
      return map;
    } catch (e) {
      throw AppException('Could not load ratings.', cause: e);
    }
  }

  // --- comments -------------------------------------------------------------
  static Future<List<ExerciseComment>> listComments({
    required String tenantId,
    required String assignmentExerciseId,
  }) async {
    try {
      final rows = await SupabaseClientWrapper.db('exercise_comments')
          .select('id, assignment_exercise_id, author_id, body, created_at')
          .eq('tenant_id', tenantId)
          .eq('assignment_exercise_id', assignmentExerciseId)
          .order('created_at');
      return (rows as List)
          .map((r) => ExerciseComment.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw AppException('Could not load comments.', cause: e);
    }
  }

  static Future<void> addComment({
    required String tenantId,
    required String assignmentExerciseId,
    required String authorId,
    required String body,
  }) async {
    try {
      await SupabaseClientWrapper.db('exercise_comments').insert({
        'tenant_id': tenantId,
        'assignment_exercise_id': assignmentExerciseId,
        'author_id': authorId,
        'body': body.trim(),
      });
    } catch (e) {
      throw AppException('Could not post the comment.', cause: e);
    }
  }

  /// Comment counts per assignment-exercise id.
  static Future<Map<String, int>> commentCountsForAes({
    required String tenantId,
    required List<String> aeIds,
  }) async {
    if (aeIds.isEmpty) return const {};
    try {
      final rows = await SupabaseClientWrapper.db('exercise_comments')
          .select('assignment_exercise_id')
          .eq('tenant_id', tenantId)
          .inFilter('assignment_exercise_id', aeIds);
      final counts = <String, int>{};
      for (final r in rows as List) {
        final id = (r as Map)['assignment_exercise_id'] as String;
        counts[id] = (counts[id] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      throw AppException('Could not load comments.', cause: e);
    }
  }

  // --- reactions (likes) ----------------------------------------------------
  static Future<void> toggleLike({
    required String tenantId,
    required String assignmentExerciseId,
    required String authorId,
    required bool liked,
  }) async {
    try {
      if (liked) {
        await SupabaseClientWrapper.db('exercise_reactions').insert({
          'tenant_id': tenantId,
          'assignment_exercise_id': assignmentExerciseId,
          'author_id': authorId,
          'kind': 'like',
        });
      } else {
        await SupabaseClientWrapper.db('exercise_reactions')
            .delete()
            .eq('tenant_id', tenantId)
            .eq('assignment_exercise_id', assignmentExerciseId)
            .eq('author_id', authorId)
            .eq('kind', 'like');
      }
    } catch (e) {
      throw AppException('Could not update your like.', cause: e);
    }
  }

  /// The set of ae ids the author has liked, among [aeIds].
  static Future<Set<String>> likedAes({
    required String tenantId,
    required String authorId,
    required List<String> aeIds,
  }) async {
    if (aeIds.isEmpty) return <String>{};
    try {
      final rows = await SupabaseClientWrapper.db('exercise_reactions')
          .select('assignment_exercise_id')
          .eq('tenant_id', tenantId)
          .eq('author_id', authorId)
          .eq('kind', 'like')
          .inFilter('assignment_exercise_id', aeIds);
      return {
        for (final r in rows as List)
          (r as Map)['assignment_exercise_id'] as String
      };
    } catch (e) {
      throw AppException('Could not load likes.', cause: e);
    }
  }

  // --- session rating -------------------------------------------------------

  /// The client's 1–10 difficulty rating from the session's most recent
  /// completion. Null = never rated — or an older backend without the
  /// `last_rating` column yet, which is tolerated silently (the rating is
  /// decorative, so review must never fail on it).
  static Future<int?> sessionRating(String assignmentSessionId) async {
    try {
      final row = await SupabaseClientWrapper.db('assignment_sessions')
          .select('last_rating')
          .eq('id', assignmentSessionId)
          .maybeSingle();
      return (row?['last_rating'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  // --- personal bests -------------------------------------------------------
  static Future<PersonalBest> personalBestFor({
    required String personId,
    required String exerciseId,
  }) async {
    try {
      final rows = await SupabaseClientWrapper.db('logged_entries')
          .select('reps, weight, logged_at')
          .eq('person_id', personId)
          .eq('exercise_id', exerciseId)
          .limit(2000);
      num? bestWeight;
      int? bestReps;
      // Volume counts every set: sum of reps × weight across all sets logged
      // on the same day, best day wins.
      final volByDay = <String, num>{};
      for (final r in rows as List) {
        final m = r as Map;
        final reps = m['reps'] as int?;
        final weight = m['weight'] as num?;
        if (weight != null && (bestWeight == null || weight > bestWeight)) {
          bestWeight = weight;
        }
        if (reps != null && (bestReps == null || reps > bestReps)) {
          bestReps = reps;
        }
        if (reps != null && weight != null && m['logged_at'] != null) {
          final day = DateTime.parse(m['logged_at'] as String)
              .toLocal()
              .toIso8601String()
              .substring(0, 10);
          volByDay[day] = (volByDay[day] ?? 0) + reps * weight;
        }
      }
      num? bestVolume;
      for (final v in volByDay.values) {
        if (bestVolume == null || v > bestVolume) bestVolume = v;
      }
      return PersonalBest(
          bestWeight: bestWeight, bestReps: bestReps, bestVolume: bestVolume);
    } catch (e) {
      throw AppException('Could not load personal bests.', cause: e);
    }
  }

  // --- assignment tree ------------------------------------------------------
  static Future<ReviewAssignmentTree?> loadClientAssignmentTree({
    required String tenantId,
    required String personId,
  }) async {
    try {
      final row = await SupabaseClientWrapper.db('assignments')
          .select(
            'id, name, '
            'assignment_phases(id, name, order_index, '
            'assignment_sessions(id, label, order_index, last_completed_at, '
            'assignment_exercises(id, exercise_id, exercise_name, order_index)))',
          )
          .eq('tenant_id', tenantId)
          .eq('person_id', personId)
          .eq('is_active', true)
          .order('assigned_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      return ReviewAssignmentTree.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException('Could not load the program.', cause: e);
    }
  }

  // --- phase reset ----------------------------------------------------------
  static Future<void> resetPhase(String assignmentPhaseId) async {
    try {
      await SupabaseClientWrapper.rpc<void>(
        'reset_assignment_phase',
        params: {'p_assignment_phase': assignmentPhaseId},
      );
    } catch (e) {
      throw AppException('Could not reset the phase.', cause: e);
    }
  }
}
