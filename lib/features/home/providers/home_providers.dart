import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/integrations/health_sync_service.dart';

/// Daily step totals for the last 7 days (oldest first), read live from
/// Apple Health / Google Fit. Empty when unavailable / not authorized.
final stepsWeekProvider = FutureProvider<List<DailyTotal>>(
    (ref) => HealthSyncService.stepsByDay(days: 7));

/// Active energy burned today (kcal). Null when unavailable.
final caloriesTodayProvider =
    FutureProvider<num?>((ref) => HealthSyncService.activeCaloriesToday());

/// Today's heart-rate curve (15-min bucket averages, oldest first).
final heartRateTodayProvider = FutureProvider<List<HealthSample>>(
    (ref) => HealthSyncService.heartRate());
