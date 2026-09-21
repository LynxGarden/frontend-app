import 'package:lynx_app/features/exercises/data/models/exercise_tag.dart';
import 'package:lynx_app/l10n/app_localizations.dart';

/// Localized label for a tag category (used by the editor + library filters).
String tagCategoryLabel(AppLocalizations l, TagCategory category) {
  switch (category) {
    case TagCategory.movementPattern:
      return l.catMovement;
    case TagCategory.muscleGroup:
      return l.catMuscle;
    case TagCategory.equipment:
      return l.catEquipment;
    case TagCategory.tempo:
      return l.catTempo;
    case TagCategory.other:
      return l.catOther;
  }
}
