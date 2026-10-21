import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/progress/data/models/progress_models.dart';
import 'package:lynx_app/features/progress/presentation/widgets/progress_line_chart.dart';
import 'package:lynx_app/features/progress/providers/progress_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/app_segmented_control.dart';
import 'package:lynx_app/shared/widgets/collapsing_header.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// Which weekly metric the chart shows.
enum _Metric { volume, weight }

/// The client's Progress tab: streak + visits, a tracked-exercise picker, and
/// per-exercise personal bests + a weekly chart.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  final _scroll = ScrollController();
  _Metric _metric = _Metric.volume;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final summary = ref.watch(progressSummaryProvider);
    final tracked = ref.watch(trackedExercisesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(progressSummaryProvider);
          ref.invalidate(trackedExercisesProvider);
          await ref.read(progressSummaryProvider.future);
        },
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverCollapsingHeader(title: l.progressTitle, controller: _scroll),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
              ),
              sliver: summary.when(
                loading: () =>
                    const SliverToBoxAdapter(child: _ProgressSkeleton()),
                error: (_, _) => SliverToBoxAdapter(
                  child: _EmptyBox(icon: Icons.wifi_off_rounded, text: l.noProgressYet),
                ),
                data: (s) {
                  if (!s.hasAnyData) {
                    return SliverToBoxAdapter(
                      child: _EmptyBox(
                          icon: Icons.insights_outlined, text: l.noProgressYet),
                    );
                  }
                  return SliverList.list(children: [
                    _SummaryRow(summary: s),
                    const SizedBox(height: AppSpacing.lg),
                    tracked.when(
                      loading: () => const _ProgressSkeleton(),
                      error: (_, _) => _EmptyBox(
                          icon: Icons.insights_outlined,
                          text: l.progressNoExercises),
                      data: (list) => _ExerciseSection(
                        exercises: list,
                        metric: _metric,
                        onMetric: (m) => setState(() => _metric = m),
                      ),
                    ),
                  ]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department_rounded,
            value: '${summary.weekStreak}',
            label: l.progressStreak,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatTile(
            icon: Icons.event_available_rounded,
            value: '${summary.visitsThisWeek}',
            label: l.progressThisWeek,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: AppSpacing.sm),
          Text(value,
              style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ExerciseSection extends ConsumerWidget {
  const _ExerciseSection({
    required this.exercises,
    required this.metric,
    required this.onMetric,
  });

  final List<TrackedExercise> exercises;
  final _Metric metric;
  final ValueChanged<_Metric> onMetric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (exercises.isEmpty) {
      return _EmptyBox(
          icon: Icons.insights_outlined, text: l.progressNoExercises);
    }

    final selectedId = ref.watch(selectedProgressExerciseProvider);
    final effectiveId = (selectedId != null &&
            exercises.any((e) => e.exerciseId == selectedId))
        ? selectedId
        : exercises.first.exerciseId;
    final selected =
        exercises.firstWhere((e) => e.exerciseId == effectiveId);

    final progress = ref.watch(exerciseProgressProvider(effectiveId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ExercisePicker(
          selected: selected,
          exercises: exercises,
          onPick: (id) =>
              ref.read(selectedProgressExerciseProvider.notifier).state = id,
        ),
        const SizedBox(height: AppSpacing.lg),
        progress.when(
          loading: () => const _ProgressSkeleton(),
          error: (_, _) =>
              _EmptyBox(icon: Icons.insights_outlined, text: l.noProgressYet),
          data: (p) {
            if (p.isEmpty) {
              return _EmptyBox(
                  icon: Icons.insights_outlined, text: l.noProgressYet);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.personalBests,
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: AppSpacing.sm),
                _PbRow(progress: p),
                const SizedBox(height: AppSpacing.lg),
                AppSegmentedControl<_Metric>(
                  segments: [
                    AppSegment(value: _Metric.volume, label: l.progressVolume),
                    AppSegment(value: _Metric.weight, label: l.bestWeight),
                  ],
                  selected: metric,
                  onChanged: onMetric,
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  margin: EdgeInsets.zero,
                  child: SizedBox(
                    height: 220,
                    child: ProgressLineChart(
                      points: p.weekly,
                      value: metric == _Metric.volume
                          ? (w) => w.volume
                          : (w) => w.topWeight,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PbRow extends StatelessWidget {
  const _PbRow({required this.progress});

  final ExerciseProgress progress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    String fmt(double? v) =>
        v == null ? '—' : (v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1));
    // 2×2 grid of stat tiles. IntrinsicHeight + stretch keeps the two cards in
    // each row the same height even when a label wraps to two lines.
    Widget row(List<Widget> tiles) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[0]),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: tiles[1]),
            ],
          ),
        );
    return Column(
      children: [
        row([
          _PbTile(label: l.bestWeight, value: fmt(progress.bestWeight)),
          _PbTile(
              label: l.bestReps, value: progress.bestReps?.toString() ?? '—'),
        ]),
        const SizedBox(height: AppSpacing.sm),
        row([
          _PbTile(
              label: l.bestSeries, value: progress.bestSeries?.toString() ?? '—'),
          _PbTile(label: l.bestVolume, value: fmt(progress.bestVolume)),
        ]),
      ],
    );
  }
}

class _PbTile extends StatelessWidget {
  const _PbTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.heading3
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

class _ExercisePicker extends StatelessWidget {
  const _ExercisePicker({
    required this.selected,
    required this.exercises,
    required this.onPick,
  });

  final TrackedExercise selected;
  final List<TrackedExercise> exercises;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: () async {
        HapticFeedback.selectionClick();
        final picked = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: AppColors.surface,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          builder: (_) => _PickerSheet(
              exercises: exercises, selectedId: selected.exerciseId),
        );
        if (picked != null) onPick(picked);
      },
      child: Row(
        children: [
          Icon(Icons.fitness_center, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.progressPickExercise,
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: 2),
                Text(
                  selected.name.isEmpty ? l.exerciseDetails : selected.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Icon(Icons.expand_more, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({required this.exercises, required this.selectedId});

  final List<TrackedExercise> exercises;
  final String selectedId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: exercises.length,
                itemBuilder: (context, i) {
                  final e = exercises[i];
                  final sel = e.exerciseId == selectedId;
                  return ListTile(
                    title: Text(e.name,
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight:
                                sel ? FontWeight.w700 : FontWeight.w400)),
                    trailing: sel
                        ? Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop(e.exerciseId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text(text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(child: SkeletonBox(height: 84, borderRadius: 18)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonBox(height: 84, borderRadius: 18)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonBox(height: 64, borderRadius: 18),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: const [
              Expanded(child: SkeletonBox(height: 72, borderRadius: 18)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonBox(height: 72, borderRadius: 18)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: SkeletonBox(height: 72, borderRadius: 18)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonBox(height: 220, borderRadius: 18),
        ],
      ),
    );
  }
}
