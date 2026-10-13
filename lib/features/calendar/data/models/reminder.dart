/// An optional client reminder (measure weight, drink water…). The device
/// schedules the local notification; this row stores the config.
class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.type,
    required this.enabled,
    this.timeOfDay,
    this.days = const [],
  });

  final String id;
  final String title;
  final String type; // 'weight' | 'water' | 'meal' | 'custom'
  final bool enabled;

  /// 'HH:mm' local time, or null.
  final String? timeOfDay;

  /// 0=Sun … 6=Sat; empty = every day.
  final List<int> days;

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        title: (json['title'] as String?) ?? '',
        type: (json['type'] as String?) ?? 'custom',
        enabled: (json['enabled'] as bool?) ?? true,
        timeOfDay: json['time_of_day'] as String?,
        days: ((json['days'] as List?) ?? const [])
            .whereType<int>()
            .toList(),
      );
}
