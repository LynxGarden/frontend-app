/// One exercise + its build-time prescription within a session. Prescription
/// fields are mostly text so coaches can write "8-12", "AMRAP", "%1RM", etc.
class SessionExercise {
  const SessionExercise({
    required this.id,
    required this.exerciseId,
    required this.orderIndex,
    required this.exerciseName,
    this.videoUrl,
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

  final String id;
  final String exerciseId;
  final int orderIndex;
  final String exerciseName;
  final String? videoUrl;

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
    return parts.join(' · ');
  }

  factory SessionExercise.fromJson(Map<String, dynamic> json) {
    final ex = json['exercises'];
    return SessionExercise(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      orderIndex: (json['order_index'] as int?) ?? 0,
      exerciseName: ex is Map ? (ex['name'] as String? ?? '') : '',
      videoUrl: ex is Map ? ex['video_url'] as String? : null,
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
