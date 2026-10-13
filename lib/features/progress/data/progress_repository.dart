import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/progress/data/models/progress_models.dart';

/// Client-side progress aggregation over `logged_entries` + `assignment_exercises`
/// (both client-readable). The client cannot read the `exercises` table, so
/// exercise display names come from their assignment snapshots.
class ProgressRepository {
  const ProgressRepository._();

  /// Monday (date-only) of the week containing [d].
  static DateTime weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// Activity summary: visits this week + a consecutive-week streak.
  static Future<ProgressSummary> loadSummary({
    required String tenantId,
    required String personId,
  }) async {
    try {
      final rows = await SupabaseClientWrapper.db('logged_entries')
          .select('logged_at')
          .eq('tenant_id', tenantId)
          .eq('person_id', personId)
          .order('logged_at', ascending: false)
          .limit(2000);

      final days = <DateTime>{};
      for (final r in rows as List) {
        final at = DateTime.parse((r as Map)['logged_at'] as String).toLocal();
        days.add(DateTime(at.year, at.month, at.day));
      }
      if (days.isEmpty) return ProgressSummary.empty;

      final thisWeekStart = weekStart(DateTime.now());
      final visitsThisWeek =
          days.where((d) => !d.isBefore(thisWeekStart)).length;

      // Weeks (by Monday) that have ≥1 training day.
      final activeWeeks = days.map(weekStart).toSet();
      // Count back from this week (allowing the streak to "still be alive" if
      // only last week is active and this week hasn't started training yet).
      var streak = 0;
      var cursor = thisWeekStart;
      if (!activeWeeks.contains(cursor)) {
        cursor = cursor.subtract(const Duration(days: 7));
      }
      while (activeWeeks.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 7));
      }

      return ProgressSummary(
        visitsThisWeek: visitsThisWeek,
        weekStreak: streak,
        hasAnyData: true,
      );
    } catch (e) {
      throw AppException('Could not load your progress.', cause: e);
    }
  }

  /// The exercises the client can view progress for — distinct movements from
  /// their assignment snapshots (name resolved there).
  static Future<List<TrackedExercise>> trackedExercises({
    required String tenantId,
    required String personId,
  }) async {
    try {
      final rows = await SupabaseClientWrapper.db('assignments')
          .select(
              'assignment_sessions(assignment_exercises(exercise_id, exercise_name))')
          .eq('tenant_id', tenantId)
          .eq('person_id', personId);

      final byId = <String, String>{};
      for (final a in rows as List) {
        final sessions = ((a as Map)['assignment_sessions'] as List?) ?? const [];
        for (final s in sessions) {
          final exs = ((s as Map)['assignment_exercises'] as List?) ?? const [];
          for (final e in exs) {
            final m = e as Map;
            final id = m['exercise_id'] as String?;
            if (id == null) continue;
            byId.putIfAbsent(id, () => (m['exercise_name'] as String?) ?? '');
          }
        }
      }
      final list = byId.entries
          .map((e) => TrackedExercise(exerciseId: e.key, name: e.value))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    } catch (e) {
      throw AppException('Could not load your exercises.', cause: e);
    }
  }

  /// Per-exercise aggregates: PBs + a weekly volume/top-weight series.
  static Future<ExerciseProgress> exerciseProgress({
    required String tenantId,
    required String personId,
    required String exerciseId,
  }) async {
    try {
      final rows = await SupabaseClientWrapper.db('logged_entries')
          .select('reps, weight, logged_at')
          .eq('tenant_id', tenantId)
          .eq('person_id', personId)
          .eq('exercise_id', exerciseId)
          .order('logged_at', ascending: true)
          .limit(5000);

      double? bestWeight;
      int? bestReps;
      double? bestSetVolume;
      final volByWeek = <DateTime, double>{};
      final topWeightByWeek = <DateTime, double>{};

      for (final r in rows as List) {
        final m = r as Map;
        final reps = (m['reps'] as int?);
        final weight = (m['weight'] as num?)?.toDouble();
        final at = DateTime.parse(m['logged_at'] as String).toLocal();
        final wk = weekStart(at);

        if (weight != null) {
          if (bestWeight == null || weight > bestWeight) bestWeight = weight;
          final cur = topWeightByWeek[wk] ?? 0;
          if (weight > cur) topWeightByWeek[wk] = weight;
        }
        if (reps != null) {
          if (bestReps == null || reps > bestReps) bestReps = reps;
        }
        if (reps != null && weight != null) {
          final setVol = reps * weight;
          if (bestSetVolume == null || setVol > bestSetVolume) {
            bestSetVolume = setVol;
          }
          volByWeek[wk] = (volByWeek[wk] ?? 0) + setVol;
        }
      }

      final weeks = {...volByWeek.keys, ...topWeightByWeek.keys}.toList()
        ..sort();
      final weekly = weeks
          .map((w) => WeeklyPoint(
                weekStart: w,
                volume: volByWeek[w] ?? 0,
                topWeight: topWeightByWeek[w] ?? 0,
              ))
          .toList();
      // Keep the most recent 12 weeks for a legible chart.
      final trimmed =
          weekly.length > 12 ? weekly.sublist(weekly.length - 12) : weekly;

      return ExerciseProgress(
        bestWeight: bestWeight,
        bestReps: bestReps,
        bestSetVolume: bestSetVolume,
        weekly: trimmed,
      );
    } catch (e) {
      throw AppException('Could not load exercise progress.', cause: e);
    }
  }
}
