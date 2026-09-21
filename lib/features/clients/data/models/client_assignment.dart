/// A program instance assigned to a client (list view).
class ClientAssignment {
  const ClientAssignment({
    required this.id,
    required this.name,
    required this.isActive,
    this.sessionCount = 0,
  });

  final String id;
  final String name;
  final bool isActive;
  final int sessionCount;

  factory ClientAssignment.fromJson(Map<String, dynamic> json) {
    final sessions = (json['assignment_sessions'] as List?) ?? const [];
    return ClientAssignment(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: (json['is_active'] as bool?) ?? true,
      sessionCount: sessions.length,
    );
  }
}
