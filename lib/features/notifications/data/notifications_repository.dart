import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/notifications/data/models/app_notification.dart';

/// Data access for the current user's in-app notifications (realtime).
class NotificationsRepository {
  const NotificationsRepository._();

  /// Realtime stream of the recipient's notifications, newest first.
  static Stream<List<AppNotification>> stream(String recipientId) {
    return SupabaseClientWrapper.stream('notifications', primaryKey: ['id'])
        .eq('recipient_id', recipientId)
        .order('created_at')
        .map((rows) {
      final list = rows
          .map((r) => AppNotification.fromJson(Map<String, dynamic>.from(r)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  static Future<void> markRead({
    required String tenantId,
    required String id,
  }) async {
    try {
      await SupabaseClientWrapper.db('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not update the notification.', cause: e);
    }
  }

  static Future<void> markAllRead({
    required String tenantId,
    required String recipientId,
  }) async {
    try {
      await SupabaseClientWrapper.db('notifications')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('tenant_id', tenantId)
          .eq('recipient_id', recipientId)
          .isFilter('read_at', null);
    } catch (e) {
      throw AppException('Could not update your notifications.', cause: e);
    }
  }
}
