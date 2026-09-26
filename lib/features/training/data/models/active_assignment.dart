// Read models for the client daily loop (CP4). These read the per-client
// `assignment_*` instance rows (snapshots) — never the templates.

/// One exercise inside a session of the client's active assignment. Carries the
/// snapshot prescription (the target) plus the snapshot name/video so the loop
/// reads only assignment rows. `exerciseId` keys the "last time" history.
class TrainingExercise {
  const TrainingExercise({
    required this.id,
    required this.exerciseId,
    required this.orderIndex,
    required this.exerciseName,
    this.videoUrl,
    this.videoStoragePath,
    this.swappedFromExerciseId,
    this.sets,
    this.reps,
    this.weight,
    this.loadIntensity,
    this.rpe,
    this.timeSeconds,
    this.tempo,
    this.restSeconds,
    this.setTypeNote,
    this.coachNote,
  });

  /// The `assignment_exercises.id` — the row logged against / swapped.
  final String id;
  final String exerciseId;
  final int orderIndex;
  final String exerciseName;
  final String? videoUrl;
  final String? videoStoragePath;
  final String? swappedFromExerciseId;

  final int? sets;
  final String? reps;
  final String? weight;
  final String? loadIntensity;
  final String? rpe;
  final int? timeSeconds;
  final String? tempo;
  final int? restSeconds;
  final String? setTypeNote;
  final String? coachNote;

  /// The prescribed target, condensed to one line (e.g. `3×8-10 · 60kg · RPE 8`).
  String get targetSummary {
    final parts = <String>[];
    if (sets != null) {
      parts.add('$sets×${reps ?? '—'}');
    } else if (reps != null) {
      parts.add(reps!);
    }
    if (weight != null && weight!.isNotEmpty) parts.add(weight!);
    if (loadIntensity != null && loadIntensity!.isNotEmpty) parts.add(loadIntensity!);
    if (timeSeconds != null) parts.add('${timeSeconds}s');
    if (rpe != null && rpe!.isNotEmpty) parts.add('RPE $rpe');
    if (tempo != null && tempo!.isNotEmpty) parts.add(tempo!);
    if (restSeconds != null) parts.add('rest ${restSeconds}s');
    return parts.join(' · ');
  }

  factory TrainingExercise.fromJson(Map<String, dynamic> json) {
    return TrainingExercise(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      orderIndex: (json['order_index'] as int?) ?? 0,
      exerciseName: (json['exercise_name'] as String?) ?? '',
      videoUrl: json['video_url'] as String?,
      videoStoragePath: json['video_storage_path'] as String?,
      swappedFromExerciseId: json['swapped_from_exercise_id'] as String?,
      sets: json['sets'] as int?,
      reps: json['reps'] as String?,
      weight: json['weight'] as String?,
      loadIntensity: json['load_intensity'] as String?,
      rpe: json['rpe'] as String?,
      timeSeconds: json['time_seconds'] as int?,
      tempo: json['tempo'] as String?,
      restSeconds: json['rest_seconds'] as int?,
      setTypeNote: json['set_type_note'] as String?,
      coachNote: json['coach_note'] as String?,
    );
  }
}

/// One session (A1, A2…) of the active assignment, with its ordered exercises.
class TrainingAssignmentSession {
  const TrainingAssignmentSession({
    required this.id,
    required this.label,
    required this.orderIndex,
    required this.exercises,
    this.lastCompletedAt,
  });

  final String id;
  final String label;
  final int orderIndex;
  final DateTime? lastCompletedAt;
  final List<TrainingExercise> exercises;

  bool get isCompleted => lastCompletedAt != null;

  factory TrainingAssignmentSession.fromJson(Map<String, dynamic> json) {
    final raw = (json['assignment_exercises'] as List?) ?? const [];
    final exercises = raw
        .map((e) => TrainingExercise.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return TrainingAssignmentSession(
      id: json['id'] as String,
      label: (json['label'] as String?) ?? '',
      orderIndex: (json['order_index'] as int?) ?? 0,
      lastCompletedAt: json['last_completed_at'] == null
          ? null
          : DateTime.parse(json['last_completed_at'] as String),
      exercises: exercises,
    );
  }
}

/// The client's active program instance: a menu of sessions.
class ActiveAssignment {
  const ActiveAssignment({
    required this.id,
    required this.name,
    required this.sessions,
  });

  final String id;
  final String name;
  final List<TrainingAssignmentSession> sessions;

  factory ActiveAssignment.fromJson(Map<String, dynamic> json) {
    final raw = (json['assignment_sessions'] as List?) ?? const [];
    final sessions = raw
        .map((s) =>
            TrainingAssignmentSession.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return ActiveAssignment(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      sessions: sessions,
    );
  }
}

/// A single logged set from a prior visit — the "last time" data.
class LoggedEntry {
  const LoggedEntry({
    required this.id,
    required this.loggedAt,
    this.setIndex,
    this.reps,
    this.weight,
    this.timeSeconds,
  });

  final String id;
  final DateTime loggedAt;
  final int? setIndex;
  final int? reps;
  final num? weight;
  final int? timeSeconds;

  /// One-line summary of this set (e.g. `8 × 60` or `45s`).
  String get summary {
    final parts = <String>[];
    if (reps != null) {
      parts.add(weight != null ? '$reps × ${_trim(weight!)}' : '$reps');
    } else if (weight != null) {
      parts.add(_trim(weight!));
    }
    if (timeSeconds != null) parts.add('${timeSeconds}s');
    return parts.join(' ');
  }

  static String _trim(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  factory LoggedEntry.fromJson(Map<String, dynamic> json) {
    return LoggedEntry(
      id: json['id'] as String,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      setIndex: json['set_index'] as int?,
      reps: json['reps'] as int?,
      weight: json['weight'] as num?,
      timeSeconds: json['time_seconds'] as int?,
    );
  }
}
