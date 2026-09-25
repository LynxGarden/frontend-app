import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/review/data/models/review_models.dart';

/// Coach-review reads (CP5). Review-on-login: staff read their clients' completed
/// sessions + logged actuals under the staff RLS granted in CP-B3/CP-B4. No
/// realtime in v1.
class ReviewRepository {
  const ReviewRepository._();

  /// Recent completed sessions across the tenant's clients (the review feed),
  /// newest first, with the client's name resolved.
  static Future<List<CompletedSession>> recentCompleted({
    required String tenantId,
    int limit = 50,
  }) async {
    try {
      final rows = await SupabaseClientWrapper.db('assignment_sessions')
          .select('id, label, last_completed_at, assignments!inner(name, person_id)')
          .eq('tenant_id', tenantId)
          .not('last_completed_at', 'is', null)
          .order('last_completed_at', ascending: false)
          .limit(limit);
      final sessions = (rows as List)
          .map((r) => CompletedSession.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
      if (sessions.isEmpty) return const [];

      final names = await _namesFor(
        tenantId: tenantId,
        personIds: sessions.map((s) => s.personId).toSet(),
      );
      return sessions
          .map((s) => s.withPersonName(names[s.personId] ?? ''))
          .toList();
    } catch (e) {
      throw AppException('Could not load the review feed.', cause: e);
    }
  }

  /// Completed sessions for a single client, newest first.
  static Future<List<CompletedSession>> clientCompleted({
    required String tenantId,
    required String personId,
  }) async {
    try {
      final rows = await SupabaseClientWrapper.db('assignment_sessions')
          .select('id, label, last_completed_at, assignments!inner(name, person_id)')
          .eq('tenant_id', tenantId)
          .eq('assignments.person_id', personId)
          .not('last_completed_at', 'is', null)
          .order('last_completed_at', ascending: false);
      return (rows as List)
          .map((r) => CompletedSession.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw AppException('Could not load completed sessions.', cause: e);
    }
  }

  /// Per-exercise actuals for a reviewed session: each exercise (in order) with
  /// the client's most recent logged occasion for it.
  static Future<List<ExerciseActuals>> sessionActuals({
    required String tenantId,
    required String assignmentSessionId,
    required String personId,
  }) async {
    try {
      final exRows = await SupabaseClientWrapper.db('assignment_exercises')
          .select('id, exercise_id, exercise_name, order_index')
          .eq('tenant_id', tenantId)
          .eq('assignment_session_id', assignmentSessionId)
          .order('order_index');
      final exercises = (exRows as List).cast<Map>();
      if (exercises.isEmpty) return const [];

      final exerciseIds = exercises
          .map((e) => e['exercise_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final logsByExercise = <String, List<LoggedEntry>>{};
      if (exerciseIds.isNotEmpty) {
        final logRows = await SupabaseClientWrapper.db('logged_entries')
            .select('id, exercise_id, logged_at, set_index, reps, weight, time_seconds')
            .eq('person_id', personId)
            .inFilter('exercise_id', exerciseIds)
            .order('logged_at', ascending: false)
            .limit(200);
        for (final r in (logRows as List)) {
          final map = Map<String, dynamic>.from(r as Map);
          (logsByExercise[map['exercise_id'] as String] ??= [])
              .add(LoggedEntry.fromJson(map));
        }
      }

      return exercises.map((e) {
        final exId = e['exercise_id'] as String?;
        final all = exId == null ? const <LoggedEntry>[] : (logsByExercise[exId] ?? const []);
        return ExerciseActuals(
          exerciseId: exId ?? '',
          exerciseName: (e['exercise_name'] as String?) ?? '',
          entries: _mostRecentOccasion(all),
        );
      }).toList();
    } catch (e) {
      throw AppException('Could not load the logged actuals.', cause: e);
    }
  }

  /// Keep only the entries near the newest timestamp (one logging occasion),
  /// ordered by set index.
  static List<LoggedEntry> _mostRecentOccasion(List<LoggedEntry> all) {
    if (all.isEmpty) return const [];
    final newest = all.first.loggedAt; // list arrives newest-first
    final occasion = all
        .where((e) => newest.difference(e.loggedAt).inHours.abs() <= 6)
        .toList()
      ..sort((a, b) => (a.setIndex ?? 0).compareTo(b.setIndex ?? 0));
    return occasion;
  }

  static Future<Map<String, String>> _namesFor({
    required String tenantId,
    required Set<String> personIds,
  }) async {
    if (personIds.isEmpty) return const {};
    final rows = await SupabaseClientWrapper.db('persons')
        .select('id, first_name, last_name')
        .eq('tenant_id', tenantId)
        .inFilter('id', personIds.toList());
    final map = <String, String>{};
    for (final r in (rows as List)) {
      final m = Map<String, dynamic>.from(r as Map);
      final name = [m['first_name'], m['last_name']]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(' ');
      map[m['id'] as String] = name;
    }
    return map;
  }
}
