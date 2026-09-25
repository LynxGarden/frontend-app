import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/programs/presentation/exercise_picker_sheet.dart';
import 'package:lynx_app/features/training/data/models/active_assignment.dart';
import 'package:lynx_app/features/training/data/training_repository.dart';
import 'package:lynx_app/features/training/providers/training_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

/// The gym-facing session runner: per exercise show the target, the video, the
/// LAST TIME actuals, inputs to log today's sets, and a swap action. A FAB marks
/// the whole session complete.
class SessionRunnerScreen extends ConsumerStatefulWidget {
  const SessionRunnerScreen({
    super.key,
    required this.assignmentId,
    required this.sessionId,
  });

  final String assignmentId;
  final String sessionId;

  @override
  ConsumerState<SessionRunnerScreen> createState() => _SessionRunnerScreenState();
}

class _SessionRunnerScreenState extends ConsumerState<SessionRunnerScreen> {
  bool _completing = false;

  RunnerKey get _key =>
      (assignmentId: widget.assignmentId, sessionId: widget.sessionId);

  Future<void> _swap(TrainingExercise ex) async {
    final l = AppLocalizations.of(context);
    final replacement = await showExercisePicker(context);
    if (replacement == null || !mounted) return;
    try {
      await TrainingRepository.swapExercise(
        assignmentExerciseId: ex.id,
        newExerciseId: replacement.id,
      );
      ref.invalidate(activeAssignmentProvider);
      ref.invalidate(sessionRunnerProvider(_key));
      if (mounted) AppToast.show(context, title: l.exerciseSwappedToast, blur: false);
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _complete(TrainingAssignmentSession session) async {
    final l = AppLocalizations.of(context);
    setState(() => _completing = true);
    try {
      await TrainingRepository.completeSession(session.id);
      ref.invalidate(activeAssignmentProvider);
      HapticFeedback.heavyImpact();
      if (mounted) {
        AppToast.show(context, title: l.sessionDoneToast, blur: false);
        Navigator.of(context).pop();
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _completing = false);
        AppToast.show(context, title: e.message, blur: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final async = ref.watch(sessionRunnerProvider(_key));
    final session = async.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: (session != null && user != null)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.forest,
              foregroundColor: AppColors.onPrimary,
              onPressed: _completing ? null : () => _complete(session),
              icon: _completing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.onPrimary),
                    )
                  : const Icon(Icons.check),
              label: Text(l.markComplete),
            )
          : null,
      body: Column(
        children: [
          AppNavBar(title: session?.label ?? '…'),
          Expanded(
            child: async.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.forest)),
              error: (_, _) => Center(
                  child: Text(l.somethingWentWrong,
                      style: AppTextStyles.bodySmall)),
              data: (session) => (session == null || user == null)
                  ? Center(
                      child: Text(l.somethingWentWrong,
                          style: AppTextStyles.bodySmall))
                  : SafeArea(
                      top: false,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
                        itemCount: session.exercises.length,
                        itemBuilder: (context, i) {
                          final ex = session.exercises[i];
                          return _ExerciseRunnerCard(
                            key: ValueKey(ex.id),
                            exercise: ex,
                            tenantId: user.tenantId,
                            personId: user.personId,
                            onSwap: () => _swap(ex),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One logged set from this visit (kept in memory for instant feedback).
class _TodaySet {
  const _TodaySet({required this.setIndex, this.reps, this.weight, this.timeSeconds});
  final int setIndex;
  final int? reps;
  final num? weight;
  final int? timeSeconds;

  String get summary {
    final parts = <String>[];
    if (reps != null) {
      parts.add(weight != null ? '$reps × ${_trim(weight!)}' : '$reps');
    } else if (weight != null) {
      parts.add(_trim(weight!));
    }
    if (timeSeconds != null) parts.add('${timeSeconds}s');
    return parts.join(' ');
  }

  static String _trim(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

class _ExerciseRunnerCard extends ConsumerStatefulWidget {
  const _ExerciseRunnerCard({
    super.key,
    required this.exercise,
    required this.tenantId,
    required this.personId,
    required this.onSwap,
  });

  final TrainingExercise exercise;
  final String tenantId;
  final String personId;
  final VoidCallback onSwap;

  @override
  ConsumerState<_ExerciseRunnerCard> createState() => _ExerciseRunnerCardState();
}

class _ExerciseRunnerCardState extends ConsumerState<_ExerciseRunnerCard> {
  final _reps = TextEditingController();
  final _weight = TextEditingController();
  final _time = TextEditingController();
  final _todaySets = <_TodaySet>[];
  bool _prefilled = false;
  bool _saving = false;

  bool get _isTimed => widget.exercise.timeSeconds != null;

  @override
  void dispose() {
    _reps.dispose();
    _weight.dispose();
    _time.dispose();
    super.dispose();
  }

  /// Carry the last-time values in as prefilled defaults (minimal taps).
  void _prefillFrom(List<LoggedEntry> last) {
    if (_prefilled || last.isEmpty) return;
    _prefilled = true;
    final first = last.first;
    if (first.reps != null) _reps.text = '${first.reps}';
    if (first.weight != null) _weight.text = _TodaySet._trim(first.weight!);
    if (first.timeSeconds != null) _time.text = '${first.timeSeconds}';
  }

  Future<void> _watchVideo() async {
    final l = AppLocalizations.of(context);
    final url = widget.exercise.videoUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    final ok = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppToast.show(context, title: l.couldNotOpenVideo, blur: false);
    }
  }

  Future<void> _logSet() async {
    final l = AppLocalizations.of(context);
    final reps = int.tryParse(_reps.text.trim());
    final weight = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    final time = int.tryParse(_time.text.trim());
    if (reps == null && weight == null && time == null) return;

    setState(() => _saving = true);
    final setIndex = _todaySets.length + 1;
    try {
      await TrainingRepository.logSet(
        tenantId: widget.tenantId,
        personId: widget.personId,
        exerciseId: widget.exercise.exerciseId,
        assignmentExerciseId: widget.exercise.id,
        setIndex: setIndex,
        reps: reps,
        weight: weight,
        timeSeconds: time,
      );
      HapticFeedback.lightImpact();
      if (mounted) {
        setState(() {
          _todaySets.add(_TodaySet(
              setIndex: setIndex, reps: reps, weight: weight, timeSeconds: time));
          _saving = false;
        });
        AppToast.show(context, title: l.setLoggedToast, blur: false);
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppToast.show(context, title: e.message, blur: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ex = widget.exercise;
    final lastAsync = ref.watch(lastEntriesProvider(ex.exerciseId));
    lastAsync.whenData(_prefillFrom);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name + swap
            Row(
              children: [
                Expanded(
                  child: Text(ex.exerciseName,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 17)),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz, color: AppColors.forest),
                  tooltip: l.swapExercise,
                  onPressed: widget.onSwap,
                ),
              ],
            ),
            // Target
            if (ex.targetSummary.isNotEmpty)
              _KeyValueLine(label: l.targetLabel, value: ex.targetSummary),
            if (ex.setTypeNote != null && ex.setTypeNote!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(ex.setTypeNote!,
                    style: AppTextStyles.bodySmall
                        .copyWith(fontStyle: FontStyle.italic)),
              ),
            if (ex.coachNote != null && ex.coachNote!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${l.coachNoteLabel}: ${ex.coachNote!}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
            if (ex.videoUrl != null && ex.videoUrl!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: _watchVideo,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_outline,
                        size: 18, color: AppColors.forest),
                    const SizedBox(width: 6),
                    Text(l.watchVideo,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            // LAST TIME
            _LastTimeBlock(async: lastAsync),

            // Today's logged sets
            if (_todaySets.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final s in _todaySets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 15, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text('${l.setN(s.setIndex)}: ${s.summary}',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
            ],

            const SizedBox(height: AppSpacing.sm),
            // Inputs
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _NumField(controller: _reps, label: l.repsLabel),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NumField(
                      controller: _weight, label: l.weightLabel, decimal: true),
                ),
                if (_isTimed) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _NumField(controller: _time, label: l.timeSecLabel),
                  ),
                ],
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    onPressed: _saving ? null : _logSet,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.onPrimary),
                          )
                        : Text(_todaySets.isEmpty ? l.logSet : l.addSet),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyValueLine extends StatelessWidget {
  const _KeyValueLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodySmall,
          children: [
            TextSpan(
              text: '$label · ',
              style: AppTextStyles.label.copyWith(color: AppColors.textTertiary),
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastTimeBlock extends StatelessWidget {
  const _LastTimeBlock({required this.async});
  final AsyncValue<List<LoggedEntry>> async;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.lastTime.toUpperCase(),
              style: AppTextStyles.label.copyWith(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4)),
          const SizedBox(height: 4),
          async.when(
            loading: () => Text('…', style: AppTextStyles.bodySmall),
            error: (_, _) =>
                Text(l.noHistoryYet, style: AppTextStyles.bodySmall),
            data: (entries) {
              if (entries.isEmpty) {
                return Text(l.noHistoryYet,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary));
              }
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: 2,
                children: [
                  for (var i = 0; i < entries.length; i++)
                    Text('${i + 1}. ${entries[i].summary}',
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w600)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.controller,
    required this.label,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String label;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.label.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 4),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            keyboardType:
                TextInputType.numberWithOptions(decimal: decimal, signed: false),
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: AppColors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: AppColors.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.forest),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
