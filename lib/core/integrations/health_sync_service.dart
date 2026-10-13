import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'package:lynx_app/features/calendar/data/health_repository.dart';
import 'package:lynx_app/features/calendar/data/models/health_log.dart';

/// Imports health data from Apple Health / Google Fit via the `health` plugin,
/// mapping it to [HealthLogInput]s. All calls are guarded so the UI degrades
/// gracefully when the platform has no provider / denies permission.
class HealthSyncService {
  HealthSyncService._();

  static final Health _health = Health();
  static bool _configured = false;

  static const List<HealthDataType> _types = [
    HealthDataType.WEIGHT,
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WORKOUT,
    HealthDataType.WATER,
  ];

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

  /// Reads the last [days] days of health data and returns mapped inputs (not yet
  /// persisted). Returns empty on any failure.
  static Future<List<HealthLogInput>> fetchRecent({int days = 14}) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));
      final points = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: start,
        endTime: now,
      );
      final source = Platform.isIOS
          ? HealthLogSource.appleHealth
          : HealthLogSource.googleFit;
      final inputs = <HealthLogInput>[];
      for (final p in points) {
        final mapped = _map(p, source);
        if (mapped != null) inputs.add(mapped);
      }
      return inputs;
    } catch (e) {
      debugPrint('[health] fetch failed: $e');
      return const [];
    }
  }

  /// Convenience: request access, fetch, and persist. Returns imported count.
  static Future<int> importAndSave({
    required String tenantId,
    required String personId,
    int days = 14,
  }) async {
    final ok = await requestPermission();
    if (!ok) return 0;
    final inputs = await fetchRecent(days: days);
    await HealthRepository.addMany(
        tenantId: tenantId, personId: personId, inputs: inputs);
    return inputs.length;
  }

  static HealthLogInput? _map(HealthDataPoint p, HealthLogSource source) {
    final value = p.value;
    final num? numeric = value is NumericHealthValue ? value.numericValue : null;
    final durationMin = p.dateTo.difference(p.dateFrom).inMinutes;
    switch (p.type) {
      case HealthDataType.WEIGHT:
        return HealthLogInput(
          type: HealthLogType.weight,
          source: source,
          value: numeric,
          unit: 'kg',
          loggedAt: p.dateFrom,
        );
      case HealthDataType.STEPS:
        return HealthLogInput(
          type: HealthLogType.activity,
          source: source,
          value: numeric,
          unit: 'steps',
          data: {'kind': 'steps'},
          loggedAt: p.dateFrom,
        );
      case HealthDataType.SLEEP_ASLEEP:
        return HealthLogInput(
          type: HealthLogType.sleep,
          source: source,
          value: durationMin > 0 ? durationMin : numeric,
          unit: 'min',
          loggedAt: p.dateFrom,
        );
      case HealthDataType.WORKOUT:
        return HealthLogInput(
          type: HealthLogType.activity,
          source: source,
          value: durationMin > 0 ? durationMin : numeric,
          unit: 'min',
          data: {'kind': 'workout'},
          loggedAt: p.dateFrom,
        );
      case HealthDataType.WATER:
        return HealthLogInput(
          type: HealthLogType.water,
          source: source,
          value: numeric,
          unit: 'L',
          loggedAt: p.dateFrom,
        );
      default:
        return null;
    }
  }
}
