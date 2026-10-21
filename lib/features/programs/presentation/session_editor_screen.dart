import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/core/utils/uuid.dart';
import 'package:lynx_app/features/programs/data/models/session_exercise.dart';
import 'package:lynx_app/features/programs/data/models/training_method.dart';
import 'package:lynx_app/features/programs/data/models/training_session.dart';
import 'package:lynx_app/features/programs/data/program_repository.dart';
import 'package:lynx_app/features/programs/providers/programs_provider.dart';
import 'package:lynx_app/features/programs/presentation/exercise_picker_sheet.dart';
import 'package:lynx_app/features/programs/presentation/method_labels.dart';
import 'package:lynx_app/features/programs/presentation/method_picker_sheet.dart';
import 'package:lynx_app/features/programs/presentation/prescription_editor_sheet.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/reorder_proxy.dart';
import 'package:lynx_app/shared/widgets/skeleton_list.dart';

/// Edits one session: its ordered exercises + prescriptions + training methods.
class SessionEditorScreen extends ConsumerStatefulWidget {
  const SessionEditorScreen({
    super.key,
    required this.programId,
    required this.sessionId,
    this.sessionLabel,
  });

  final String programId;
  final String sessionId;

  /// Known session label from the caller — used as the header title while the
  /// session is still loading (or if it fails to resolve), so the nav bar never
  /// shows a bare "…".
  final String? sessionLabel;

  @override
  ConsumerState<SessionEditorScreen> createState() => _SessionEditorScreenState();
}

class _SessionEditorScreenState extends ConsumerState<SessionEditorScreen> {
  /// Local copy for optimistic reorder; synced from [sessionEditorProvider] via
  /// `ref.listen` in build.
  TrainingSession? _session;

  double _collapse = 0;

  @override
  void initState() {
    super.initState();
    // Ensure the program is (re)fetched fresh so a just-created session always
    // resolves — the shared programProvider may otherwise serve a cached copy
    // taken before this session existed.
    Future.microtask(() {
      if (mounted) ref.invalidate(programProvider(widget.programId));
    });
  }

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

  /// Method-first add flow: the coach picks the training method, then the
  /// exercise; the prescription editor opens prefilled with the method's
  /// defaults (sets, rep scheme, pauses) so only exercise-specific values
  /// (weight…) remain to fill in.
  Future<void> _addExercise() async {
    final method = await showMethodPicker(context);
    if (method == null || !mounted) return;
    if (methodRequiresGroup(method)) {
      await _addAsGroup(method);
      return;
    }
    final exercise = await showExercisePicker(context);
    if (exercise == null || !mounted) return;
    final prescription = await showPrescriptionEditor(
      context,
      exerciseName: exercise.name,
      metricSchema: exercise.metricSchema,
      lockMethod: method,
    );
    if (prescription == null || !mounted) return;
    await _guard(() => ProgramRepository.addSessionExercise(
          tenantId: _tenantId,
          sessionId: widget.sessionId,
          exerciseId: exercise.id,
          orderIndex: _session?.exercises.length ?? 0,
          prescription: prescription,
        ));
  }

  /// Builds a method group (2+ exercises sharing one group id): keeps offering
  /// the exercise picker + prefilled prescription until the coach cancels.
  Future<void> _addAsGroup(TrainingMethod method) async {
    final groupId = uuidV4();
    var order = _session?.exercises.length ?? 0;
    var groupOrder = 0;
    var added = 0;

    while (true) {
      if (!mounted) return;
      final ex = await showExercisePicker(context);
      if (ex == null || !mounted) break;
      final pp = await showPrescriptionEditor(
        context,
        exerciseName: ex.name,
        metricSchema: ex.metricSchema,
        lockMethod: method,
        groupId: groupId,
        groupOrder: groupOrder,
      );
      if (pp == null || !mounted) break;
      final capturedOrder = order;
      await _guard(() => ProgramRepository.addSessionExercise(
            tenantId: _tenantId,
            sessionId: widget.sessionId,
            exerciseId: ex.id,
            orderIndex: capturedOrder,
            prescription: pp,
          ));
      order++;
      groupOrder++;
      added++;
    }

    if (!mounted) return;
    if (added > 0 && added < 2) {
      AppToast.show(context,
          title: AppLocalizations.of(context).methodNeedsMultiple, blur: false);
    }
  }

