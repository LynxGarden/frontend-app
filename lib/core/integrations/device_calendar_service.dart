import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Adds Lynx events (bookings, reminders) to the device's Apple/Google calendar.
/// All calls are guarded and return a success bool; failures never throw.
class DeviceCalendarService {
  DeviceCalendarService._();

  static final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  static bool _tzReady = false;

  static void _ensureTz() {
    if (_tzReady) return;
    try {
      tzdata.initializeTimeZones();
      _tzReady = true;
    } catch (e) {
      debugPrint('[calendar] tz init failed: $e');
    }
  }

  static Future<bool> requestPermission() async {
    try {
      final has = await _plugin.hasPermissions();
      if (has.isSuccess && (has.data ?? false)) return true;
      final req = await _plugin.requestPermissions();
      return req.isSuccess && (req.data ?? false);
    } catch (e) {
      debugPrint('[calendar] permission failed: $e');
      return false;
    }
  }

  /// Adds a timed event to the default writable calendar. Returns true on success.
  static Future<bool> addEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String? notes,
  }) async {
    _ensureTz();
    try {
      if (!await requestPermission()) return false;
      final calsResult = await _plugin.retrieveCalendars();
      final cals = calsResult.data;
      if (cals == null || cals.isEmpty) return false;
      final writable = cals.firstWhere(
        (c) => !(c.isReadOnly ?? true),
        orElse: () => cals.first,
      );

      final event = Event(
        writable.id,
        title: title,
        start: tz.TZDateTime.from(start, tz.local),
        end: tz.TZDateTime.from(end, tz.local),
        description: notes,
      );
      final result = await _plugin.createOrUpdateEvent(event);
      return result?.isSuccess ?? false;
    } catch (e) {
      debugPrint('[calendar] addEvent failed: $e');
      return false;
    }
  }
}
