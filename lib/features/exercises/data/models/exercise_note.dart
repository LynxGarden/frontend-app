/// A client's personal, global note for an exercise (keyed on exercise_id, so it
/// follows the movement across programs). One per (person, exercise).
class ExerciseNote {
  const ExerciseNote({
    required this.exerciseId,
    required this.note,
    this.updatedAt,
  });

  final String exerciseId;
  final String note;
  final DateTime? updatedAt;

  factory ExerciseNote.fromJson(Map<String, dynamic> json) => ExerciseNote(
        exerciseId: json['exercise_id'] as String,
        note: (json['note'] as String?) ?? '',
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at'] as String),
      );
}
