/// The kind of health datum logged.
enum HealthLogType { sleep, meal, activity, weight, water, other }

HealthLogType healthLogTypeFromDb(String v) {
  switch (v) {
    case 'sleep':
      return HealthLogType.sleep;
    case 'meal':
      return HealthLogType.meal;
    case 'activity':
      return HealthLogType.activity;
    case 'weight':
      return HealthLogType.weight;
    case 'water':
      return HealthLogType.water;
    default:
      return HealthLogType.other;
  }
}

String healthLogTypeToDb(HealthLogType t) => t.name;

/// Where a log came from.
enum HealthLogSource { manual, appleHealth, googleFit, strava }

HealthLogSource healthLogSourceFromDb(String v) {
  switch (v) {
    case 'apple_health':
      return HealthLogSource.appleHealth;
    case 'google_fit':
      return HealthLogSource.googleFit;
    case 'strava':
      return HealthLogSource.strava;
    default:
      return HealthLogSource.manual;
  }
}

String healthLogSourceToDb(HealthLogSource s) {
  switch (s) {
    case HealthLogSource.manual:
      return 'manual';
    case HealthLogSource.appleHealth:
      return 'apple_health';
    case HealthLogSource.googleFit:
      return 'google_fit';
    case HealthLogSource.strava:
      return 'strava';
  }
}

/// A client's health datum (sleep/meal/activity/weight/water), logged in-app or
/// imported from a native source. Special-category data (GDPR).
class HealthLog {
  const HealthLog({
    required this.id,
    required this.type,
    required this.source,
    required this.loggedAt,
    this.value,
    this.unit,
    this.data = const {},
    this.notes,
  });

  final String id;
  final HealthLogType type;
  final HealthLogSource source;
  final DateTime loggedAt;
  final num? value;
  final String? unit;
  final Map<String, dynamic> data;
  final String? notes;

  factory HealthLog.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return HealthLog(
      id: json['id'] as String,
      type: healthLogTypeFromDb(json['type'] as String),
      source: healthLogSourceFromDb((json['source'] as String?) ?? 'manual'),
      loggedAt: DateTime.parse(json['logged_at'] as String).toLocal(),
      value: json['value'] as num?,
      unit: json['unit'] as String?,
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : const {},
      notes: json['notes'] as String?,
    );
  }
}