  /// Adds one more exercise into an existing group, re-sequencing so it sits
  /// right after the group's current last member.
  Future<void> _addToGroup(SessionExercise lastMember) async {
    final ex = await showExercisePicker(context);
    if (ex == null || !mounted) return;
    final current = _session?.exercises ?? const [];
    final groupMembers =
        current.where((e) => e.methodGroupId == lastMember.methodGroupId);
    final nextGroupOrder = groupMembers.isEmpty
        ? 0
        : groupMembers.map((e) => e.groupOrder).reduce((a, b) => a > b ? a : b) +
            1;
    final pp = await showPrescriptionEditor(
      context,
      exerciseName: ex.name,
      metricSchema: ex.metricSchema,
      lockMethod: lastMember.method,
      groupId: lastMember.methodGroupId,
      groupOrder: nextGroupOrder,
    );
    if (pp == null || !mounted) return;

    await _guard(() async {
      final newId = await ProgramRepository.addSessionExercise(
        tenantId: _tenantId,
        sessionId: widget.sessionId,
        exerciseId: ex.id,
        orderIndex: current.length,
        prescription: pp,
      );
      final ids = current.map((e) => e.id).toList();
      final lastIdx = ids.indexOf(lastMember.id);
      ids.insert(lastIdx + 1, newId);
      await ProgramRepository.setExerciseOrder(
          tenantId: _tenantId, orderedIds: ids);
    });
  }

  Future<void> _editExercise(SessionExercise se) async {
    final prescription = await showPrescriptionEditor(
      context,
      exerciseName: se.exerciseName,
      metricSchema: se.metricSchema,
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
            phaseId: _session!.phaseId,
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
    ref.listen(sessionEditorProvider(_key), (prev, next) {
      next.whenData((s) {
        if (mounted) setState(() => _session = s);
      });
    });
    final async = ref.watch(sessionEditorProvider(_key));
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
                      ? _SessionEditorMessage(
                          topInset: topInset,
                          icon: Icons.error_outline_rounded,
                          message: l.somethingWentWrong,
                        )
                      : session.exercises.isEmpty
                          ? _SessionEditorMessage(
                              topInset: topInset,
                              icon: Icons.fitness_center_outlined,
                              message: l.sessionExercisesEmpty,
                            )
                          : SafeArea(
                              top: false,
                              bottom: false,
                              child: ReorderableListView.builder(
                                padding: EdgeInsets.fromLTRB(AppSpacing.lg,
                                    topInset + AppSpacing.sm, AppSpacing.lg, 96),
                                itemCount: session.exercises.length,
                                proxyDecorator: roundedReorderProxy,
                                onReorderItem: _reorder,
                                itemBuilder: (context, i) {
                                  final list = session.exercises;
                                  final se = list[i];
                                  final gid = se.methodGroupId;
                                  final inGroup = gid != null && gid.isNotEmpty;
                                  final prevGid =
                                      i > 0 ? list[i - 1].methodGroupId : null;
                                  final nextGid = i < list.length - 1
                                      ? list[i + 1].methodGroupId
                                      : null;
                                  final isFirst = inGroup && gid != prevGid;
                                  final isLast = inGroup && gid != nextGid;
                                  return _ExerciseCard(
                                    key: ValueKey(se.id),
                                    se: se,
                                    inGroup: inGroup,
                                    isFirstInGroup: isFirst,
                                    isLastInGroup: isLast,
                                    onEdit: () => _editExercise(se),
                                    onRemove: () => _removeExercise(se),
                                    onAddToGroup:
                                        isLast ? () => _addToGroup(se) : null,
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
              title: session?.label ?? widget.sessionLabel ?? '…',
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

/// Centered icon + message used for the empty and error states — mirrors the
/// screen's content area (below the floating nav bar).
class _SessionEditorMessage extends StatelessWidget {
  const _SessionEditorMessage({
    required this.topInset,
    required this.icon,
    required this.message,
  });

  final double topInset;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: topInset, left: AppSpacing.xl, right: AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.se,
    required this.inGroup,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.onEdit,
    required this.onRemove,
    this.onAddToGroup,
  });

  final SessionExercise se;
  final bool inGroup;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback? onAddToGroup;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Method badge: shown once for a group (on its first member), or on a
    // single exercise whose method isn't "straight".
    final showMethodBadge = isFirstInGroup ||
        (!inGroup &&
            se.method != TrainingMethod.straight &&
            se.method != TrainingMethod.none);

    final card = Container(
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
                if (showMethodBadge || (se.weekLabel ?? '').isNotEmpty) ...[
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (showMethodBadge)
                        _Pill(
                          text: methodLabel(l, se.method),
                          color: AppColors.primary,
                        ),
                      if ((se.weekLabel ?? '').isNotEmpty)
                        _Pill(
                          text: se.weekLabel!,
                          color: AppColors.textTertiary,
                          subtle: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Text(se.exerciseName,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                if (se.prescriptionSummary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(se.prescriptionSummary, style: AppTextStyles.bodySmall),
                ],
                if (onAddToGroup != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  InkWell(
                    onTap: onAddToGroup,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(l.addToGroup,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
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
    );

    return Padding(
      padding: EdgeInsets.only(
          bottom: inGroup && !isLastInGroup ? 2 : AppSpacing.sm),
      child: inGroup
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 3,
                    margin: const EdgeInsets.only(right: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  Expanded(child: card),
                ],
              ),
            )
          : card,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.subtle = false});
  final String text;
  final Color color;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: subtle
            ? AppColors.surfaceLight
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: subtle ? AppColors.textSecondary : color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
