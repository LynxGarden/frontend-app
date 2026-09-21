/// A faceted tag on an exercise (movement pattern / muscle group / equipment /
/// tempo / other). Drives search and the later "swap exercise" feature.
enum TagCategory { movementPattern, muscleGroup, equipment, tempo, other }

TagCategory tagCategoryFromDb(String value) {
  switch (value) {
    case 'movement_pattern':
      return TagCategory.movementPattern;
    case 'muscle_group':
      return TagCategory.muscleGroup;
    case 'equipment':
      return TagCategory.equipment;
    case 'tempo':
      return TagCategory.tempo;
    default:
      return TagCategory.other;
  }
}

String tagCategoryToDb(TagCategory category) {
  switch (category) {
    case TagCategory.movementPattern:
      return 'movement_pattern';
    case TagCategory.muscleGroup:
      return 'muscle_group';
    case TagCategory.equipment:
      return 'equipment';
    case TagCategory.tempo:
      return 'tempo';
    case TagCategory.other:
      return 'other';
  }
}

class ExerciseTag {
  const ExerciseTag({
    required this.id,
    required this.category,
    required this.label,
  });

  final String id;
  final TagCategory category;
  final String label;

  factory ExerciseTag.fromJson(Map<String, dynamic> json) {
    return ExerciseTag(
      id: json['id'] as String,
      category: tagCategoryFromDb(json['category'] as String),
      label: json['label'] as String,
    );
  }

  @override
  bool operator ==(Object other) => other is ExerciseTag && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
