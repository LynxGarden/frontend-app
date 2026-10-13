/// A structured training method for a session exercise (or a group of them).
/// Replaces the old free-text set-type note. Drives both the builder prefills
/// and the client runner rendering.
///
/// DB: `session_exercises.method` / `assignment_exercises.method` (text, checked).
enum TrainingMethod {
  straight,
  superset,
  dropset,
  mechanicalDropset,
  myo,
  myoMatch,
  emom,
  e2mom,
  e3mom,
  restPause,
  ramp,
  backOff,
  cluster,
  contrast,
  tempo,
}

TrainingMethod methodFromDb(String value) {
  switch (value) {
    case 'superset':
      return TrainingMethod.superset;
    case 'dropset':
      return TrainingMethod.dropset;
    case 'mechanical_dropset':
      return TrainingMethod.mechanicalDropset;
    case 'myo':
      return TrainingMethod.myo;
    case 'myo_match':
      return TrainingMethod.myoMatch;
    case 'emom':
      return TrainingMethod.emom;
    case 'e2mom':
      return TrainingMethod.e2mom;
    case 'e3mom':
      return TrainingMethod.e3mom;
    case 'rest_pause':
      return TrainingMethod.restPause;
    case 'ramp':
      return TrainingMethod.ramp;
    case 'back_off':
      return TrainingMethod.backOff;
    case 'cluster':
      return TrainingMethod.cluster;
    case 'contrast':
      return TrainingMethod.contrast;
    case 'tempo':
      return TrainingMethod.tempo;
    case 'straight':
    default:
      return TrainingMethod.straight;
  }
}

String methodToDb(TrainingMethod m) {
  switch (m) {
    case TrainingMethod.straight:
      return 'straight';
    case TrainingMethod.superset:
      return 'superset';
    case TrainingMethod.dropset:
      return 'dropset';
    case TrainingMethod.mechanicalDropset:
      return 'mechanical_dropset';
    case TrainingMethod.myo:
      return 'myo';
    case TrainingMethod.myoMatch:
      return 'myo_match';
    case TrainingMethod.emom:
      return 'emom';
    case TrainingMethod.e2mom:
      return 'e2mom';
    case TrainingMethod.e3mom:
      return 'e3mom';
    case TrainingMethod.restPause:
      return 'rest_pause';
    case TrainingMethod.ramp:
      return 'ramp';
    case TrainingMethod.backOff:
      return 'back_off';
    case TrainingMethod.cluster:
      return 'cluster';
    case TrainingMethod.contrast:
      return 'contrast';
    case TrainingMethod.tempo:
      return 'tempo';
  }
}

/// Methods that are composed from 2+ exercises performed as one block (the coach
/// must pick multiple exercises into a method group).
bool methodRequiresGroup(TrainingMethod m) {
  switch (m) {
    case TrainingMethod.superset:
    case TrainingMethod.mechanicalDropset:
    case TrainingMethod.contrast:
    case TrainingMethod.ramp:
      return true;
    default:
      return false;
  }
}

/// Methods built on a fixed time interval (minute-based). The interval seconds
/// live in `method_config.interval_seconds`.
bool methodIsInterval(TrainingMethod m) =>
    m == TrainingMethod.emom ||
    m == TrainingMethod.e2mom ||
    m == TrainingMethod.e3mom;

/// Sensible prefills applied when a coach first picks a method (editable after).
/// Encodes the Lynx "Metode treniranja" table: series counts, rep scheme hints,
/// fixed pauses and any interval config.
class MethodDefaults {
  const MethodDefaults({
    this.sets,
    this.reps,
    this.restSeconds,
    this.config = const {},
  });

  final int? sets;
  final String? reps;
  final int? restSeconds;
  final Map<String, dynamic> config;
}

MethodDefaults methodDefaults(TrainingMethod m) {
  switch (m) {
    case TrainingMethod.straight:
    case TrainingMethod.superset:
      return const MethodDefaults();
    case TrainingMethod.dropset:
      // 3–4 sets, same exercise, decreasing load, no rest.
      return const MethodDefaults(
          sets: 3, reps: '10RM → AMRAP → AMRAP', restSeconds: 0);
    case TrainingMethod.mechanicalDropset:
      // 3–4 different exercises, hardest → easiest, no rest.
      return const MethodDefaults(sets: 1, restSeconds: 0);
    case TrainingMethod.myo:
      // 1 activation + 3–4 mini-sets; 15s between.
      return const MethodDefaults(
          sets: 5, reps: '10-15, then 3-5', restSeconds: 15);
    case TrainingMethod.myoMatch:
      // 3 sets, matched reps; 120s between, 10s within.
      return MethodDefaults(
          sets: 3,
          reps: '12RM matched',
          restSeconds: 120,
          config: {'within_set_rest_seconds': 10});
    case TrainingMethod.emom:
      return const MethodDefaults(config: {'interval_seconds': 60});
    case TrainingMethod.e2mom:
      return const MethodDefaults(config: {'interval_seconds': 120});
    case TrainingMethod.e3mom:
      return const MethodDefaults(config: {'interval_seconds': 180});
    case TrainingMethod.restPause:
      // 1 heavy + 4 AMRAP; 2–3min then 20s.
      return const MethodDefaults(
          sets: 5, reps: '3-10RM, then AMRAP', restSeconds: 20);
    case TrainingMethod.ramp:
      // 2 exercises, intensity ramp RPE 4 → 6-7 → 8+.
      return const MethodDefaults(sets: 3, reps: 'RPE 4 → 6-7 → 8+');
    case TrainingMethod.backOff:
      // 1 heavy (3-5) + 3-4 back-off (5-8) at 80-85%; 2-3min.
      return const MethodDefaults(
          sets: 4, reps: '3-5, then 5-8', restSeconds: 150);
    case TrainingMethod.cluster:
      // 1 set broken into subsets; 20s between subsets.
      return MethodDefaults(
          sets: 1, reps: '3 + 2', config: {'within_set_rest_seconds': 20});
    case TrainingMethod.contrast:
      // Strength + ballistic superset, no rest.
      return const MethodDefaults(sets: 3, restSeconds: 0);
    case TrainingMethod.tempo:
      return const MethodDefaults(sets: 3);
  }
}
