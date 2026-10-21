// Read models for the client daily loop (CP4). These read the per-client
// `assignment_*` instance rows (snapshots) — never the templates.

import 'package:lynx_app/features/exercises/data/models/metric_field.dart';
import 'package:lynx_app/features/programs/data/models/training_method.dart';

/// One exercise inside a session of the client's active assignment. Carries the
/// snapshot prescription (the target) plus the snapshot name/video so the loop
/// reads only assignment rows. `exerciseId` keys the "last time" history.
class TrainingExercise {
  const TrainingExercise({
    required this.id,
    required this.exerciseId,
    required this.orderIndex,
    required this.exerciseName,
    this.description,
    this.videoUrl,
    this.videoStoragePath,
    this.thumbnailStoragePath,
    this.swappedFromExerciseId,
    this.sets,
    this.reps,
    this.weight,
    this.loadIntensity,
    this.rpe,
    this.rir,
    this.timeSeconds,
    this.tempo,
    this.restSeconds,
    this.setTypeNote,
    this.coachNote,
    this.metricSchema = const [],
    this.targetMetrics = const {},
    this.method = TrainingMethod.straight,
    this.methodGroupId,
    this.groupOrder = 0,
    this.methodConfig = const {},
  });

  /// The `assignment_exercises.id` — the row logged against / swapped.
  final String id;
  final String exerciseId;
  final int orderIndex;
  final String exerciseName;
  final String? description;
  final String? videoUrl;
  final String? videoStoragePath;
  /// Path in the public `exercise-thumbnails` bucket (snapshotted at assign
  /// time), or null for legacy assignments made before thumbnails existed.
  final String? thumbnailStoragePath;
  final String? swappedFromExerciseId;

  final int? sets;
  final String? reps;
  final String? weight;
  final String? loadIntensity;
  final String? rpe;
  final String? rir;
  final int? timeSeconds;
  final String? tempo;
  final int? restSeconds;
  final String? setTypeNote;
  final String? coachNote;

  /// Config-driven logging fields (snapshotted). Empty → legacy reps/weight.
  final List<MetricField> metricSchema;

  /// Per-metric prescribed targets keyed by metric-field key (snapshotted).
  /// Only used when [method] is [TrainingMethod.none].
  final Map<String, String> targetMetrics;

  /// Structured training method + grouping (snapshotted).
  final TrainingMethod method;
  final String? methodGroupId;
  final int groupOrder;
  final Map<String, dynamic> methodConfig;

  bool get isGrouped => methodGroupId != null && methodGroupId!.isNotEmpty;

  /// The prescribed target, condensed to one line
  /// (e.g. `3×8-10 · 60kg @ RPE 8 · Tempo: 3-1-0-1`).
  String get targetSummary {
    // Schema-driven exercise (no method): read the custom targets in the
    // exercise's field order (e.g. "5:00 · 30:00").
    if (method == TrainingMethod.none) {
      final parts = <String>[];
      for (final f in metricSchema) {
        final v = targetMetrics[f.key];
        if (v != null && v.trim().isNotEmpty) {
          final unit =
              (f.unit != null && f.unit!.trim().isNotEmpty) ? ' ${f.unit!.trim()}' : '';
          parts.add('${v.trim()}$unit');
        }
      }
      if (parts.isEmpty) {
        parts.addAll(targetMetrics.values
            .where((v) => v.trim().isNotEmpty)
            .map((v) => v.trim()));
      }
      return parts.join(' · ');
    }

    final volume = <String>[];
    if (sets != null) {
      volume.add('$sets×${reps ?? '—'}');
    } else if (reps != null) {
      volume.add(reps!);
    }
    if (weight != null && weight!.isNotEmpty) volume.add(weight!);
    if (loadIntensity != null && loadIntensity!.isNotEmpty) volume.add(loadIntensity!);
    if (timeSeconds != null) volume.add('${timeSeconds}s');

    final intensity = <String>[];
    if (rpe != null && rpe!.isNotEmpty) intensity.add('RPE $rpe');
    if (rir != null && rir!.isNotEmpty) intensity.add('RIR $rir');

    var head = volume.join(' · ');
    if (intensity.isNotEmpty) {
      final intensityStr = intensity.join(' · ');
      head = head.isEmpty ? intensityStr : '$head @ $intensityStr';
    }

    final parts = <String>[if (head.isNotEmpty) head];
    if (tempo != null && tempo!.isNotEmpty) parts.add('Tempo: ${tempo!}');
    if (restSeconds != null) parts.add('rest ${restSeconds}s');
    return parts.join(' · ');
  }

  factory TrainingExercise.fromJson(Map<String, dynamic> json) {
    final rawConfig = json['method_config'];
    return TrainingExercise(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      orderIndex: (json['order_index'] as int?) ?? 0,
      exerciseName: (json['exercise_name'] as String?) ?? '',
      description: json['description'] as String?,
      videoUrl: json['video_url'] as String?,
      videoStoragePath: json['video_storage_path'] as String?,
      thumbnailStoragePath: json['thumbnail_storage_path'] as String?,
      swappedFromExerciseId: json['swapped_from_exercise_id'] as String?,
      sets: json['sets'] as int?,
      reps: json['reps'] as String?,
      weight: json['weight'] as String?,
      loadIntensity: json['load_intensity'] as String?,
      rpe: json['rpe'] as String?,
      rir: json['rir'] as String?,
      timeSeconds: json['time_seconds'] as int?,
      tempo: json['tempo'] as String?,
      restSeconds: json['rest_seconds'] as int?,
      setTypeNote: json['set_type_note'] as String?,
      coachNote: json['coach_note'] as String?,
      metricSchema: MetricField.listFromDb(json['metric_schema']),
      targetMetrics: json['target_metrics'] is Map
          ? (json['target_metrics'] as Map)
              .map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
          : const {},
      method: methodFromDb((json['method'] as String?) ?? 'straight'),
      methodGroupId: json['method_group_id'] as String?,
      groupOrder: (json['group_order'] as int?) ?? 0,
      methodConfig:
          rawConfig is Map ? Map<String, dynamic>.from(rawConfig) : const {},
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
      // Tie-break on id so the order is deterministic and matches the coach's
      // review even when order_index values collide (e.g. legacy all-zero rows).
      ..sort((a, b) {
        final c = a.orderIndex.compareTo(b.orderIndex);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
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
    this.description,
  });

  final String id;
  final String name;
  final String? description;
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
      description: json['description'] as String?,
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
    this.data = const {},
  });

  final String id;
  final DateTime loggedAt;
  final int? setIndex;
  final int? reps;
  final num? weight;
  final int? timeSeconds;

  /// Config-driven actuals keyed by metric-field key (mirrors the schema).
  final Map<String, dynamic> data;

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
    final rawData = json['data'];
    return LoggedEntry(
      id: json['id'] as String,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      setIndex: json['set_index'] as int?,
      reps: json['reps'] as int?,
      weight: json['weight'] as num?,
      timeSeconds: json['time_seconds'] as int?,
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : const {},
    );
  }
}
