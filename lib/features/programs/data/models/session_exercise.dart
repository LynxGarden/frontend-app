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

  bool get isGrouped => methodGroupId != null && methodGroupId!.isNotEmpty;

  /// A short one-line summary of the prescription for list rows.
  String get prescriptionSummary {
    final parts = <String>[];
    if (sets != null) {
      parts.add('$sets×${reps ?? '—'}');
    } else if (reps != null) {
      parts.add(reps!);
    }
    if (weight != null && weight!.isNotEmpty) parts.add(weight!);
    if (timeSeconds != null) parts.add('${timeSeconds}s');
    if (rpe != null && rpe!.isNotEmpty) parts.add('RPE $rpe');
    if (rir != null && rir!.isNotEmpty) parts.add('RIR $rir');
    return parts.join(' · ');
  }

  factory SessionExercise.fromJson(Map<String, dynamic> json) {
    final ex = json['exercises'];
    final rawConfig = json['method_config'];
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
    );
  }
}
