import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_chip.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';

/// The result of composing a reminder.
class ReminderDraft {
  const ReminderDraft(
      {required this.title, required this.type, required this.timeOfDay});
  final String title;
  final String type;
  final String timeOfDay; // 'HH:mm'
}

/// Bottom sheet to create a reminder. Returns a [ReminderDraft] or null.
Future<ReminderDraft?> showReminderSheet(BuildContext context) {
  return showModalBottomSheet<ReminderDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => const _ReminderSheet(),
  );
}

class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet();

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  final _title = TextEditingController();
  String _type = 'custom';
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _preset(String type, String title) {
    HapticFeedback.selectionClick();
    setState(() {
      _type = type;
      _title.text = title;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  String get _timeString =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
          Text(l.addReminder, style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppChip(
                label: l.reminderMeasureWeight,
                selected: _type == 'weight',
                onTap: () => _preset('weight', l.reminderMeasureWeight),
              ),
              AppChip(
                label: l.reminderDrinkWater,
                selected: _type == 'water',
                onTap: () => _preset('water', l.reminderDrinkWater),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: _title, label: l.reminderTitle),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: _pickTime,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l.reminderTime,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(_timeString,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l.save,
            isExpanded: true,
            onPressed: () {
              final title = _title.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(
                context,
                ReminderDraft(
                    title: title, type: _type, timeOfDay: _timeString),
              );
            },
          ),
        ],
      ),
    );
  }
}
