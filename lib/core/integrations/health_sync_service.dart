import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'package:lynx_app/features/calendar/data/health_repository.dart';
import 'package:lynx_app/features/calendar/data/models/health_log.dart';

/// A single point of an intraday series (e.g. heart rate over the day).
typedef HealthSample = ({DateTime time, double value});

/// One day's total for a daily series (e.g. steps per day).
typedef DailyTotal = ({DateTime day, num value});

/// Imports health data from Apple Health / Google Fit via the `health` plugin,
/// mapping it to [HealthLogInput]s. All calls are guarded so the UI degrades
/// gracefully when the platform has no provider / denies permission.
///
/// Imported rows are **aggregated per day** (steps, water, sleep, calories) —
/// Apple Health returns steps as hundreds of small interval samples per day and
/// we only ever want the daily total. Workouts are imported individually, but
/// only "major" ones (≥ [minWorkoutMinutes]). Re-importing replaces the window
/// instead of duplicating it.
class HealthSyncService {
  HealthSyncService._();

  static final Health _health = Health();
  static bool _configured = false;

  /// Workouts shorter than this are ignored on import (stand minutes, brief
  /// auto-detected walks and similar noise).
  static const int minWorkoutMinutes = 10;

  static const List<HealthDataType> _types = [
    HealthDataType.WEIGHT,
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WORKOUT,
    HealthDataType.WATER,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
  ];

  static HealthLogSource get _source =>
      Platform.isIOS ? HealthLogSource.appleHealth : HealthLogSource.googleFit;

  static Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Requests read access to the supported types. Returns true if authorized.
  static Future<bool> requestPermission() async {
    try {
      await _ensureConfigured();
      final access = _types.map((_) => HealthDataAccess.READ).toList();
      return await _health.requestAuthorization(_types, permissions: access);
    } catch (e) {
      debugPrint('[health] auth failed: $e');
      return false;
    }
  }

