import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/calendar/data/models/reminder.dart';

/// Data access for client reminders (weight/water/custom).
class ReminderRepository {
  const ReminderRepository._();

  static const _select = 'id, title, type, time_of_day, days, enabled';

  static Future<List<Reminder>> listForPerson({
    required String tenantId,
    required String personId,
  }) async {
    try {
      final rows = await SupabaseClientWrapper.db('reminders')
          .select(_select)
          .eq('tenant_id', tenantId)
          .eq('person_id', personId)
          .order('created_at');
      return (rows as List)
          .map((r) => Reminder.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw AppException('Could not load your reminders.', cause: e);
    }
  }

  static Future<String> create({
    required String tenantId,
    required String personId,
    required String title,
    required String type,
    String? timeOfDay,
    List<int> days = const [],
  }) async {
    try {
      final row = await SupabaseClientWrapper.db('reminders')
          .insert({
            'tenant_id': tenantId,
            'person_id': personId,
            'title': title.trim(),
            'type': type,
            'time_of_day': timeOfDay,
            'days': days,
          })
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      throw AppException('Could not create the reminder.', cause: e);
    }
  }

  static Future<void> setEnabled({
    required String tenantId,
    required String id,
    required bool enabled,
  }) async {
    try {
      await SupabaseClientWrapper.db('reminders')
          .update({'enabled': enabled})
          .eq('id', id)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not update the reminder.', cause: e);
    }
  }

  static Future<void> delete({
    required String tenantId,
    required String id,
  }) async {
    try {
      await SupabaseClientWrapper.db('reminders')
          .delete()
          .eq('id', id)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not delete the reminder.', cause: e);
    }
  }
}
