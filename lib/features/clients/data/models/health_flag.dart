/// A coach-side safety-screening flag on a client. Special-category data.
/// flag_type is an open vocabulary; the common ones are enumerated for the UI.
class HealthFlag {
  const HealthFlag({
    required this.id,
    required this.flagType,
    this.value,
    this.notes,
  });

  final String id;
  final String flagType;
  final String? value;
  final String? notes;

  factory HealthFlag.fromJson(Map<String, dynamic> json) => HealthFlag(
        id: json['id'] as String,
        flagType: json['flag_type'] as String,
        value: json['value'] as String?,
        notes: json['notes'] as String?,
      );
}

/// The standard safety-screening flag types (brief §5.4).
const kHealthFlagTypes = <String>[
  'smoking',
  'blood_pressure',
  'vertigo',
  'migraines',
  'medications',
  'allergies',
  'asthma',
  'osteoporosis',
  'joint_pain',
  'spine_condition',
  'other',
];
