import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/programs/data/models/session_exercise.dart';
import 'package:lynx_app/features/programs/data/models/training_session.dart';
import 'package:lynx_app/features/programs/data/program_repository.dart';
import 'package:lynx_app/features/programs/presentation/exercise_picker_sheet.dart';
import 'package:lynx_app/features/programs/presentation/prescription_editor_sheet.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

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
  TrainingSession? _session;
  bool _loading = true;

  String get _tenantId =>
      ref.read(currentUserProvider).valueOrNull?.tenantId ?? '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final program = await ProgramRepository.loadProgram(
        tenantId: _tenantId,
        programId: widget.programId,
      );
      final matches =
          program.sessions.where((s) => s.id == widget.sessionId).toList();
      final session = matches.isEmpty ? null : matches.first;
      if (mounted) setState(() { _session = session; _loading = false; });
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppToast.show(context, title: e.message, blur: false);
      }
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
      await _reload();
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
    final session = _session;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.onPrimary,
        onPressed: _addExercise,
        icon: const Icon(Icons.add),
        label: Text(l.addExercise),
      ),
      body: Column(
        children: [
          AppNavBar(title: session?.label ?? '…'),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.forest))
                : session == null
                    ? Center(
                        child: Text(l.somethingWentWrong,
                            style: AppTextStyles.bodySmall))
                    : session.exercises.isEmpty
                        ? Center(
                            child: Text(l.comingSoon,
                                style: AppTextStyles.bodySmall))
                        : SafeArea(
                            top: false,
                            child: ReorderableListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
                              itemCount: session.exercises.length,
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
              icon: const Icon(Icons.edit_outlined, color: AppColors.forest),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textTertiary),
              tooltip: l.remove,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
