import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/exercises/data/models/exercise.dart';
import 'package:lynx_app/features/exercises/data/models/exercise_tag.dart';

/// Tenant-scoped data access for the coach exercise library. Every query is
/// scoped to `tenant_id` (belt-and-braces on top of RLS); writes stamp it.
class ExerciseRepository {
  const ExerciseRepository._();

  static const _select =
      'id, owner_id, name, description, video_url, exercise_tags(tags(id, category, label))';

  /// A coach's own exercises, alphabetical.
  static Future<List<Exercise>> listForOwner({
    required String tenantId,
    required String ownerId,
  }) async {
    try {
      final rows = await SupabaseClientWrapper.db('exercises')
          .select(_select)
          .eq('tenant_id', tenantId)
          .eq('owner_id', ownerId)
          .order('name');
      return (rows as List)
          .map((r) => Exercise.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw AppException('Could not load your exercises.', cause: e);
    }
  }

  /// All tags available in the tenant.
  static Future<List<ExerciseTag>> listTags(String tenantId) async {
    try {
      final rows = await SupabaseClientWrapper.db('tags')
          .select('id, category, label')
          .eq('tenant_id', tenantId)
          .order('label');
      return (rows as List)
          .map((r) => ExerciseTag.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw AppException('Could not load tags.', cause: e);
    }
  }

  /// Finds a tag by (category,label) within the tenant or creates it; returns id.
  static Future<String> ensureTag({
    required String tenantId,
    required String ownerId,
    required TagCategory category,
    required String label,
  }) async {
    final cat = tagCategoryToDb(category);
    final trimmed = label.trim();
    try {
      final existing = await SupabaseClientWrapper.db('tags')
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('category', cat)
          .eq('label', trimmed)
          .maybeSingle();
      if (existing != null) return existing['id'] as String;

      final created = await SupabaseClientWrapper.db('tags')
          .insert({
            'tenant_id': tenantId,
            'owner_id': ownerId,
            'category': cat,
            'label': trimmed,
          })
          .select('id')
          .single();
      return created['id'] as String;
    } catch (e) {
      throw AppException('Could not save the tag.', cause: e);
    }
  }

  /// Creates an exercise and its tag links; returns the new id.
  static Future<String> create({
    required String tenantId,
    required String ownerId,
    required String name,
    String? description,
    String? videoUrl,
    List<String> tagIds = const [],
  }) async {
    try {
      final row = await SupabaseClientWrapper.db('exercises')
          .insert({
            'tenant_id': tenantId,
            'owner_id': ownerId,
            'created_by': ownerId,
            'name': name.trim(),
            'description': _nullIfBlank(description),
            'video_url': _nullIfBlank(videoUrl),
          })
          .select('id')
          .single();
      final id = row['id'] as String;
      await _replaceTags(tenantId: tenantId, exerciseId: id, tagIds: tagIds);
      return id;
    } catch (e) {
      throw AppException('Could not create the exercise.', cause: e);
    }
  }

  /// Updates an exercise and replaces its tag links.
  static Future<void> update({
    required String tenantId,
    required String exerciseId,
    required String name,
    String? description,
    String? videoUrl,
    List<String> tagIds = const [],
  }) async {
    try {
      await SupabaseClientWrapper.db('exercises')
          .update({
            'name': name.trim(),
            'description': _nullIfBlank(description),
            'video_url': _nullIfBlank(videoUrl),
          })
          .eq('id', exerciseId)
          .eq('tenant_id', tenantId);
      await _replaceTags(tenantId: tenantId, exerciseId: exerciseId, tagIds: tagIds);
    } catch (e) {
      throw AppException('Could not save the exercise.', cause: e);
    }
  }

  static Future<void> delete({
    required String tenantId,
    required String exerciseId,
  }) async {
    try {
      await SupabaseClientWrapper.db('exercises')
          .delete()
          .eq('id', exerciseId)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not delete the exercise.', cause: e);
    }
  }

  static Future<void> _replaceTags({
    required String tenantId,
    required String exerciseId,
    required List<String> tagIds,
  }) async {
    await SupabaseClientWrapper.db('exercise_tags')
        .delete()
        .eq('exercise_id', exerciseId)
        .eq('tenant_id', tenantId);
    if (tagIds.isEmpty) return;
    final rows = tagIds
        .toSet()
        .map((tagId) => {
              'exercise_id': exerciseId,
              'tag_id': tagId,
              'tenant_id': tenantId,
            })
        .toList();
    await SupabaseClientWrapper.db('exercise_tags').insert(rows);
  }

  static String? _nullIfBlank(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}
