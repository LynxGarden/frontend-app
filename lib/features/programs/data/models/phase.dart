import 'package:lynx_app/features/programs/data/models/training_session.dart';

/// A phase within a program — the tier between a program and its sessions
/// (e.g. "Phase 1", "Deload"). Groups an ordered list of sessions.
class Phase {
  const Phase({
    required this.id,
    required this.name,
    required this.orderIndex,
    this.sessions = const [],
  });

  final String id;
  final String name;
  final int orderIndex;
  final List<TrainingSession> sessions;

  int get sessionCount => sessions.length;

  factory Phase.fromJson(Map<String, dynamic> json) {
    final rawSessions = (json['sessions'] as List?) ?? const [];
    final sessions = rawSessions
        .map((s) => TrainingSession.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return Phase(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      orderIndex: (json['order_index'] as int?) ?? 0,
      sessions: sessions,
    );
  }
}
