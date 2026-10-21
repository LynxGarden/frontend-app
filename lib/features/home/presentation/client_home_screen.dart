import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/home/presentation/health_activity_screen.dart';
import 'package:lynx_app/features/home/presentation/widgets/home_charts.dart';
import 'package:lynx_app/features/home/providers/home_providers.dart';
import 'package:lynx_app/features/notifications/presentation/notification_bell.dart';
import 'package:lynx_app/features/progress/providers/progress_provider.dart';
import 'package:lynx_app/features/training/data/models/active_assignment.dart';
import 'package:lynx_app/features/training/presentation/session_runner_screen.dart';
import 'package:lynx_app/features/training/providers/training_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/collapsing_header.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// The client's Home tab: the next session to train (straight into the runner),
/// the full session menu, activity KPIs, and Apple Health / Strava highlights
/// (steps + heart-rate graphs) with a "See more" detail screen.
class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// The session to train next: the first never-completed one, else the one
  /// trained longest ago (so a finished program keeps cycling).
  TrainingAssignmentSession? _nextSession(ActiveAssignment a) {
    if (a.sessions.isEmpty) return null;
    for (final s in a.sessions) {
      if (!s.isCompleted) return s;
    }
    var oldest = a.sessions.first;
    for (final s in a.sessions) {
      if (s.lastCompletedAt!.isBefore(oldest.lastCompletedAt!)) oldest = s;
    }
    return oldest;
  }

  void _openRunner(ActiveAssignment a, TrainingAssignmentSession s) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SessionRunnerScreen(assignmentId: a.id, sessionId: s.id),
      ),
    );
  }

  void _openHealthDetail() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HealthActivityScreen()),
    );
  }

  Future<void> _refresh() {
    ref.invalidate(stepsWeekProvider);
    ref.invalidate(caloriesTodayProvider);
    ref.invalidate(heartRateTodayProvider);
    ref.invalidate(progressSummaryProvider);
    return ref.refresh(activeAssignmentProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final assignmentAsync = ref.watch(activeAssignmentProvider);
    final summaryAsync = ref.watch(progressSummaryProvider);
    final stepsAsync = ref.watch(stepsWeekProvider);
    final kcalAsync = ref.watch(caloriesTodayProvider);
    final hrAsync = ref.watch(heartRateTodayProvider);

    final steps = stepsAsync.valueOrNull ?? const [];
    final stepsToday = steps.isEmpty ? null : steps.last.value;
    final hasHealthData = steps.any((d) => d.value > 0) ||
        (kcalAsync.valueOrNull ?? 0) > 0 ||
        (hrAsync.valueOrNull?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverCollapsingHeader(
              title: l.homeTitle,
              controller: _scroll,
              action: const NotificationBell(),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs,
                  AppSpacing.lg, MediaQuery.paddingOf(context).bottom + AppSpacing.md),
              sliver: SliverList.list(
                children: [
                  // ── Next session ─────────────────────────────────────────
                  assignmentAsync.when(
                    loading: () => const _CardSkeleton(height: 108),
                    error: (_, _) => _EmptyCard(
                        icon: Icons.wifi_off_rounded,
                        text: l.somethingWentWrong),
                    data: (a) {
                      if (a == null || a.sessions.isEmpty) {
                        return _EmptyCard(
                            icon: Icons.fitness_center,
                            text: l.noProgramAssigned);
                      }
                      final next = _nextSession(a)!;
                      final allDone =
                          a.sessions.every((s) => s.isCompleted);
                      return _NextSessionCard(
                        programName: a.name,
                        session: next,
                        note: allDone ? l.allSessionsDone : null,
                        onStart: () => _openRunner(a, next),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── KPIs ─────────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _KpiTile(
                          icon: Icons.directions_walk_rounded,
                          value: stepsAsync.isLoading
                              ? null
                              : compactNumber(stepsToday ?? 0),
                          label: l.stepsToday,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _KpiTile(
                          icon: Icons.local_fire_department_rounded,
                          value: kcalAsync.isLoading
                              ? null
                              : compactNumber(kcalAsync.valueOrNull ?? 0),
                          label: l.caloriesToday,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _KpiTile(
                          icon: Icons.event_available_rounded,
                          value: summaryAsync.isLoading
                              ? null
                              : '${summaryAsync.valueOrNull?.visitsThisWeek ?? 0}',
                          label: l.progressThisWeek,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _KpiTile(
                          icon: Icons.whatshot_rounded,
                          value: summaryAsync.isLoading
                              ? null
                              : '${summaryAsync.valueOrNull?.weekStreak ?? 0}',
                          label: l.progressStreak,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Health & activity ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(l.healthSection,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.textTertiary)),
                      ),
                      TextButton(
                        onPressed: _openHealthDetail,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.primary,
                        ),
                        child: Text(l.seeMore,
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (stepsAsync.isLoading || hrAsync.isLoading) ...[
                    const _CardSkeleton(height: 200),
                    const SizedBox(height: AppSpacing.md),
                    const _CardSkeleton(height: 200),
                  ] else if (!hasHealthData)
                    AppCard(
                      margin: EdgeInsets.zero,
                      onTap: _openHealthDetail,
                      child: Row(
                        children: [
                          Icon(Icons.monitor_heart_outlined,
                              color: AppColors.primary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(l.noHealthData,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary)),
                          ),
                          Icon(Icons.chevron_right,
                              color: AppColors.textTertiary),
                        ],
                      ),
                    )
                  else ...[
                    _ChartCard(
                      title: l.stepsLast7Days,
                      child: StepsBarChart(data: steps),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ChartCard(
                      title: l.heartRateToday,
                      child: (hrAsync.valueOrNull?.isEmpty ?? true)
                          ? Center(
                              child: Text(l.noHeartRateData,
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textTertiary)),
                            )
                          : HeartRateChart(samples: hrAsync.valueOrNull!),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),

                  // ── All sessions ─────────────────────────────────────────
                  assignmentAsync.maybeWhen(
                    data: (a) {
                      if (a == null || a.sessions.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.homeSessions,
                              style: AppTextStyles.label
                                  .copyWith(color: AppColors.textTertiary)),
                          const SizedBox(height: AppSpacing.xs),
                          for (final s in a.sessions)
                            _SessionRow(
                              session: s,
                              onTap: () => _openRunner(a, s),
                            ),
                        ],
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── widgets ────

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({
    required this.programName,
    required this.session,
    required this.onStart,
    this.note,
  });

  final String programName;
  final TrainingAssignmentSession session;
  final VoidCallback onStart;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: onStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.nextSession.toUpperCase(),
              style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading3),
                    const SizedBox(height: 2),
                    Text(
                      '$programName · ${l.sessionCount(session.exercises.length)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded,
                    color: AppColors.onPrimary, size: 28),
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(note!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiary)),
          ],
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String? value; // null → loading skeleton
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: AppSpacing.sm),
          value == null
              ? const SkeletonLoader(child: SkeletonBox(width: 48, height: 22))
              : Text(value!,
                  style: AppTextStyles.heading2
                      .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
          SizedBox(height: 170, child: child),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onTap});

  final TrainingAssignmentSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(l.sessionCount(session.exercises.length),
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          if (session.isCompleted)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child:
                  Icon(Icons.check_circle, size: 18, color: AppColors.success),
            ),
          Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Icon(icon, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

/// Layout-matching loading placeholder for an async card section.
class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: SkeletonBox(
          width: double.infinity, height: height, borderRadius: AppRadius.lg),
    );
  }
}
