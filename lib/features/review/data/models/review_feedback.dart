/// The client's difficulty rating for one exercise (1–5).
class ExerciseFeedback {
  const ExerciseFeedback({
    required this.id,
    required this.assignmentExerciseId,
    required this.difficulty,
    this.note,
  });

  final String id;
  final String assignmentExerciseId;
  final int difficulty;
  final String? note;

  factory ExerciseFeedback.fromJson(Map<String, dynamic> json) =>
      ExerciseFeedback(
        id: json['id'] as String,
        assignmentExerciseId: json['assignment_exercise_id'] as String,
        difficulty: (json['difficulty'] as num).toInt(),
        note: json['note'] as String?,
      );
}

/// A coach comment on a client's exercise.
class ExerciseComment {
  const ExerciseComment({
    required this.id,
    required this.assignmentExerciseId,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String assignmentExerciseId;
  final String authorId;
  final String body;
  final DateTime createdAt;

  factory ExerciseComment.fromJson(Map<String, dynamic> json) => ExerciseComment(
        id: json['id'] as String,
        assignmentExerciseId: json['assignment_exercise_id'] as String,
        authorId: json['author_id'] as String,
        body: (json['body'] as String?) ?? '',
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}

/// A coach reaction (like) on a client's exercise.
class ExerciseReaction {
  const ExerciseReaction({
    required this.id,
    required this.assignmentExerciseId,
    required this.authorId,
    this.kind = 'like',
  });

  final String id;
  final String assignmentExerciseId;
  final String authorId;
  final String kind;

  factory ExerciseReaction.fromJson(Map<String, dynamic> json) =>
      ExerciseReaction(
        id: json['id'] as String,
        assignmentExerciseId: json['assignment_exercise_id'] as String,
        authorId: json['author_id'] as String,
        kind: (json['kind'] as String?) ?? 'like',
      );
}

/// A client's personal best for an exercise (computed from logged_entries).
class PersonalBest {
  const PersonalBest({
    this.bestWeight,
    this.bestReps,
    this.bestVolume,
  });

  final num? bestWeight;
  final int? bestReps;
  final num? bestVolume;

  bool get isEmpty => bestWeight == null && bestReps == null && bestVolume == null;
}

// --- Coach deep-dive tree (Program → Phase → Session → Exercise) -------------

class ReviewExercise {
  const ReviewExercise({
    required this.assignmentExerciseId,
    required this.exerciseId,
    required this.name,
    required this.orderIndex,
  });

  final String assignmentExerciseId;
  final String exerciseId;
  final String name;
  final int orderIndex;

  factory ReviewExercise.fromJson(Map<String, dynamic> json) => ReviewExercise(
        assignmentExerciseId: json['id'] as String,
        exerciseId: (json['exercise_id'] as String?) ?? '',
        name: (json['exercise_name'] as String?) ?? '',
        orderIndex: (json['order_index'] as int?) ?? 0,
      );
}

class ReviewSession {
  const ReviewSession({
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
  final List<ReviewExercise> exercises;

  bool get isCompleted => lastCompletedAt != null;

  factory ReviewSession.fromJson(Map<String, dynamic> json) {
    final raw = (json['assignment_exercises'] as List?) ?? const [];
    final exercises = raw
        .map((e) => ReviewExercise.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) {
        final c = a.orderIndex.compareTo(b.orderIndex);
        return c != 0 ? c : a.assignmentExerciseId.compareTo(b.assignmentExerciseId);
      });
    return ReviewSession(
      id: json['id'] as String,
      label: (json['label'] as String?) ?? '',
      orderIndex: (json['order_index'] as int?) ?? 0,
      lastCompletedAt: json['last_completed_at'] == null
          ? null
          : DateTime.parse(json['last_completed_at'] as String).toLocal(),
      exercises: exercises,
    );
  }
}

class ReviewPhase {
  const ReviewPhase({
    required this.id,
    required this.name,
    required this.orderIndex,
    required this.sessions,
  });

  final String id;
  final String name;
  final int orderIndex;
  final List<ReviewSession> sessions;

  factory ReviewPhase.fromJson(Map<String, dynamic> json) {
    final raw = (json['assignment_sessions'] as List?) ?? const [];
    final sessions = raw
        .map((s) => ReviewSession.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return ReviewPhase(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      orderIndex: (json['order_index'] as int?) ?? 0,
      sessions: sessions,
    );
  }
}

class ReviewAssignmentTree {
  const ReviewAssignmentTree({
    required this.id,
    required this.name,
    required this.phases,
  });

  final String id;
  final String name;
  final List<ReviewPhase> phases;

  factory ReviewAssignmentTree.fromJson(Map<String, dynamic> json) {
    final raw = (json['assignment_phases'] as List?) ?? const [];
    final phases = raw
        .map((p) => ReviewPhase.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return ReviewAssignmentTree(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      phases: phases,
    );
  }
}
