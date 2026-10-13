import 'package:lynx_app/features/programs/data/models/session_exercise.dart';

/// An ordered session within a phase (A1, A2, B1…). Named TrainingSession to
/// avoid clashing with Supabase's auth `Session`.
class TrainingSession {
  const TrainingSession({
    required this.id,
    required this.label,
    required this.orderIndex,
    this.phaseId,
    this.exercises = const [],
  });

  final String id;
  final String label;
  final int orderIndex;
  final String? phaseId;
  final List<SessionExercise> exercises;

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    final rawExercises = (json['session_exercises'] as List?) ?? const [];
    final exercises = rawExercises
        .map((e) => SessionExercise.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) {
        final byOrder = a.orderIndex.compareTo(b.orderIndex);
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });
    return TrainingSession(
      id: json['id'] as String,
      // Null-tolerant: the shallow templates query selects `sessions(id)` only.
      label: (json['label'] as String?) ?? '',
      orderIndex: (json['order_index'] as int?) ?? 0,
      phaseId: json['phase_id'] as String?,
      exercises: exercises,
    );
  }
}
