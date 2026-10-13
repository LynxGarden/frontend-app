import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around `flutter_local_notifications` for client reminders
/// (measure weight, drink water…). Everything is best-effort and guarded so a
/// missing platform capability never crashes the app.
class LocalNotificationsService {
  LocalNotificationsService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _channelId = 'lynx_reminders';
  static const _channelName = 'Reminders';

  static Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('[reminders] timezone init failed: $e');
    }
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _ready = true;
  }

  /// Requests notification permission (iOS + Android 13+). Returns true if
  /// granted (best-effort; treats unknown as granted).
  static Future<bool> requestPermission() async {
    await _ensureReady();
    try {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
            alert: true, badge: true, sound: true);
        return granted ?? true;
      }
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? true;
      }
    } catch (e) {
      debugPrint('[reminders] permission request failed: $e');
    }
    return true;
  }

  /// Schedules a daily repeating reminder at [hour]:[minute] for [days] of week
  /// (1=Mon … 7=Sun; empty = every day). Uses a stable base id so re-scheduling
  /// replaces prior instances for that reminder.
  static Future<void> scheduleDaily({
    required int baseId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    List<int> days = const [],
  }) async {
    await _ensureReady();
    try {
      final targetDays = days.isEmpty ? List<int>.generate(7, (i) => i + 1) : days;
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );
      for (final weekday in targetDays) {
        await _plugin.zonedSchedule(
          baseId * 10 + weekday,
          title,
          body,
          _nextInstanceOf(weekday, hour, minute),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (e) {
      debugPrint('[reminders] schedule failed: $e');
    }
  }

  /// Cancels every notification instance for a reminder's [baseId].
  static Future<void> cancelReminder(int baseId) async {
    await _ensureReady();
    for (var weekday = 1; weekday <= 7; weekday++) {
      try {
        await _plugin.cancel(baseId * 10 + weekday);
      } catch (_) {/* best-effort */}
    }
  }

  static tz.TZDateTime _nextInstanceOf(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
