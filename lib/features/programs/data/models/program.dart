import 'package:lynx_app/features/programs/data/models/training_session.dart';

/// A reusable program template — an ordered menu of sessions.
class Program {
  const Program({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.isTemplate = true,
    this.sessions = const [],
  });

  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final bool isTemplate;
  final List<TrainingSession> sessions;

  int get sessionCount => sessions.length;

  /// Shallow parse (list rows) — no nested sessions.
  factory Program.fromJson(Map<String, dynamic> json) {
    final rawSessions = (json['sessions'] as List?) ?? const [];
    final sessions = rawSessions
        .map((s) => TrainingSession.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return Program(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isTemplate: (json['is_template'] as bool?) ?? true,
      sessions: sessions,
    );
  }
}
