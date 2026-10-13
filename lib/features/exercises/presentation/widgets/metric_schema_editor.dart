import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/exercises/data/models/metric_field.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';

String _metricTypeLabel(AppLocalizations l, MetricFieldType t) {
  switch (t) {
    case MetricFieldType.number:
      return l.metricTypeNumber;
    case MetricFieldType.decimal:
      return l.metricTypeDecimal;
    case MetricFieldType.duration:
      return l.metricTypeDuration;
    case MetricFieldType.text:
      return l.metricTypeText;
    case MetricFieldType.enumChoice:
      return l.metricTypeEnum;
  }
}

/// Coach-side editor for an exercise's config-driven logging [MetricField] list.
/// Emits the edited list through [onChanged] on every mutation.
class MetricSchemaEditor extends StatefulWidget {
  const MetricSchemaEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final List<MetricField> initial;
  final ValueChanged<List<MetricField>> onChanged;

  @override
  State<MetricSchemaEditor> createState() => _MetricSchemaEditorState();
}

class _MetricSchemaEditorState extends State<MetricSchemaEditor> {
  late final List<MetricField> _fields = List.of(widget.initial);

  void _emit() => widget.onChanged(List.of(_fields));

  String _slug(String label, {String? exceptKey}) {
    var base = label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (base.isEmpty) base = 'field';
    var key = base;
    var n = 1;
    bool taken(String k) =>
        _fields.any((f) => f.key == k && f.key != exceptKey);
    while (taken(key)) {
      key = '${base}_$n';
      n++;
    }
    return key;
  }

  Future<void> _addOrEdit([int? index]) async {
    final existing = index == null ? null : _fields[index];
    final result = await _showFieldEditor(context, existing);
    if (result == null) return;
    final key = _slug(result.label, exceptKey: existing?.key);
    final field = result.copyWith(key: key);
    setState(() {
      if (index == null) {
        _fields.add(field);
      } else {
        _fields[index] = field;
      }
    });
    _emit();
  }

  void _remove(int index) {
    setState(() => _fields.removeAt(index));
    _emit();
  }

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _fields.length) return;
    setState(() {
      final f = _fields.removeAt(index);
      _fields.insert(target, f);
    });
    HapticFeedback.selectionClick();
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_fields.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              l.noLoggingFields,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiary),
            ),
          )
        else
          for (var i = 0; i < _fields.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _FieldRow(
                field: _fields[i],
                isFirst: i == 0,
                isLast: i == _fields.length - 1,
                onTap: () => _addOrEdit(i),
                onRemove: () => _remove(i),
                onUp: () => _move(i, -1),
                onDown: () => _move(i, 1),
              ),
            ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: l.addField,
          variant: AppButtonVariant.secondary,
          isExpanded: true,
          onPressed: () => _addOrEdit(),
        ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.onRemove,
    required this.onUp,
    required this.onDown,
  });

  final MetricField field;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bits = <String>[_metricTypeLabel(l, field.type)];
    if (field.enumKind != null) bits.add(field.enumKind!.toUpperCase());
    if (field.unit != null && field.unit!.trim().isNotEmpty) {
      bits.add(field.unit!.trim());
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field.label,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(bits.join(' · '),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            _iconBtn(Icons.keyboard_arrow_up, isFirst ? null : onUp),
            _iconBtn(Icons.keyboard_arrow_down, isLast ? null : onDown),
            _iconBtn(Icons.close, onRemove, tint: AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback? onTap, {Color? tint}) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(icon,
          size: 20,
          color: onTap == null
              ? AppColors.textTertiary.withValues(alpha: 0.4)
              : (tint ?? AppColors.textSecondary)),
    );
  }
}

/// A bottom sheet to create/edit a single [MetricField]. Returns the field (key
/// is derived by the caller) or null if cancelled.
Future<MetricField?> _showFieldEditor(
    BuildContext context, MetricField? initial) {
  return showModalBottomSheet<MetricField>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _FieldEditorSheet(initial: initial),
  );
}

class _FieldEditorSheet extends StatefulWidget {
  const _FieldEditorSheet({this.initial});
  final MetricField? initial;

  @override
  State<_FieldEditorSheet> createState() => _FieldEditorSheetState();
}

class _FieldEditorSheetState extends State<_FieldEditorSheet> {
  late final TextEditingController _label =
      TextEditingController(text: widget.initial?.label ?? '');
  late final TextEditingController _unit =
      TextEditingController(text: widget.initial?.unit ?? '');
  late final TextEditingController _options = TextEditingController(
      text: (widget.initial?.options ?? const []).join(', '));
  late MetricFieldType _type = widget.initial?.type ?? MetricFieldType.number;
  late String? _enumKind = widget.initial?.enumKind;

  @override
  void dispose() {
    _label.dispose();
    _unit.dispose();
    _options.dispose();
    super.dispose();
  }

  void _save() {
    final label = _label.text.trim();
    if (label.isEmpty) return;
    final options = _type == MetricFieldType.enumChoice
        ? _options.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : const <String>[];
    Navigator.of(context).pop(MetricField(
      key: widget.initial?.key ?? label,
      label: label,
      type: _type,
      unit: _type == MetricFieldType.number || _type == MetricFieldType.decimal
          ? _unit.text.trim()
          : null,
      enumKind: _enumKind,
      options: options,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final showUnit =
        _type == MetricFieldType.number || _type == MetricFieldType.decimal;
    final showOptions = _type == MetricFieldType.enumChoice;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l.fieldLabel,
            controller: _label,
            hintText: l.fieldLabelHint,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l.fieldType, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in MetricFieldType.values)
                _choice(
                  _metricTypeLabel(l, t),
                  selected: _type == t,
                  onTap: () => setState(() => _type = t),
                ),
            ],
          ),
          if (showUnit) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l.fieldUnit,
              controller: _unit,
              hintText: l.fieldUnitHint,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l.fieldIntensity, style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _choice(l.intensityNone,
                    selected: _enumKind == null,
                    onTap: () => setState(() => _enumKind = null)),
                for (final k in const ['rm', 'rpe', 'rir'])
                  _choice(k.toUpperCase(),
                      selected: _enumKind == k,
                      onTap: () => setState(() => _enumKind = k)),
              ],
            ),
          ],
          if (showOptions) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l.fieldOptions,
              controller: _options,
              hintText: l.fieldOptionsHint,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: l.save, isExpanded: true, onPressed: _save),
        ],
      ),
    );
  }

  Widget _choice(String label,
      {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
