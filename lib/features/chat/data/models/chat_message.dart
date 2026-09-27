/// A single chat message (text and/or image). `client_person_id` /
/// `coach_person_id` are denormalized from the conversation, so a message is
/// "from the client" when [senderPersonId] == [clientPersonId].
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderPersonId,
    required this.clientPersonId,
    required this.coachPersonId,
    required this.createdAt,
    this.body,
    this.imagePath,
    this.readAt,
  });

  final String id;
  final String conversationId;
  final String senderPersonId;
  final String clientPersonId;
  final String coachPersonId;
  final DateTime createdAt;
  final String? body;
  final String? imagePath;
  final DateTime? readAt;

  bool get isFromClient => senderPersonId == clientPersonId;
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get isRead => readAt != null;

  /// True when this message was sent BY [me].
  bool isMine(String me) => senderPersonId == me;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        senderPersonId: json['sender_person_id'] as String,
        clientPersonId: json['client_person_id'] as String,
        coachPersonId: json['coach_person_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        body: json['body'] as String?,
        imagePath: json['image_path'] as String?,
        readAt: json['read_at'] == null
            ? null
            : DateTime.tryParse(json['read_at'] as String),
      );
}
