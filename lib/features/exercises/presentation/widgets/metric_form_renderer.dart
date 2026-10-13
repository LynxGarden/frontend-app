import 'package:flutter/material.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/exercises/data/models/metric_field.dart';

/// Renders a config-driven logging form from an exercise's [schema], emitting a
/// value per field key via [onChanged]. Pure UI — no DB. Reused by the client
/// runner (and anywhere a schema needs to be filled in).
///
/// When [schema] is empty it falls back to the legacy Reps + Weight(kg) pair so
/// exercises saved before custom schemas still log sensibly.
class MetricFormRenderer extends StatefulWidget {
  const MetricFormRenderer({
    super.key,
    required this.schema,
    required this.values,
    required this.onChanged,
    this.lastValues,
  });

  final List<MetricField> schema;
  final Map<String, dynamic> values;
  final void Function(String key, dynamic value) onChanged;

  /// Previous occasion's values, shown as faint hints to minimise taps.
  final Map<String, dynamic>? lastValues;

  @override
  State<MetricFormRenderer> createState() => _MetricFormRendererState();
}

class _MetricFormRendererState extends State<MetricFormRenderer> {
  final Map<String, TextEditingController> _controllers = {};

  List<MetricField> get _effectiveSchema =>
      widget.schema.isEmpty ? MetricField.strengthDefault : widget.schema;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant MetricFormRenderer old) {
    super.didUpdateWidget(old);
    _syncControllers();
  }

  void _syncControllers() {
    for (final f in _effectiveSchema) {
      if (f.type == MetricFieldType.enumChoice) continue;
      final existing = _controllers[f.key];
      final text = _displayText(f, widget.values[f.key]);
      if (existing == null) {
        _controllers[f.key] = TextEditingController(text: text);
      } else if (existing.text != text &&
          !existing.selection.isValid) {
        existing.text = text;
      }
    }
  }

  String _displayText(MetricField f, dynamic value) {
    if (value == null) return '';
    if (f.type == MetricFieldType.duration && value is num) {
      return _formatDuration(value.toInt());
    }
    return '$value';
  }

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static int? _parseDuration(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.contains(':')) {
      final parts = t.split(':');
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      return m * 60 + s;
    }
    return int.tryParse(t);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _suffix(MetricField f) {
    if (f.enumKind != null) return f.enumKind!.toUpperCase();
    if (f.unit != null && f.unit!.trim().isNotEmpty) return f.unit!.trim();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final fields = _effectiveSchema;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _buildField(fields[i]),
        ],
      ],
    );
  }

  Widget _buildField(MetricField f) {
    switch (f.type) {
      case MetricFieldType.enumChoice:
        return _enumField(f);
      case MetricFieldType.text:
        return _textField(f, keyboard: TextInputType.text);
      case MetricFieldType.duration:
        return _durationField(f);
      case MetricFieldType.number:
        return _textField(f,
            keyboard: TextInputType.number, numeric: true, decimal: false);
      case MetricFieldType.decimal:
        return _textField(f,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
            numeric: true,
            decimal: true);
    }
  }

  Widget _label(MetricField f) => Text(
        f.label,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      );

  InputDecoration _decoration(MetricField f) {
    final suffix = _suffix(f);
    final last = widget.lastValues?[f.key];
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.surfaceLight,
      hintText: last == null ? null : _displayText(f, last),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
      suffixText: suffix,
      suffixStyle:
          AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
        borderSide: BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _textField(MetricField f,
      {required TextInputType keyboard,
      bool numeric = false,
      bool decimal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(f),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _controllers[f.key],
          keyboardType: keyboard,
          cursorColor: AppColors.primary,
          style: AppTextStyles.body,
          decoration: _decoration(f),
          onChanged: (v) {
            final t = v.trim();
            if (!numeric) {
              widget.onChanged(f.key, t.isEmpty ? null : t);
            } else if (decimal) {
              widget.onChanged(f.key, t.isEmpty ? null : double.tryParse(t));
            } else {
              widget.onChanged(f.key, t.isEmpty ? null : int.tryParse(t));
            }
          },
        ),
      ],
    );
  }

  Widget _durationField(MetricField f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(f),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _controllers[f.key],
          keyboardType: TextInputType.datetime,
          cursorColor: AppColors.primary,
          style: AppTextStyles.body,
          decoration: _decoration(f).copyWith(hintText: 'mm:ss'),
          onChanged: (v) => widget.onChanged(f.key, _parseDuration(v)),
        ),
      ],
    );
  }

  Widget _enumField(MetricField f) {
    final selected = widget.values[f.key] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(f),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final opt in f.options)
              GestureDetector(
                onTap: () => widget.onChanged(f.key, opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: selected == opt
                        ? AppColors.primary
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                        color: selected == opt
                            ? AppColors.primary
                            : AppColors.surfaceBorder),
                  ),
                  child: Text(
                    opt,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: selected == opt
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
