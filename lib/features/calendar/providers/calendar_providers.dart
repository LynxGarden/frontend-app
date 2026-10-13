import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/calendar/data/booking_repository.dart';
import 'package:lynx_app/features/calendar/data/health_repository.dart';
import 'package:lynx_app/features/calendar/data/models/booking.dart';
import 'package:lynx_app/features/calendar/data/models/health_log.dart';
import 'package:lynx_app/features/calendar/data/models/reminder.dart';
import 'package:lynx_app/features/calendar/data/reminder_repository.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// Realtime stream of the tenant's bookings (for live slot capacity).
final tenantBookingsProvider = StreamProvider<List<Booking>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* BookingRepository.tenantBookingsStream(user.tenantId);
});

/// This client's active (booked) bookings, most recent first.
final myBookingsProvider = Provider<List<Booking>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final all = ref.watch(tenantBookingsProvider).valueOrNull ?? const [];
  if (user == null) return const [];
  final mine = all
      .where((b) => b.personId == user.personId && b.isBooked)
      .toList()
    ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
  return mine;
});

/// The client's health logs (optionally filtered by type). Invalidate after add.
final healthLogsProvider =
    FutureProvider.family<List<HealthLog>, HealthLogType?>((ref, type) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return HealthRepository.listForPerson(
    tenantId: user.tenantId,
    personId: user.personId,
    type: type,
  );
});

/// The client's reminders. Invalidate after mutate.
final remindersProvider = FutureProvider<List<Reminder>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return ReminderRepository.listForPerson(
    tenantId: user.tenantId,
    personId: user.personId,
  );
});
