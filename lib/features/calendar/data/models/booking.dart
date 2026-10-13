/// A client's booking for a 1-hour training slot.
class Booking {
  const Booking({
    required this.id,
    required this.personId,
    required this.slotStart,
    required this.slotEnd,
    required this.status,
    this.coachId,
    this.assignmentSessionId,
  });

  final String id;
  final String personId;
  final String? coachId;
  final String? assignmentSessionId;
  final DateTime slotStart;
  final DateTime slotEnd;
  final String status; // 'booked' | 'cancelled'

  bool get isBooked => status == 'booked';

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        personId: json['person_id'] as String,
        coachId: json['coach_id'] as String?,
        assignmentSessionId: json['assignment_session_id'] as String?,
        slotStart: DateTime.parse(json['slot_start'] as String).toLocal(),
        slotEnd: DateTime.parse(json['slot_end'] as String).toLocal(),
        status: (json['status'] as String?) ?? 'booked',
      );
}

/// A computed bookable hour slot for a day, with live capacity and whether the
/// current user holds it. Not a DB row — derived from [Booking]s in the UI.
class TimeSlot {
  const TimeSlot({
    required this.start,
    required this.bookedCount,
    required this.capacity,
    this.myBooking,
  });

  final DateTime start;
  final int bookedCount;
  final int capacity;
  final Booking? myBooking;

  DateTime get end => start.add(const Duration(hours: 1));
  int get remaining => (capacity - bookedCount).clamp(0, capacity);
  bool get isFull => remaining <= 0;
  bool get isMine => myBooking != null;
  bool get isPast => start.isBefore(DateTime.now());

  /// Cancellation allowed up to 2h before start.
  bool get canCancel =>
      isMine && DateTime.now().isBefore(start.subtract(const Duration(hours: 2)));
}