  /// Reads the last [days] days of health data, aggregated to daily rows +
  /// major workouts (not yet persisted). Returns empty on any failure.
  static Future<List<HealthLogInput>> fetchRecent({int days = 14}) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));
      final points = await _health.getHealthDataFromTypes(
        types: const [
          HealthDataType.WEIGHT,
          HealthDataType.STEPS,
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.WORKOUT,
          HealthDataType.WATER,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
        startTime: start,
        endTime: now,
      );
      return _aggregate(points, _source);
    } catch (e) {
      debugPrint('[health] fetch failed: $e');
      return const [];
    }
  }

  /// Convenience: request access, fetch, and persist. Replaces previously
  /// imported rows in the window so re-syncing never duplicates. Returns the
  /// imported row count.
  static Future<int> importAndSave({
    required String tenantId,
    required String personId,
    int days = 14,
  }) async {
    final ok = await requestPermission();
    if (!ok) return 0;
    final inputs = await fetchRecent(days: days);
    if (inputs.isEmpty) return 0;
    await HealthRepository.replaceImported(
      tenantId: tenantId,
      personId: personId,
      source: _source,
      from: DateTime.now().subtract(Duration(days: days)),
      inputs: inputs,
    );
    return inputs.length;
  }

  // --- aggregation ----------------------------------------------------------

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Collapses raw samples into one row per day per metric (+ one row per
  /// major workout). Daily rows are stamped at local noon so they sort stably
  /// inside the day.
  static List<HealthLogInput> _aggregate(
      List<HealthDataPoint> points, HealthLogSource source) {
    final steps = <DateTime, num>{};
    final water = <DateTime, num>{};
    final sleepMin = <DateTime, num>{};
    final kcal = <DateTime, num>{};
    final weightByDay = <DateTime, HealthDataPoint>{};
    final workouts = <HealthLogInput>[];

    for (final p in points) {
      final v = p.value;
      final num? numeric = v is NumericHealthValue ? v.numericValue : null;
      final day = _day(p.dateFrom);
      switch (p.type) {
        case HealthDataType.STEPS:
          steps[day] = (steps[day] ?? 0) + (numeric ?? 0);
        case HealthDataType.WATER:
          water[day] = (water[day] ?? 0) + (numeric ?? 0);
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          kcal[day] = (kcal[day] ?? 0) + (numeric ?? 0);
        case HealthDataType.SLEEP_ASLEEP:
          final min = p.dateTo.difference(p.dateFrom).inMinutes;
          sleepMin[day] = (sleepMin[day] ?? 0) + (min > 0 ? min : (numeric ?? 0));
        case HealthDataType.WEIGHT:
          final prev = weightByDay[day];
          if (prev == null || p.dateFrom.isAfter(prev.dateFrom)) {
            weightByDay[day] = p;
          }
        case HealthDataType.WORKOUT:
          final mins = p.dateTo.difference(p.dateFrom).inMinutes;
          if (mins < minWorkoutMinutes) break;
          String? activity;
          if (v is WorkoutHealthValue) {
            activity = v.workoutActivityType.name;
          }
          workouts.add(HealthLogInput(
            type: HealthLogType.activity,
            source: source,
            value: mins,
            unit: 'min',
            data: {
              'kind': 'workout',
              'name': ?activity,
            },
            loggedAt: p.dateFrom,
          ));
        default:
          break;
      }
    }

    DateTime noon(DateTime day) => day.add(const Duration(hours: 12));
    final inputs = <HealthLogInput>[...workouts];
    steps.forEach((day, total) {
      if (total <= 0) return;
      inputs.add(HealthLogInput(
        type: HealthLogType.activity,
        source: source,
        value: total.round(),
        unit: 'steps',
        data: const {'kind': 'steps'},
        loggedAt: noon(day),
      ));
    });
    kcal.forEach((day, total) {
      if (total <= 0) return;
      inputs.add(HealthLogInput(
        type: HealthLogType.activity,
        source: source,
        value: total.round(),
        unit: 'kcal',
        data: const {'kind': 'calories'},
        loggedAt: noon(day),
      ));
    });
    water.forEach((day, total) {
      if (total <= 0) return;
      inputs.add(HealthLogInput(
        type: HealthLogType.water,
        source: source,
        value: total,
        unit: 'L',
        loggedAt: noon(day),
      ));
    });
    sleepMin.forEach((day, total) {
      if (total <= 0) return;
      inputs.add(HealthLogInput(
        type: HealthLogType.sleep,
        source: source,
        value: total,
        unit: 'min',
        loggedAt: noon(day),
      ));
    });
    weightByDay.forEach((day, p) {
      final v = p.value;
      final num? numeric = v is NumericHealthValue ? v.numericValue : null;
      if (numeric == null) return;
      inputs.add(HealthLogInput(
        type: HealthLogType.weight,
        source: source,
        value: numeric,
        unit: 'kg',
        loggedAt: p.dateFrom,
      ));
    });
    return inputs;
  }

  // --- live dashboard reads (not persisted) ---------------------------------

  /// Total steps per day for the last [days] days (today included, oldest
  /// first). Missing days are 0. Empty on failure / no permission.
  static Future<List<DailyTotal>> stepsByDay({int days = 7}) async {
    try {
      await _ensureConfigured();
      final today = _day(DateTime.now());
      final out = <DailyTotal>[];
      for (var i = days - 1; i >= 0; i--) {
        final day = today.subtract(Duration(days: i));
        final end = i == 0 ? DateTime.now() : day.add(const Duration(days: 1));
        final total = await _health.getTotalStepsInInterval(day, end);
        out.add((day: day, value: total ?? 0));
      }
      return out;
    } catch (e) {
      debugPrint('[health] steps fetch failed: $e');
      return const [];
    }
  }

  /// Active energy burned today, in kcal. Null on failure.
  static Future<num?> activeCaloriesToday() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final points = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: _day(now),
        endTime: now,
      );
      num total = 0;
      for (final p in points) {
        final v = p.value;
        if (v is NumericHealthValue) total += v.numericValue;
      }
      return total.round();
    } catch (e) {
      debugPrint('[health] calories fetch failed: $e');
      return null;
    }
  }

  /// Heart-rate samples for the given window (default: today), averaged into
  /// [bucketMinutes] buckets so the chart stays smooth. Oldest first.
  static Future<List<HealthSample>> heartRate({
    DateTime? start,
    DateTime? end,
    int bucketMinutes = 15,
  }) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final from = start ?? _day(now);
      final to = end ?? now;
      final points = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: from,
        endTime: to,
      );
      if (points.isEmpty) return const [];
      final bucket = Duration(minutes: bucketMinutes);
      final sums = <int, double>{};
      final counts = <int, int>{};
      for (final p in points) {
        final v = p.value;
        if (v is! NumericHealthValue) continue;
        final idx =
            p.dateFrom.difference(from).inMinutes ~/ bucket.inMinutes;
        sums[idx] = (sums[idx] ?? 0) + v.numericValue.toDouble();
        counts[idx] = (counts[idx] ?? 0) + 1;
      }
      final keys = sums.keys.toList()..sort();
      return [
        for (final k in keys)
          (
            time: from.add(bucket * k),
            value: sums[k]! / counts[k]!,
          ),
      ];
    } catch (e) {
      debugPrint('[health] heart rate fetch failed: $e');
      return const [];
    }
  }
}
