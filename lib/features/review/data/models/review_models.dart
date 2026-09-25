import 'package:lynx_app/features/training/data/models/active_assignment.dart' show LoggedEntry;

export 'package:lynx_app/features/training/data/models/active_assignment.dart' show LoggedEntry;

/// A session a client marked complete — the unit of coach review. `personName`
/// is filled only for the tenant-wide feed (empty on a per-client list).
class CompletedSession {
  const CompletedSession({
    required this.assignmentSessionId,
    required this.label,
    required this.assignmentName,
    required this.personId,
    required this.completedAt,
    this.personName = '',
  });

  final String assignmentSessionId;
  final String label;
  final String assignmentName;
  final String personId;
  final DateTime completedAt;
  final String personName;

  factory CompletedSession.fromJson(Map<String, dynamic> json) {
    final a = json['assignments'];
    return CompletedSession(
      assignmentSessionId: json['id'] as String,
      label: (json['label'] as String?) ?? '',
      assignmentName: a is Map ? (a['name'] as String? ?? '') : '',
      personId: a is Map ? (a['person_id'] as String? ?? '') : '',
      completedAt: DateTime.parse(json['last_completed_at'] as String),
    );
  }

  CompletedSession withPersonName(String name) => CompletedSession(
        assignmentSessionId: assignmentSessionId,
        label: label,
        assignmentName: assignmentName,
        personId: personId,
        completedAt: completedAt,
        personName: name,
      );
}

/// One exercise in a reviewed session plus the client's most recent logged sets.
class ExerciseActuals {
  const ExerciseActuals({
    required this.exerciseId,
    required this.exerciseName,
    required this.entries,
  });

  final String exerciseId;
  final String exerciseName;
  final List<LoggedEntry> entries;
}
