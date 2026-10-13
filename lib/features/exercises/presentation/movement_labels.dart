import 'package:lynx_app/features/exercises/data/models/movement.dart';
import 'package:lynx_app/l10n/app_localizations.dart';

/// Localized display label for a [Movement].
String movementLabel(AppLocalizations l, Movement m) {
  switch (m) {
    case Movement.strength:
      return l.movementStrength;
    case Movement.hypertrophy:
      return l.movementHypertrophy;
    case Movement.power:
      return l.movementPower;
    case Movement.plyometric:
      return l.movementPlyometric;
    case Movement.cardio:
      return l.movementCardio;
    case Movement.mobility:
      return l.movementMobility;
    case Movement.rehab:
      return l.movementRehab;
    case Movement.warmup:
      return l.movementWarmup;
  }
}
