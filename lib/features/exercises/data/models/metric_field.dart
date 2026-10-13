/// One field in an exercise's config-driven logging form. The coach composes a
/// list of these per exercise (`exercises.metric_schema` jsonb) so any exercise
/// can be covered — running = pace/time/incline; bench = reps/weight; etc.
///
/// Logged actuals are stored in `logged_entries.data` jsonb, keyed by [key].
enum MetricFieldType {
  /// Whole number (reps, incline %, steps…).
  number,

  /// Decimal (weight, distance, pace…).
  decimal,

  /// A duration in seconds, entered as mm:ss.
  duration,

  /// Free-form text.
  text,

  /// One of [MetricField.options].
  enumChoice,
}

MetricFieldType metricFieldTypeFromDb(String value) {
  switch (value) {
    case 'number':
      return MetricFieldType.number;
    case 'decimal':
      return MetricFieldType.decimal;
    case 'duration':
      return MetricFieldType.duration;
    case 'text':
      return MetricFieldType.text;
    case 'enum':
      return MetricFieldType.enumChoice;
    default:
      return MetricFieldType.number;
  }
}

String metricFieldTypeToDb(MetricFieldType t) {
  switch (t) {
    case MetricFieldType.number:
      return 'number';
    case MetricFieldType.decimal:
      return 'decimal';
    case MetricFieldType.duration:
      return 'duration';
    case MetricFieldType.text:
      return 'text';
    case MetricFieldType.enumChoice:
      return 'enum';
  }
}

class MetricField {
  const MetricField({
    required this.key,
    required this.label,
    required this.type,
    this.unit,
    this.enumKind,
    this.options = const [],
  });

  /// Stable key used in `logged_entries.data` (e.g. "reps", "weight", "pace").
  final String key;

  /// Human label shown above the input.
  final String label;
  final MetricFieldType type;

  /// Free-text unit shown as a suffix (kg, km/h, %, cm, m…), or null.
  final String? unit;

  /// Special intensity unit semantics: 'rm' | 'rpe' | 'rir' (or null). Drives a
  /// suffix + sensible bounds in the UI.
  final String? enumKind;

  /// Options for [MetricFieldType.enumChoice].
  final List<String> options;

  MetricField copyWith({
    String? key,
    String? label,
    MetricFieldType? type,
    String? unit,
    String? enumKind,
    List<String>? options,
  }) =>
      MetricField(
        key: key ?? this.key,
        label: label ?? this.label,
        type: type ?? this.type,
        unit: unit ?? this.unit,
        enumKind: enumKind ?? this.enumKind,
        options: options ?? this.options,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'type': metricFieldTypeToDb(type),
        if (unit != null && unit!.trim().isNotEmpty) 'unit': unit!.trim(),
        if (enumKind != null) 'enumKind': enumKind,
        if (options.isNotEmpty) 'options': options,
      };

  factory MetricField.fromJson(Map<String, dynamic> json) => MetricField(
        key: json['key'] as String,
        label: (json['label'] as String?) ?? (json['key'] as String),
        type: metricFieldTypeFromDb((json['type'] as String?) ?? 'number'),
        unit: json['unit'] as String?,
        enumKind: json['enumKind'] as String?,
        options: ((json['options'] as List?) ?? const [])
            .whereType<String>()
            .toList(),
      );

  /// Parse an `exercises.metric_schema` jsonb value (a List of maps).
  static List<MetricField> listFromDb(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => MetricField.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  static List<Map<String, dynamic>> listToJson(List<MetricField> fields) =>
      fields.map((f) => f.toJson()).toList();

  /// The default schema offered when a coach hasn't customised one — mirrors the
  /// legacy reps/weight logging so existing muscle memory still works.
  static const List<MetricField> strengthDefault = [
    MetricField(key: 'reps', label: 'Reps', type: MetricFieldType.number),
    MetricField(
        key: 'weight',
        label: 'Weight',
        type: MetricFieldType.decimal,
        unit: 'kg'),
  ];
}
