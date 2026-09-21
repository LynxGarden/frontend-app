import 'package:flutter/material.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/programs/data/models/session_exercise.dart';
import 'package:lynx_app/features/programs/data/program_repository.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';

/// Bottom sheet to set/edit a session exercise's prescription. Returns a
/// [PrescriptionInput] on Done (null if dismissed).
Future<PrescriptionInput?> showPrescriptionEditor(
  BuildContext context, {
  required String exerciseName,
  SessionExercise? initial,
}) {
  return showModalBottomSheet<PrescriptionInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _PrescriptionEditor(exerciseName: exerciseName, initial: initial),
  );
}

class _PrescriptionEditor extends StatefulWidget {
  const _PrescriptionEditor({required this.exerciseName, this.initial});
  final String exerciseName;
  final SessionExercise? initial;

  @override
  State<_PrescriptionEditor> createState() => _PrescriptionEditorState();
}

class _PrescriptionEditorState extends State<_PrescriptionEditor> {
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _weight;
  late final TextEditingController _load;
  late final TextEditingController _rpe;
  late final TextEditingController _time;
  late final TextEditingController _tempo;
  late final TextEditingController _rest;
  late final TextEditingController _setType;
  late final TextEditingController _coachNote;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _sets = TextEditingController(text: p?.sets?.toString() ?? '');
    _reps = TextEditingController(text: p?.reps ?? '');
    _weight = TextEditingController(text: p?.weight ?? '');
    _load = TextEditingController(text: p?.loadIntensity ?? '');
    _rpe = TextEditingController(text: p?.rpe ?? '');
    _time = TextEditingController(text: p?.timeSeconds?.toString() ?? '');
    _tempo = TextEditingController(text: p?.tempo ?? '');
    _rest = TextEditingController(text: p?.restSeconds?.toString() ?? '');
    _setType = TextEditingController(text: p?.setTypeNote ?? '');
    _coachNote = TextEditingController(text: p?.coachNote ?? '');
  }

  @override
  void dispose() {
    for (final c in [_sets, _reps, _weight, _load, _rpe, _time, _tempo, _rest, _setType, _coachNote]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _intOrNull(TextEditingController c) => int.tryParse(c.text.trim());

  PrescriptionInput _build() => PrescriptionInput(
        sets: _intOrNull(_sets),
        reps: _reps.text,
        weight: _weight.text,
        loadIntensity: _load.text,
        rpe: _rpe.text,
        timeSeconds: _intOrNull(_time),
        tempo: _tempo.text,
        restSeconds: _intOrNull(_rest),
        setTypeNote: _setType.text,
        coachNote: _coachNote.text,
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, bottom + AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.exerciseName, style: AppTextStyles.heading3),
            Text(l.prescription, style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(child: _num(_sets, l.presSets)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _text(_reps, l.presReps)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: _text(_weight, l.presWeight)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _text(_load, l.presLoad)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: _text(_rpe, l.presRpe)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _num(_time, l.presTime)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: _text(_tempo, l.presTempo)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _num(_rest, l.presRest)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            _text(_setType, l.presSetType),
            const SizedBox(height: AppSpacing.sm),
            _text(_coachNote, l.presCoachNote),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l.done,
              isExpanded: true,
              onPressed: () => Navigator.of(context).pop(_build()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _text(TextEditingController c, String label) =>
      AppTextField(label: label, controller: c, hintText: '');

  Widget _num(TextEditingController c, String label) => AppTextField(
        label: label,
        controller: c,
        hintText: '',
        keyboardType: TextInputType.number,
      );
}
