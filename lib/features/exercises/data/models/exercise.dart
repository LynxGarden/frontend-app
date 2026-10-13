import 'package:lynx_app/features/exercises/data/models/exercise_tag.dart';
import 'package:lynx_app/features/exercises/data/models/metric_field.dart';
import 'package:lynx_app/features/exercises/data/models/movement.dart';

/// A library exercise: name, optional video (link-based in v1) + description,
/// faceted tags, a required movement classification and a config-driven logging
/// schema. Owned by a coach within a tenant.
class Exercise {
  const Exercise({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.videoUrl,
    this.videoStoragePath,
    this.thumbnailStoragePath,
    this.tags = const [],
    this.movements = const [],
    this.metricSchema = const [],
  });

  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? videoUrl;
  /// Path in the private `exercise-videos` bucket (hosted video), or null.
  final String? videoStoragePath;
  /// Path in the public `exercise-thumbnails` bucket (cover image), or null.
  final String? thumbnailStoragePath;
  final List<ExerciseTag> tags;

  /// Required (≥1) movement classification. Coach-visible; drives the filter.
  final List<Movement> movements;

  /// Config-driven logging fields. Empty → runner falls back to reps/weight.
  final List<MetricField> metricSchema;

  bool get hasHostedVideo =>
      videoStoragePath != null && videoStoragePath!.trim().isNotEmpty;
  bool get hasLinkVideo => videoUrl != null && videoUrl!.trim().isNotEmpty;
  bool get hasVideo => hasHostedVideo || hasLinkVideo;

  bool get hasThumbnail =>
      thumbnailStoragePath != null && thumbnailStoragePath!.trim().isNotEmpty;

  /// Parses a row selected with the embedded tags shape:
  /// `id, owner_id, name, description, video_url, video_storage_path,
  ///  thumbnail_storage_path, movements, metric_schema,
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
      videoStoragePath: json['video_storage_path'] as String?,
      thumbnailStoragePath: json['thumbnail_storage_path'] as String?,
      tags: tags,
      movements: movementsFromDb(json['movements']),
      metricSchema: MetricField.listFromDb(json['metric_schema']),
    );
  }
}
