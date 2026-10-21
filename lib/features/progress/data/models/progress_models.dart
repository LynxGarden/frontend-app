/// An exercise the client can view progress for (from their assignments).
class TrackedExercise {
  const TrackedExercise({required this.exerciseId, required this.name});

  final String exerciseId;
  final String name;
}

/// Top-of-screen activity summary.
class ProgressSummary {
  const ProgressSummary({
    required this.visitsThisWeek,
    required this.weekStreak,
    required this.hasAnyData,
  });

  /// Distinct training days in the current (Mon–Sun) week.
  final int visitsThisWeek;

  /// Consecutive weeks (ending this week or last week) with ≥1 training day.
  final int weekStreak;

  final bool hasAnyData;

  static const empty =
      ProgressSummary(visitsThisWeek: 0, weekStreak: 0, hasAnyData: false);
}

/// One week's aggregates for a single exercise.
class WeeklyPoint {
  const WeeklyPoint({
    required this.weekStart,
    required this.volume,
    required this.topWeight,
  });

  final DateTime weekStart; // Monday of the week
  final double volume; // Σ reps × weight across the week
  final double topWeight; // heaviest logged weight that week
}

/// Aggregated progress for one exercise.
class ExerciseProgress {
  const ExerciseProgress({
    required this.bestWeight,
    required this.bestReps,
    required this.bestSeries,
    required this.bestVolume,
    required this.weekly,
  });

  final double? bestWeight;
  final int? bestReps;

  /// Most sets (series) logged for this exercise in a single session.
  final int? bestSeries;

  /// Best single-session volume — Σ (reps × weight) across that session's sets
  /// (i.e. weight × series × reps for uniform sets).
  final double? bestVolume;
  final List<WeeklyPoint> weekly; // chronological

  bool get isEmpty => weekly.isEmpty && bestWeight == null && bestReps == null;

  static const empty = ExerciseProgress(
    bestWeight: null,
    bestReps: null,
    bestSeries: null,
    bestVolume: null,
    weekly: [],
  );
}
