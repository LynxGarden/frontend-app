import 'package:lynx_app/features/exercises/data/models/metric_field.dart';
import 'package:lynx_app/features/programs/data/models/training_method.dart';

/// One exercise + its build-time prescription within a session. Prescription
/// fields are mostly text so coaches can write "8-12", "AMRAP", "%1RM", etc.
class SessionExercise {
  const SessionExercise({
    required this.id,
    required this.exerciseId,
    required this.orderIndex,
    required this.exerciseName,
    this.videoUrl,
    this.thumbnailStoragePath,
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
    this.method = TrainingMethod.straight,
    this.methodGroupId,
    this.groupOrder = 0,
    this.methodConfig = const {},
    this.weekLabel,
    this.metricSchema = const [],
    this.targetMetrics = const {},
  });

  final String id;
  final String exerciseId;
  final int orderIndex;
  final String exerciseName;
  final String? videoUrl;
  final String? thumbnailStoragePath;

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

  /// Structured training method + grouping.
  final TrainingMethod method;
  final String? methodGroupId;
  final int groupOrder;
  final Map<String, dynamic> methodConfig;

  /// Coach-only periodization tag (e.g. "Week 1"). Never shown to the client.
  final String? weekLabel;

  /// The exercise's config-driven logging fields (from `exercises.metric_schema`).
  /// Drives the prescription form when [method] is [TrainingMethod.none].
  final List<MetricField> metricSchema;

  /// Per-metric prescribed targets keyed by metric-field key (e.g.
  /// `{"pace": "5:00", "duration": "1800"}`). Only used for method = none.
  final Map<String, String> targetMetrics;

  bool get isGrouped => methodGroupId != null && methodGroupId!.isNotEmpty;

  /// A short one-line summary of the prescription for list rows. Volume/load
  /// parts are joined by "·"; the intensity (RPE/RIR) is appended after an "@",
  /// e.g. "4×8-12 · 100kg @ RPE 7".
  String get prescriptionSummary {
    // Schema-driven exercise (no method): summarise the custom targets in the
    // exercise's own field order, e.g. "5:00 · 30:00".
    if (method == TrainingMethod.none) {
      final parts = <String>[];
      for (final f in metricSchema) {
        final v = targetMetrics[f.key];
        if (v != null && v.trim().isNotEmpty) parts.add(v.trim());
      }
      // Fall back to any targets not covered by the schema (defensive).
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
    if (timeSeconds != null) volume.add('${timeSeconds}s');

    final intensity = <String>[];
    if (rpe != null && rpe!.isNotEmpty) intensity.add('RPE $rpe');
    if (rir != null && rir!.isNotEmpty) intensity.add('RIR $rir');

    final volumeStr = volume.join(' · ');
    final intensityStr = intensity.join(' · ');
    var head = volumeStr;
    if (intensityStr.isNotEmpty) {
      head = head.isEmpty ? intensityStr : '$head @ $intensityStr';
    }
    final parts = <String>[if (head.isNotEmpty) head];
    if (tempo != null && tempo!.isNotEmpty) parts.add('Tempo: ${tempo!}');
    return parts.join(' · ');
  }

  factory SessionExercise.fromJson(Map<String, dynamic> json) {
    final ex = json['exercises'];
    final rawConfig = json['method_config'];
    final rawTargets = json['target_metrics'];
    return SessionExercise(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      orderIndex: (json['order_index'] as int?) ?? 0,
      exerciseName: ex is Map ? (ex['name'] as String? ?? '') : '',
      videoUrl: ex is Map ? ex['video_url'] as String? : null,
      thumbnailStoragePath:
          ex is Map ? ex['thumbnail_storage_path'] as String? : null,
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
      method: methodFromDb((json['method'] as String?) ?? 'straight'),
      methodGroupId: json['method_group_id'] as String?,
      groupOrder: (json['group_order'] as int?) ?? 0,
      methodConfig:
          rawConfig is Map ? Map<String, dynamic>.from(rawConfig) : const {},
      weekLabel: json['week_label'] as String?,
      metricSchema:
          ex is Map ? MetricField.listFromDb(ex['metric_schema']) : const [],
      targetMetrics: rawTargets is Map
          ? rawTargets.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
          : const {},
    );
  }
}
