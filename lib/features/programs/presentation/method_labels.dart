import 'package:lynx_app/features/programs/data/models/training_method.dart';
import 'package:lynx_app/l10n/app_localizations.dart';

/// Localized display label for a [TrainingMethod].
String methodLabel(AppLocalizations l, TrainingMethod m) {
  switch (m) {
    case TrainingMethod.none:
      return l.methodNone;
    case TrainingMethod.straight:
      return l.methodStraight;
    case TrainingMethod.superset:
      return l.methodSuperset;
    case TrainingMethod.dropset:
      return l.methodDropset;
    case TrainingMethod.mechanicalDropset:
      return l.methodMechanicalDropset;
    case TrainingMethod.myo:
      return l.methodMyo;
    case TrainingMethod.myoMatch:
      return l.methodMyoMatch;
    case TrainingMethod.emom:
      return l.methodEmom;
    case TrainingMethod.e2mom:
      return l.methodE2mom;
    case TrainingMethod.e3mom:
      return l.methodE3mom;
    case TrainingMethod.restPause:
      return l.methodRestPause;
    case TrainingMethod.ramp:
      return l.methodRamp;
    case TrainingMethod.backOff:
      return l.methodBackOff;
    case TrainingMethod.cluster:
      return l.methodCluster;
    case TrainingMethod.contrast:
      return l.methodContrast;
    case TrainingMethod.tempo:
      return l.methodTempo;
  }
}

/// Localized one-line description of a [TrainingMethod] — mirrors the
/// "Metode treniranja" spec and is shown in the method picker.
String methodDescription(AppLocalizations l, TrainingMethod m) {
  switch (m) {
    case TrainingMethod.none:
      return l.methodDescNone;
    case TrainingMethod.straight:
      return l.methodDescStraight;
    case TrainingMethod.superset:
      return l.methodDescSuperset;
    case TrainingMethod.dropset:
      return l.methodDescDropset;
    case TrainingMethod.mechanicalDropset:
      return l.methodDescMechanicalDropset;
    case TrainingMethod.myo:
      return l.methodDescMyo;
    case TrainingMethod.myoMatch:
      return l.methodDescMyoMatch;
    case TrainingMethod.emom:
      return l.methodDescEmom;
    case TrainingMethod.e2mom:
      return l.methodDescE2mom;
    case TrainingMethod.e3mom:
      return l.methodDescE3mom;
    case TrainingMethod.restPause:
      return l.methodDescRestPause;
    case TrainingMethod.ramp:
      return l.methodDescRamp;
    case TrainingMethod.backOff:
      return l.methodDescBackOff;
    case TrainingMethod.cluster:
      return l.methodDescCluster;
    case TrainingMethod.contrast:
      return l.methodDescContrast;
    case TrainingMethod.tempo:
      return l.methodDescTempo;
  }
}
