import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/programs/data/models/session_exercise.dart';
import 'package:lynx_app/features/programs/data/models/training_method.dart';
import 'package:lynx_app/features/programs/data/program_repository.dart';
import 'package:lynx_app/features/programs/presentation/method_labels.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';

/// Bottom sheet to set/edit a session exercise's prescription + training method.
/// Returns a [PrescriptionInput] on Done (null if dismissed).
///
/// [lockMethod] forces the method (used when adding an exercise into an existing
/// method group); [groupId]/[groupOrder] are threaded onto the result so the
/// exercise joins that group.
Future<PrescriptionInput?> showPrescriptionEditor(
  BuildContext context, {
  required String exerciseName,
  SessionExercise? initial,
  TrainingMethod? lockMethod,
  String? groupId,
  int groupOrder = 0,
}) {
  return showModalBottomSheet<PrescriptionInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _PrescriptionEditor(
      exerciseName: exerciseName,
      initial: initial,
      lockMethod: lockMethod,
      groupId: groupId,
      groupOrder: groupOrder,
    ),
  );
}

class _PrescriptionEditor extends StatefulWidget {
  const _PrescriptionEditor({
    required this.exerciseName,
    this.initial,
    this.lockMethod,
    this.groupId,
    this.groupOrder = 0,
  });
  final String exerciseName;
  final SessionExercise? initial;
  final TrainingMethod? lockMethod;
  final String? groupId;
  final int groupOrder;

  @override
  State<_PrescriptionEditor> createState() => _PrescriptionEditorState();
}

class _PrescriptionEditorState extends State<_PrescriptionEditor> {
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _weight;
  late final TextEditingController _load;
  late final TextEditingController _rpe;
  late final TextEditingController _rir;
  late final TextEditingController _time;
  late final TextEditingController _tempo;
  late final TextEditingController _rest;
  late final TextEditingController _interval;
  late final TextEditingController _coachNote;
  late final TextEditingController _week;

  late TrainingMethod _method;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _method = widget.lockMethod ?? p?.method ?? TrainingMethod.straight;
    _sets = TextEditingController(text: p?.sets?.toString() ?? '');
    _reps = TextEditingController(text: p?.reps ?? '');
    _weight = TextEditingController(text: p?.weight ?? '');
    _load = TextEditingController(text: p?.loadIntensity ?? '');
    _rpe = TextEditingController(text: p?.rpe ?? '');
    _rir = TextEditingController(text: p?.rir ?? '');
    _time = TextEditingController(text: p?.timeSeconds?.toString() ?? '');
    _tempo = TextEditingController(text: p?.tempo ?? '');
    _rest = TextEditingController(text: p?.restSeconds?.toString() ?? '');
    _interval = TextEditingController(
        text: (p?.methodConfig['interval_seconds'])?.toString() ?? '');
    _coachNote = TextEditingController(text: p?.coachNote ?? '');
    _week = TextEditingController(text: p?.weekLabel ?? '');
    // On a fresh add with a locked (group) method, seed the defaults too.
    if (widget.lockMethod != null && p == null) {
      _applyMethodDefaults(_method);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _sets, _reps, _weight, _load, _rpe, _rir, _time, _tempo, _rest,
      _interval, _coachNote, _week,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _intOrNull(TextEditingController c) => int.tryParse(c.text.trim());

  /// Prefills empty fields from the method's defaults (never clobbers input).
  void _applyMethodDefaults(TrainingMethod m) {
    final d = methodDefaults(m);
    if (_sets.text.trim().isEmpty && d.sets != null) {
      _sets.text = d.sets.toString();
    }
    if (_reps.text.trim().isEmpty && d.reps != null) _reps.text = d.reps!;
    if (_rest.text.trim().isEmpty && d.restSeconds != null) {
      _rest.text = d.restSeconds.toString();
    }
    if (methodIsInterval(m) && _interval.text.trim().isEmpty) {
      final iv = d.config['interval_seconds'];
      if (iv != null) _interval.text = iv.toString();
    }
  }

  Map<String, dynamic> _buildConfig() {
    final config =
        Map<String, dynamic>.from(widget.initial?.methodConfig ?? const {});
    methodDefaults(_method).config.forEach((k, v) {
      config.putIfAbsent(k, () => v);
    });
    if (methodIsInterval(_method)) {
      final iv = _intOrNull(_interval);
      if (iv != null) config['interval_seconds'] = iv;
    }
    return config;
  }

  PrescriptionInput _build() => PrescriptionInput(
        sets: _intOrNull(_sets),
        reps: _reps.text,
        weight: _weight.text,
        loadIntensity: _load.text,
        rpe: _rpe.text,
        rir: _rir.text,
        timeSeconds: _intOrNull(_time),
        tempo: _tempo.text,
        restSeconds: _intOrNull(_rest),
        coachNote: _coachNote.text,
        method: _method,
        methodGroupId: widget.groupId ?? widget.initial?.methodGroupId,
        groupOrder: widget.groupId != null
            ? widget.groupOrder
            : (widget.initial?.groupOrder ?? 0),
        methodConfig: _buildConfig(),
        weekLabel: _week.text,
      );

  Future<void> _pickMethod() async {
    final picked = await showModalBottomSheet<TrainingMethod>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetCtx) {
        final l = AppLocalizations.of(sheetCtx);
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l.trainingMethod,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textTertiary)),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final m in TrainingMethod.values)
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(sheetCtx).pop(m);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(methodLabel(l, m),
                                      style: AppTextStyles.body.copyWith(
                                          color: m == _method
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                          fontWeight: m == _method
                                              ? FontWeight.w600
                                              : FontWeight.w400)),
                                ),
                                if (m == _method)
                                  Icon(Icons.check, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _method = picked;
        _applyMethodDefaults(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, bottom + AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.exerciseName, style: AppTextStyles.heading3),
            Text(l.prescription, style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.md),
            // Method picker (hidden when locked to a group's method).
            if (widget.lockMethod == null) ...[
              _MethodField(
                label: l.trainingMethod,
                value: methodLabel(l, _method),
                onTap: _pickMethod,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (methodIsInterval(_method)) ...[
              _num(_interval, l.intervalSeconds),
              const SizedBox(height: AppSpacing.sm),
            ],
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
              Expanded(child: _text(_rir, l.presRir)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: _text(_tempo, l.presTempo)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _num(_rest, l.presRest)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Expanded(child: _num(_time, l.presTime)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _text(_week, l.weekTag, hint: l.weekTagHint)),
            ]),
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

  Widget _text(TextEditingController c, String label, {String hint = ''}) =>
      AppTextField(label: label, controller: c, hintText: hint);

  Widget _num(TextEditingController c, String label) => AppTextField(
        label: label,
        controller: c,
        hintText: '',
        keyboardType: TextInputType.number,
      );
}

/// A tappable field that opens the method picker. Styled to match AppTextField.
class _MethodField extends StatelessWidget {
  const _MethodField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(value,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textPrimary)),
                ),
                Icon(Icons.expand_more, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
