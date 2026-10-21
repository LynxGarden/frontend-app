import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/calendar/data/models/health_log.dart';

/// A health datum to insert (in-app or imported).
class HealthLogInput {
  const HealthLogInput({
    required this.type,
    required this.source,
    this.value,
    this.unit,
    this.data = const {},
    this.notes,
    this.loggedAt,
  });

  final HealthLogType type;
  final HealthLogSource source;
  final num? value;
  final String? unit;
  final Map<String, dynamic> data;
  final String? notes;
  final DateTime? loggedAt;

  Map<String, dynamic> toColumns(String tenantId, String personId) => {
        'tenant_id': tenantId,
        'person_id': personId,
        'type': healthLogTypeToDb(type),
        'source': healthLogSourceToDb(source),
        'value': value,
        'unit': unit,
        'data': data,
        'notes': notes,
        if (loggedAt != null) 'logged_at': loggedAt!.toUtc().toIso8601String(),
      };
}

/// Data access for client health logs (sleep/meal/activity/weight/water).
class HealthRepository {
  const HealthRepository._();

  static const _select =
      'id, type, source, value, unit, data, notes, logged_at';

  static Future<List<HealthLog>> listForPerson({
    required String tenantId,
    required String personId,
    HealthLogType? type,
    int limit = 100,
  }) async {
    try {
      var q = SupabaseClientWrapper.db('health_logs')
          .select(_select)
          .eq('tenant_id', tenantId)
          .eq('person_id', personId);
      if (type != null) q = q.eq('type', healthLogTypeToDb(type));
      final rows = await q.order('logged_at', ascending: false).limit(limit);
      return (rows as List)
          .map((r) => HealthLog.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw AppException('Could not load your health logs.', cause: e);
    }
  }

  static Future<void> add({
    required String tenantId,
    required String personId,
    required HealthLogInput input,
  }) async {
    try {
      await SupabaseClientWrapper.db('health_logs')
          .insert(input.toColumns(tenantId, personId));
    } catch (e) {
      throw AppException('Could not save the log.', cause: e);
    }
  }

  /// Bulk insert for native imports. Silently no-ops on an empty list.
  static Future<void> addMany({
    required String tenantId,
    required String personId,
    required List<HealthLogInput> inputs,
  }) async {
    if (inputs.isEmpty) return;
    try {
      await SupabaseClientWrapper.db('health_logs')
          .insert(inputs.map((i) => i.toColumns(tenantId, personId)).toList());
    } catch (e) {
      throw AppException('Could not import your health data.', cause: e);
    }
  }

  /// Replaces every previously imported row from [source] since [from] with
  /// [inputs], so a re-sync is idempotent instead of duplicating the window.
  /// Manual logs (source = manual) are never touched.
  static Future<void> replaceImported({
    required String tenantId,
    required String personId,
    required HealthLogSource source,
    required DateTime from,
    required List<HealthLogInput> inputs,
  }) async {
    try {
      await SupabaseClientWrapper.db('health_logs')
          .delete()
          .eq('tenant_id', tenantId)
          .eq('person_id', personId)
          .eq('source', healthLogSourceToDb(source))
          .gte('logged_at', from.toUtc().toIso8601String());
      if (inputs.isNotEmpty) {
        await SupabaseClientWrapper.db('health_logs')
            .insert(inputs.map((i) => i.toColumns(tenantId, personId)).toList());
      }
    } catch (e) {
      throw AppException('Could not import your health data.', cause: e);
    }
  }

  static Future<void> delete({
    required String tenantId,
    required String id,
  }) async {
    try {
      await SupabaseClientWrapper.db('health_logs')
          .delete()
          .eq('id', id)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not delete the log.', cause: e);
    }
  }
}
