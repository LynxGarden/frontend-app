/// Movement classification for an exercise. Required (app-enforced ≥1) and
/// multi-valued; drives the coach library filter. Coach-visible only.
///
/// DB: a Postgres enum `movement_type` stored in `exercises.movements` (array).
enum Movement {
  strength,
  hypertrophy,
  power,
  plyometric,
  cardio,
  mobility,
  rehab,
  warmup,
}

Movement movementFromDb(String value) {
  switch (value) {
    case 'strength':
      return Movement.strength;
    case 'hypertrophy':
      return Movement.hypertrophy;
    case 'power':
      return Movement.power;
    case 'plyometric':
      return Movement.plyometric;
    case 'cardio':
      return Movement.cardio;
    case 'mobility':
      return Movement.mobility;
    case 'rehab':
      return Movement.rehab;
    case 'warmup':
      return Movement.warmup;
    default:
      return Movement.strength;
  }
}

String movementToDb(Movement m) {
  switch (m) {
    case Movement.strength:
      return 'strength';
    case Movement.hypertrophy:
      return 'hypertrophy';
    case Movement.power:
      return 'power';
    case Movement.plyometric:
      return 'plyometric';
    case Movement.cardio:
      return 'cardio';
    case Movement.mobility:
      return 'mobility';
    case Movement.rehab:
      return 'rehab';
    case Movement.warmup:
      return 'warmup';
  }
}

/// Parse a Postgres `movement_type[]` value (a List of strings) into [Movement]s.
List<Movement> movementsFromDb(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<String>()
      .map(movementFromDb)
      .toList(growable: false);
}
