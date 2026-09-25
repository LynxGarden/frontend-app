/// A roster of clients (CP5). One program can be group-assigned to all members,
/// fanning out an independent instance per member.
class Group {
  const Group({
    required this.id,
    required this.name,
    this.memberCount = 0,
  });

  final String id;
  final String name;
  final int memberCount;

  factory Group.fromJson(Map<String, dynamic> json) {
    final members = (json['group_members'] as List?) ?? const [];
    return Group(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      memberCount: members.length,
    );
  }
}

/// One membership row (the person + their name), for the group detail list.
class GroupMember {
  const GroupMember({
    required this.id,
    required this.personId,
    required this.name,
  });

  /// The `group_members.id` (the row to remove).
  final String id;
  final String personId;
  final String name;

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final p = json['persons'];
    final name = p is Map
        ? [p['first_name'], p['last_name']]
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .join(' ')
        : '';
    return GroupMember(
      id: json['id'] as String,
      personId: json['person_id'] as String,
      name: name,
    );
  }
}
