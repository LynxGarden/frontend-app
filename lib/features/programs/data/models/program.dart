import 'package:lynx_app/features/programs/data/models/phase.dart';

/// A reusable program template — an ordered list of phases, each an ordered
/// menu of sessions (Program → Phase → Session → SessionExercise).
class Program {
  const Program({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.isTemplate = true,
    this.phases = const [],
  });

  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final bool isTemplate;
  final List<Phase> phases;

  int get phaseCount => phases.length;
  int get sessionCount =>
      phases.fold(0, (sum, p) => sum + p.sessions.length);

  /// Shallow parse (list rows) — counts via `phases(sessions(id))`.
  factory Program.fromJson(Map<String, dynamic> json) {
    final rawPhases = (json['phases'] as List?) ?? const [];
    final phases = rawPhases
        .map((p) => Phase.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return Program(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isTemplate: (json['is_template'] as bool?) ?? true,
      phases: phases,
    );
  }
}
