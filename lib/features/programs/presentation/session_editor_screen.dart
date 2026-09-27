import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/programs/data/models/session_exercise.dart';
import 'package:lynx_app/features/programs/data/models/training_session.dart';
import 'package:lynx_app/features/programs/data/program_repository.dart';
import 'package:lynx_app/features/programs/providers/programs_provider.dart';
import 'package:lynx_app/features/programs/presentation/exercise_picker_sheet.dart';
import 'package:lynx_app/features/programs/presentation/prescription_editor_sheet.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/reorder_proxy.dart';
import 'package:lynx_app/shared/widgets/skeleton_list.dart';

/// Edits one session: its ordered exercises + prescriptions.
class SessionEditorScreen extends ConsumerStatefulWidget {
  const SessionEditorScreen({
    super.key,
    required this.programId,
    required this.sessionId,
  });

  final String programId;
  final String sessionId;

  @override
  ConsumerState<SessionEditorScreen> createState() => _SessionEditorScreenState();
}

class _SessionEditorScreenState extends ConsumerState<SessionEditorScreen> {
  /// Local copy for optimistic reorder; synced from [sessionEditorProvider] via
  /// `ref.listen` in build.
  TrainingSession? _session;

  /// Scroll-driven frost/shrink for the floating nav bar (mirrors
  /// [FrostedNavScaffold]): 0 at the top, ramps to 1 over the first 60px.
  double _collapse = 0;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final t = (n.metrics.pixels / 60).clamp(0.0, 1.0);
    if ((t - _collapse).abs() > 0.01) setState(() => _collapse = t);
    return false;
  }

  SessionEditorKey get _key =>
      (programId: widget.programId, sessionId: widget.sessionId);

  String get _tenantId =>
      ref.read(currentUserProvider).valueOrNull?.tenantId ?? '';

  void _refresh() {
    ref.invalidate(sessionEditorProvider(_key));
    ref.invalidate(programProvider(widget.programId));
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
      _refresh();
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _addExercise() async {
    final exercise = await showExercisePicker(context);
    if (exercise == null || !mounted) return;
    final prescription = await showPrescriptionEditor(context, exerciseName: exercise.name);
    if (prescription == null || !mounted) return;
    await _guard(() => ProgramRepository.addSessionExercise(
          tenantId: _tenantId,
          sessionId: widget.sessionId,
          exerciseId: exercise.id,
          orderIndex: _session?.exercises.length ?? 0,
          prescription: prescription,
        ));
  }

  Future<void> _editExercise(SessionExercise se) async {
    final prescription = await showPrescriptionEditor(
      context,
      exerciseName: se.exerciseName,
      initial: se,
    );
    if (prescription == null || !mounted) return;
    await _guard(() => ProgramRepository.updateSessionExercise(
          tenantId: _tenantId,
          sessionExerciseId: se.id,
          prescription: prescription,
        ));
  }

  Future<void> _removeExercise(SessionExercise se) => _guard(
        () => ProgramRepository.deleteSessionExercise(
          tenantId: _tenantId,
          sessionExerciseId: se.id,
        ),
      );

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final list = [...?_session?.exercises];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    setState(() => _session = _session == null
        ? null
        : TrainingSession(
            id: _session!.id,
            label: _session!.label,
            orderIndex: _session!.orderIndex,
            exercises: list,
          ));
    await _guard(() => ProgramRepository.setExerciseOrder(
          tenantId: _tenantId,
          orderedIds: list.map((e) => e.id).toList(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Keep the local (optimistically-reorderable) copy in sync with the provider.
    ref.listen(sessionEditorProvider(_key), (prev, next) {
      next.whenData((s) {
        if (mounted) setState(() => _session = s);
      });
    });
    final async = ref.watch(sessionEditorProvider(_key));
    // Fall back to the provider's current value: `ref.listen` only fires on
    // *changes*, so it misses a value already resolved before this screen
    // mounted — which otherwise shows the error state over a real session.
    final session = _session ?? async.valueOrNull;
    final loading = session == null && async.isLoading;
    final topInset = AppNavBar.estimatedHeight(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_session_editor',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: _addExercise,
        icon: const Icon(Icons.add),
        label: Text(l.addExercise),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: loading
                ? SessionEditorSkeleton(topInset: topInset)
                : session == null
                    ? Padding(
                        padding: EdgeInsets.only(top: topInset),
                        child: Center(
                            child: Text(l.somethingWentWrong,
                                style: AppTextStyles.bodySmall)),
                      )
                    : session.exercises.isEmpty
                        ? Padding(
                            padding: EdgeInsets.only(
                                top: topInset, left: AppSpacing.xl, right: AppSpacing.xl),
                            child: Center(
                                child: Text(l.sessionExercisesEmpty,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodySmall)),
                          )
                        : SafeArea(
                            top: false,
                            bottom: false,
                            child: ReorderableListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                  AppSpacing.lg, topInset + AppSpacing.sm, AppSpacing.lg, 96),
                              itemCount: session.exercises.length,
                              proxyDecorator: roundedReorderProxy,
                              onReorderItem: _reorder,
                              itemBuilder: (context, i) {
                                final se = session.exercises[i];
                                return _ExerciseCard(
                                  key: ValueKey(se.id),
                                  se: se,
                                  onEdit: () => _editExercise(se),
                                  onRemove: () => _removeExercise(se),
                                );
                              },
                            ),
                          ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppNavBar(
              title: session?.label ?? '…',
              blurred: true,
              frost: _collapse,
              scale: lerpDouble(1.0, 0.9, _collapse)!,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.se,
    required this.onEdit,
    required this.onRemove,
  });

  final SessionExercise se;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(se.exerciseName,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  if (se.prescriptionSummary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(se.prescriptionSummary, style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.close, color: AppColors.textTertiary),
              tooltip: l.remove,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
