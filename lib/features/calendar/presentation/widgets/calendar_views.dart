import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';

/// Whether a calendar renders a single week strip or a full month grid.
enum CalView { week, month }

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Monday of the week containing [d].
DateTime weekStartOf(DateTime d) {
  final day = dateOnly(d);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// A compact Week / Month segmented toggle. Mirrors the pill look used across
/// the app without pulling in the full segmented-control for just two options.
class CalendarViewToggle extends StatelessWidget {
  const CalendarViewToggle({
    super.key,
    required this.view,
    required this.onChanged,
    required this.weekLabel,
    required this.monthLabel,
  });

  final CalView view;
  final ValueChanged<CalView> onChanged;
  final String weekLabel;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(CalView.week, weekLabel),
          _seg(CalView.month, monthLabel),
        ],
      ),
    );
  }

  Widget _seg(CalView v, String label) {
    final selected = v == view;
    return GestureDetector(
      onTap: () {
        if (selected) return;
        HapticFeedback.selectionClick();
        onChanged(v);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.onPrimary : AppColors.textSecondary,
            )),
      ),
    );
  }
}

/// A navigable single-week strip: ‹  range  › above seven day cells. [markedDays]
/// (date-only) render a small dot under the number.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.weekStart,
    required this.selected,
    required this.onPick,
    required this.onPrev,
    required this.onNext,
    required this.locale,
    this.markedDays = const {},
  });

  final DateTime weekStart;
  final DateTime selected;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final String locale;
  final Set<DateTime> markedDays;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final md = DateFormat.MMMd(locale);
    final range = '${md.format(days.first)} – ${md.format(days.last)}';
    return Column(
      children: [
        _NavHeader(label: range, onPrev: onPrev, onNext: onNext),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final d in days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _DayCell(
                    day: d,
                    selected: dateOnly(d) == dateOnly(selected),
                    inFocus: true,
                    marked: markedDays.contains(dateOnly(d)),
                    locale: locale,
                    showDow: true,
                    onTap: () => onPick(d),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A full month grid: ‹  Month YYYY  › above weekday labels and six day rows.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.onPick,
    required this.onPrev,
    required this.onNext,
    required this.locale,
    this.markedDays = const {},
  });

  /// Any day within the focused month.
  final DateTime month;
  final DateTime selected;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final String locale;
  final Set<DateTime> markedDays;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final gridStart = weekStartOf(first); // Monday on/before the 1st
    final cells = List.generate(42, (i) => gridStart.add(Duration(days: i)));
    final dowFmt = DateFormat.E(locale);
    // Monday-first weekday labels.
    final labelDays =
        List.generate(7, (i) => DateTime(2024, 1, 1).add(Duration(days: i)));

    return Column(
      children: [
        _NavHeader(
          label: DateFormat.yMMMM(locale).format(first),
          onPrev: onPrev,
          onNext: onNext,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final d in labelDays)
              Expanded(
                child: Center(
                  child: Text(dowFmt.format(d).toUpperCase(),
                      style: AppTextStyles.label.copyWith(
                          fontSize: 10, color: AppColors.textTertiary)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var w = 0; w < 6; w++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _DayCell(
                        day: cells[w * 7 + i],
                        selected: dateOnly(cells[w * 7 + i]) ==
                            dateOnly(selected),
                        inFocus: cells[w * 7 + i].month == first.month,
                        marked:
                            markedDays.contains(dateOnly(cells[w * 7 + i])),
                        locale: locale,
                        showDow: false,
                        onTap: () => onPick(cells[w * 7 + i]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NavHeader extends StatelessWidget {
  const _NavHeader(
      {required this.label, required this.onPrev, required this.onNext});
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _arrow(Icons.chevron_left_rounded, onPrev),
        Text(label,
            style:
                AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        _arrow(Icons.chevron_right_rounded, onNext),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Icon(icon, size: 22, color: AppColors.textPrimary),
        ),
      );
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.inFocus,
    required this.marked,
    required this.locale,
    required this.showDow,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool inFocus;
  final bool marked;
  final String locale;
  final bool showDow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = dateOnly(day) == dateOnly(DateTime.now());
    final Color fg;
    if (selected) {
      fg = AppColors.onPrimary;
    } else if (!inFocus) {
      fg = AppColors.textTertiary.withValues(alpha: 0.5);
    } else {
      fg = AppColors.textPrimary;
    }

    final dotColor = selected ? AppColors.onPrimary : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: showDow ? 60 : 44,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: (!selected && isToday)
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showDow) ...[
              Text(DateFormat.E(locale).format(day).toUpperCase(),
                  style: AppTextStyles.label
                      .copyWith(fontSize: 10, color: fg)),
              const SizedBox(height: 2),
            ],
            Text('${day.day}',
                style: AppTextStyles.body.copyWith(
                    color: fg,
                    fontWeight:
                        selected || isToday ? FontWeight.w700 : FontWeight.w500)),
            const SizedBox(height: 3),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: marked ? dotColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
