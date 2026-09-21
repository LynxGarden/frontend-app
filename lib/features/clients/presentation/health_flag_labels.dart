import 'package:lynx_app/l10n/app_localizations.dart';

/// Localized label for a health-flag type (open vocabulary; unknown → prettified).
String healthFlagLabel(AppLocalizations l, String type) {
  switch (type) {
    case 'smoking':
      return l.hfSmoking;
    case 'blood_pressure':
      return l.hfBloodPressure;
    case 'vertigo':
      return l.hfVertigo;
    case 'migraines':
      return l.hfMigraines;
    case 'medications':
      return l.hfMedications;
    case 'allergies':
      return l.hfAllergies;
    case 'asthma':
      return l.hfAsthma;
    case 'osteoporosis':
      return l.hfOsteoporosis;
    case 'joint_pain':
      return l.hfJointPain;
    case 'spine_condition':
      return l.hfSpineCondition;
    case 'other':
      return l.hfOther;
    default:
      return type.replaceAll('_', ' ');
  }
}
