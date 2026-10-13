import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/calendar/data/health_repository.dart';
import 'package:lynx_app/features/calendar/data/models/health_log.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_chip.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';

/// Bottom sheet to log a health datum manually. Returns a [HealthLogInput] or
/// null if dismissed.
Future<HealthLogInput?> showHealthLogSheet(BuildContext context) {
  return showModalBottomSheet<HealthLogInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => const _HealthLogSheet(),
  );
}

class _HealthLogSheet extends StatefulWidget {
  const _HealthLogSheet();

  @override
  State<_HealthLogSheet> createState() => _HealthLogSheetState();
}

class _HealthLogSheetState extends State<_HealthLogSheet> {
  HealthLogType _type = HealthLogType.weight;
  final _value = TextEditingController();
  final _unit = TextEditingController(text: 'kg');
  final _notes = TextEditingController();

  static const _units = {
    HealthLogType.weight: 'kg',
    HealthLogType.water: 'L',
    HealthLogType.sleep: 'min',
    HealthLogType.activity: 'min',
    HealthLogType.meal: 'kcal',
    HealthLogType.other: '',
  };

  @override
  void dispose() {
    _value.dispose();
    _unit.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _pick(HealthLogType t) {
    HapticFeedback.selectionClick();
    setState(() {
      _type = t;
      _unit.text = _units[t] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final types = [
      (HealthLogType.weight, l.logWeight),
      (HealthLogType.water, l.logWater),
      (HealthLogType.sleep, l.logSleep),
      (HealthLogType.activity, l.logActivity),
      (HealthLogType.meal, l.logMeal),
    ];
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
          Text(l.addLog, style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in types)
                AppChip(
                  label: t.$2,
                  selected: _type == t.$1,
                  onTap: () => _pick(t.$1),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: _value,
                  label: l.logValue,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(controller: _unit, label: l.fieldUnit),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(controller: _notes, label: l.logNotes),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l.save,
            isExpanded: true,
            onPressed: () {
              final v = num.tryParse(_value.text.trim().replaceAll(',', '.'));
              Navigator.pop(
                context,
                HealthLogInput(
                  type: _type,
                  source: HealthLogSource.manual,
                  value: v,
                  unit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
                  notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
