/// An in-app notification for the current user (comment / like / feedback / …).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.body,
    this.actorId,
    this.data = const {},
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String? body;
  final String? actorId;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return AppNotification(
      id: json['id'] as String,
      type: (json['type'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      body: json['body'] as String?,
      actorId: json['actor_id'] as String?,
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : const {},
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String).toLocal(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
