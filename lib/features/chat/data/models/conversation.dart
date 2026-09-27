/// A 1:1 chat conversation between a client and their assigned coach.
class Conversation {
  const Conversation({
    required this.id,
    required this.tenantId,
    required this.clientPersonId,
    required this.coachPersonId,
    this.lastMessageAt,
  });

  final String id;
  final String tenantId;
  final String clientPersonId;
  final String coachPersonId;
  final DateTime? lastMessageAt;

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        clientPersonId: json['client_person_id'] as String,
        coachPersonId: json['coach_person_id'] as String,
        lastMessageAt: json['last_message_at'] == null
            ? null
            : DateTime.tryParse(json['last_message_at'] as String),
      );
}
