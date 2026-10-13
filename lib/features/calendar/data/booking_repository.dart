import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/calendar/data/models/booking.dart';

/// Data access for training slot bookings. Reads are realtime (tenant-wide, for
/// live capacity); writes go through the SECURITY DEFINER RPCs.
class BookingRepository {
  const BookingRepository._();

  /// Opening hours: 1-hour slots starting 06:00 … 21:00 (last ends 22:00).
  static const int firstHour = 6;
  static const int lastHour = 21;
  static const int slotCapacity = 10;

  /// A realtime stream of the tenant's bookings (RLS-scoped). The UI filters to
  /// the current week + `booked` status and aggregates per-slot counts.
  static Stream<List<Booking>> tenantBookingsStream(String tenantId) {
    return SupabaseClientWrapper.stream('bookings', primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .map((rows) => rows
            .map((r) => Booking.fromJson(Map<String, dynamic>.from(r)))
            .toList());
  }

  /// Books the current client into [slotStart] (top of the hour). Returns the
  /// new booking id. Throws [AppException] with the backend's friendly reason.
  static Future<String> book(DateTime slotStart) async {
    try {
      return await SupabaseClientWrapper.rpc<String>(
        'book_training',
        params: {'p_slot_start': slotStart.toUtc().toIso8601String()},
      );
    } catch (e) {
      throw AppException(_bookingMessage(e), cause: e);
    }
  }

  /// Cancels a booking (allowed up to 2h before start).
  static Future<void> cancel(String bookingId) async {
    try {
      await SupabaseClientWrapper.rpc<void>(
        'cancel_booking',
        params: {'p_booking': bookingId},
      );
    } catch (e) {
      throw AppException(_bookingMessage(e), cause: e);
    }
  }

  /// Maps known Postgres RAISE messages to friendly copy; falls back generic.
  static String _bookingMessage(Object e) {
    final s = e.toString();
    if (s.contains('slot is full')) return 'That slot is full.';
    if (s.contains('already have a booking')) {
      return 'You already have a booking that day.';
    }
    if (s.contains('current week')) return 'You can only book the current week.';
    if (s.contains('opening hours')) return 'That time is outside opening hours.';
    if (s.contains('in the past')) return 'That slot has already started.';
    if (s.contains('too late to cancel')) {
      return 'Too late to cancel — within 2 hours of the start.';
    }
    return 'Could not update your booking. Please try again.';
  }
}
