import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/exercises/data/models/metric_field.dart';
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
  List<MetricField> metricSchema = const [],
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
      metricSchema: metricSchema,
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
    this.metricSchema = const [],
    this.initial,
    this.lockMethod,
    this.groupId,
    this.groupOrder = 0,
  });
  final String exerciseName;
  final List<MetricField> metricSchema;
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

  /// Dynamic controllers for the exercise's own metric fields (method = none),
  /// keyed by metric-field key.
  final Map<String, TextEditingController> _metric = {};

  late TrainingMethod _method;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _method = widget.lockMethod ?? p?.method ?? TrainingMethod.straight;
    for (final f in widget.metricSchema) {
      _metric[f.key] =
          TextEditingController(text: p?.targetMetrics[f.key] ?? '');
    }
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
    for (final c in _metric.values) {
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

  /// Collect the schema-field targets (trimmed, blanks dropped). Empty unless
  /// method = none.
  Map<String, String> _buildTargets() {
    if (_method != TrainingMethod.none) return const {};
    final out = <String, String>{};
    _metric.forEach((key, c) {
      final v = c.text.trim();
      if (v.isNotEmpty) out[key] = v;
    });
    return out;
  }

  PrescriptionInput _build() {
    final isNone = _method == TrainingMethod.none;
    return PrescriptionInput(
      // For a schema-driven exercise the strength grid is irrelevant — persist
      // only the custom targets + coach note.
      sets: isNone ? null : _intOrNull(_sets),
      reps: isNone ? null : _reps.text,
      weight: isNone ? null : _weight.text,
      loadIntensity: isNone ? null : _load.text,
      rpe: isNone ? null : _rpe.text,
      rir: isNone ? null : _rir.text,
      timeSeconds: isNone ? null : _intOrNull(_time),
      tempo: isNone ? null : _tempo.text,
      restSeconds: isNone ? null : _intOrNull(_rest),
      coachNote: _coachNote.text,
      method: _method,
      methodGroupId: widget.groupId ?? widget.initial?.methodGroupId,
      groupOrder: widget.groupId != null
          ? widget.groupOrder
          : (widget.initial?.groupOrder ?? 0),
      methodConfig: isNone ? const {} : _buildConfig(),
      weekLabel: _week.text,
      targetMetrics: _buildTargets(),
    );
  }

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
            // Method picker (static header when the method was chosen upfront
            // or comes from the group being extended).
            if (widget.lockMethod == null) ...[
              _MethodField(
                label: l.trainingMethod,
                value: methodLabel(l, _method),
                onTap: _pickMethod,
              ),
              const SizedBox(height: AppSpacing.sm),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(methodLabel(l, _method),
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(methodDescription(l, _method),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (_method == TrainingMethod.none)
              ..._schemaFields(l)
            else
              ..._strengthGrid(l),
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

  /// The fixed strength prescription grid (shown for every method except none).
  List<Widget> _strengthGrid(AppLocalizations l) => [
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
      ];

  /// The exercise's own metric fields (shown when method = none), laid out two
  /// per row, followed by the universal week-tag annotation.
  List<Widget> _schemaFields(AppLocalizations l) {
    final fields = widget.metricSchema;
    final rows = <Widget>[];
    if (fields.isEmpty) {
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(l.noMetricFields,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textTertiary)),
      ));
    }
    for (var i = 0; i < fields.length; i += 2) {
      final left = fields[i];
      final right = i + 1 < fields.length ? fields[i + 1] : null;
      rows.add(Row(children: [
        Expanded(child: _metricField(left)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: right == null ? const SizedBox() : _metricField(right)),
      ]));
      if (i + 2 < fields.length) rows.add(const SizedBox(height: AppSpacing.sm));
    }
    rows.add(const SizedBox(height: AppSpacing.sm));
    rows.add(_text(_week, l.weekTag, hint: l.weekTagHint));
    return rows;
  }

  /// One input for an exercise metric field — label carries the unit, keyboard
  /// matches the field type.
  Widget _metricField(MetricField f) {
    final label = (f.unit != null && f.unit!.trim().isNotEmpty)
        ? '${f.label} (${f.unit!.trim()})'
        : f.label;
    final numeric = f.type == MetricFieldType.number ||
        f.type == MetricFieldType.decimal;
    return AppTextField(
      label: label,
      controller: _metric[f.key]!,
      hintText: '',
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
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
