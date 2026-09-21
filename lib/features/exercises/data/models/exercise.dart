import 'package:lynx_app/features/exercises/data/models/exercise_tag.dart';

/// A library exercise: name, optional video (link-based in v1) + description,
/// and faceted tags. Owned by a coach within a tenant.
class Exercise {
  const Exercise({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.videoUrl,
    this.tags = const [],
  });

  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? videoUrl;
  final List<ExerciseTag> tags;

  bool get hasVideo => (videoUrl != null && videoUrl!.trim().isNotEmpty);

  /// Parses a row selected with the embedded tags shape:
  /// `id, owner_id, name, description, video_url,
  ///  exercise_tags(tags(id, category, label))`
  factory Exercise.fromJson(Map<String, dynamic> json) {
    final tagJoins = (json['exercise_tags'] as List?) ?? const [];
    final tags = <ExerciseTag>[];
    for (final join in tagJoins) {
      final tag = (join as Map)['tags'];
      if (tag is Map) {
        tags.add(ExerciseTag.fromJson(Map<String, dynamic>.from(tag)));
      }
    }
    return Exercise(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      videoUrl: json['video_url'] as String?,
      tags: tags,
    );
  }
}
