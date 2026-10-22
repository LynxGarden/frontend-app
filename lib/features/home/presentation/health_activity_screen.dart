import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:lynx_app/core/integrations/health_sync_service.dart';
import 'package:lynx_app/core/integrations/strava_service.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/calendar/data/models/health_log.dart';
import 'package:lynx_app/features/calendar/providers/calendar_providers.dart';
import 'package:lynx_app/features/home/presentation/widgets/home_charts.dart';
import 'package:lynx_app/features/home/providers/home_providers.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/frosted_nav_scaffold.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// "See more" from the Home health section: full steps / heart-rate charts,
/// Apple Health + Strava sync, and the imported activity log.
class HealthActivityScreen extends ConsumerStatefulWidget {
  const HealthActivityScreen({super.key});

  @override
  ConsumerState<HealthActivityScreen> createState() =>
      _HealthActivityScreenState();
}

class _HealthActivityScreenState extends ConsumerState<HealthActivityScreen> {
  bool _syncingHealth = false;
  bool _syncingStrava = false;

  void _invalidateAll() {
    ref.invalidate(stepsWeekProvider);
    ref.invalidate(caloriesTodayProvider);
    ref.invalidate(heartRateTodayProvider);
    ref.invalidate(healthLogsProvider(null));
  }

  Future<void> _syncHealth() async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    setState(() => _syncingHealth = true);
    final count = await HealthSyncService.importAndSave(
        tenantId: user.tenantId, personId: user.personId);
    _invalidateAll();
    if (!mounted) return;
    setState(() => _syncingHealth = false);
    AppToast.show(context,
        title: count > 0 ? l.imported(count) : l.importUnavailable,
        blur: false);
  }

  Future<void> _syncStrava() async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    if (!StravaService.isConfigured) {
      AppToast.show(context, title: l.importUnavailable, blur: false);
      return;
    }
    setState(() => _syncingStrava = true);
    final connected = await StravaService.isConnected;
    if (!connected) {
      await StravaService.connect(); // OAuth completes out-of-band.
      if (mounted) setState(() => _syncingStrava = false);
      return;
    }
    final count = await StravaService.importAndSave(
        tenantId: user.tenantId, personId: user.personId);
    _invalidateAll();
    if (!mounted) return;
    setState(() => _syncingStrava = false);
    AppToast.show(context,
        title: count > 0 ? l.imported(count) : l.importUnavailable,
        blur: false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final stepsAsync = ref.watch(stepsWeekProvider);
    final kcalAsync = ref.watch(caloriesTodayProvider);
    final hrAsync = ref.watch(heartRateTodayProvider);
    final logsAsync = ref.watch(healthLogsProvider(null));

    final steps = stepsAsync.valueOrNull ?? const [];
    final stepsToday = steps.isEmpty ? null : steps.last.value;

    return FrostedNavScaffold(
      title: l.healthSection,
      builder: (context, topInset) => ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, topInset + AppSpacing.sm,
            AppSpacing.lg, MediaQuery.paddingOf(context).bottom + AppSpacing.xl),
        children: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: l.importFromHealth,
                  leading: SvgPicture.asset('assets/images/apple-health.svg',
                      width: 22, height: 22),
                  maxLines: 2,
                  variant: AppButtonVariant.secondary,
                  isLoading: _syncingHealth,
                  onPressed: _syncingHealth ? null : _syncHealth,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: l.importFromStrava,
                  leading: SvgPicture.asset('assets/images/strava.svg',
                      width: 22, height: 22),
                  maxLines: 2,
                  variant: AppButtonVariant.secondary,
                  isLoading: _syncingStrava,
                  onPressed: _syncingStrava ? null : _syncStrava,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: l.stepsToday,
                  value: stepsAsync.isLoading
                      ? null
                      : compactNumber(stepsToday ?? 0),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MiniStat(
                  label: l.caloriesToday,
                  value: kcalAsync.isLoading
                      ? null
                      : compactNumber(kcalAsync.valueOrNull ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ChartCard(
            title: l.stepsLast7Days,
            loading: stepsAsync.isLoading,
            child: StepsBarChart(data: steps),
          ),
          const SizedBox(height: AppSpacing.md),
          _ChartCard(
            title: l.heartRateToday,
            loading: hrAsync.isLoading,
            child: (hrAsync.valueOrNull?.isEmpty ?? true)
                ? Center(
                    child: Text(l.noHeartRateData,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textTertiary)),
                  )
                : HeartRateChart(samples: hrAsync.valueOrNull!),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l.healthLogs,
              style:
                  AppTextStyles.label.copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: AppSpacing.sm),
          logsAsync.when(
            loading: () => const SkeletonLoader(
              child: Column(children: [
                SkeletonBox(
                    width: double.infinity,
                    height: 56,
                    borderRadius: AppRadius.lg),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(
                    width: double.infinity,
                    height: 56,
                    borderRadius: AppRadius.lg),
              ]),
            ),
            error: (_, _) => Text(l.noLogsYet,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiary)),
            data: (logs) => logs.isEmpty
                ? Text(l.noLogsYet,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary))
                : Column(
                    children: [for (final log in logs) _LogTile(log: log)]),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String? value; // null → loading

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          value == null
              ? const SkeletonLoader(child: SkeletonBox(width: 48, height: 22))
              : Text(value!,
                  style: AppTextStyles.heading2
                      .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard(
      {required this.title, required this.child, this.loading = false});

  final String title;
  final Widget child;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 190,
            child: loading
                ? const SkeletonLoader(
                    child: SkeletonBox(
                        width: double.infinity,
                        height: 190,
                        borderRadius: AppRadius.md),
                  )
                : child,
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});
  final HealthLog log;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final when = DateFormat.MMMEd(locale).format(log.loggedAt);
    final value =
        log.value == null ? '' : '${_trim(log.value!)} ${log.unit ?? ''}'.trim();
    return AppCard(
      child: Row(
        children: [
          Icon(_icon(log.type), color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_typeLabel(l, log),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(when,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          if (value.isNotEmpty)
            Text(value,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  static String _trim(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  IconData _icon(HealthLogType t) => switch (t) {
        HealthLogType.sleep => Icons.bedtime_outlined,
        HealthLogType.meal => Icons.restaurant_outlined,
        HealthLogType.activity => Icons.directions_run,
        HealthLogType.weight => Icons.monitor_weight_outlined,
        HealthLogType.water => Icons.water_drop_outlined,
        HealthLogType.other => Icons.circle_outlined,
      };

  String _typeLabel(AppLocalizations l, HealthLog log) {
    final kind = log.data['kind'];
    if (kind == 'steps') return l.stepsLabel;
    if (kind == 'calories') return l.caloriesLabel;
    final name = log.data['name'];
    if (name is String && name.trim().isNotEmpty) return name;
    return switch (log.type) {
      HealthLogType.sleep => l.logSleep,
      HealthLogType.meal => l.logMeal,
      HealthLogType.activity => l.logActivity,
      HealthLogType.weight => l.logWeight,
      HealthLogType.water => l.logWater,
      HealthLogType.other => l.logActivity,
    };
  }
}
