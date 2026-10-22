import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lynx_app/core/integrations/device_calendar_service.dart';
import 'package:lynx_app/core/integrations/local_notifications_service.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/calendar/data/booking_repository.dart';
import 'package:lynx_app/features/calendar/data/health_repository.dart';
import 'package:lynx_app/features/calendar/data/models/booking.dart';
import 'package:lynx_app/features/calendar/data/models/health_log.dart';
import 'package:lynx_app/features/calendar/data/models/reminder.dart';
import 'package:lynx_app/features/calendar/data/reminder_repository.dart';
import 'package:lynx_app/features/calendar/presentation/widgets/calendar_views.dart';
import 'package:lynx_app/features/calendar/presentation/widgets/health_log_sheet.dart';
import 'package:lynx_app/features/calendar/presentation/widgets/reminder_sheet.dart';
import 'package:lynx_app/features/calendar/providers/calendar_providers.dart';
import 'package:lynx_app/features/training/providers/training_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/collapsing_header.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// The client's Calendar tab: one big week/month calendar. Tapping a day opens a
/// detail with its training slots (bookable only for the current week), that
/// day's health logs, finished trainings, plus quick-add actions (activity,
/// meal, water, reminder). Reminders are listed globally at the bottom.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final _scroll = ScrollController();
  CalView _calView = CalView.week;
  late DateTime _selectedDay;
  late DateTime _focusDate; // any day in the focused week/month

  @override
  void initState() {
    super.initState();
    _selectedDay = dateOnly(DateTime.now());
    _focusDate = _selectedDay;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _pickDay(DateTime d) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDay = dateOnly(d);
      _focusDate = _selectedDay;
    });
  }

  void _shiftFocus(int units) {
    HapticFeedback.selectionClick();
    setState(() {
      _focusDate = _calView == CalView.week
          ? _focusDate.add(Duration(days: 7 * units))
          : DateTime(_focusDate.year, _focusDate.month + units, 1);
    });
  }

  /// Booking is offered only for days in the current calendar week.
  bool _isBookable(DateTime day) {
    final ws = weekStartOf(DateTime.now());
    final we = ws.add(const Duration(days: 7));
    final d = dateOnly(day);
    return !d.isBefore(ws) && d.isBefore(we);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final user = ref.watch(currentUserProvider).valueOrNull;

    final bookingsState = ref.watch(tenantBookingsProvider);
    final bookings = bookingsState.valueOrNull ?? const <Booking>[];
    final logs = ref.watch(healthLogsProvider(null)).valueOrNull ??
        const <HealthLog>[];
    final assignment = ref.watch(activeAssignmentProvider).valueOrNull;
    final completed = [
      for (final s in (assignment?.sessions ?? const []))
        if (s.isCompleted && s.lastCompletedAt != null) s,
    ];
    final reminders = ref.watch(remindersProvider);

    // Days that carry something → a dot in the grid.
    final marked = <DateTime>{
      for (final b in bookings)
        if (b.isBooked && b.personId == user?.personId)
          dateOnly(b.slotStart),
      for (final log in logs) dateOnly(log.loggedAt),
      for (final s in completed) dateOnly(s.lastCompletedAt!),
    };

    final dayLogs = [
      for (final log in logs)
        if (dateOnly(log.loggedAt) == _selectedDay) log,
    ];
    final dayCompleted = [
      for (final s in completed)
        if (dateOnly(s.lastCompletedAt!) == _selectedDay) s,
    ];
    final daySlots = _isBookable(_selectedDay)
        ? _slotsForDay(_selectedDay, bookings, user?.personId)
        : const <TimeSlot>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverCollapsingHeader(title: l.calendarTitle, controller: _scroll),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
            ),
            sliver: SliverList.list(
              children: [
                // ── Calendar ──────────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: CalendarViewToggle(
                    view: _calView,
                    onChanged: (v) => setState(() => _calView = v),
                    weekLabel: l.calendarWeek,
                    monthLabel: l.calendarMonth,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_calView == CalView.week)
                  WeekStrip(
                    weekStart: weekStartOf(_focusDate),
                    selected: _selectedDay,
                    onPick: _pickDay,
                    onPrev: () => _shiftFocus(-1),
                    onNext: () => _shiftFocus(1),
                    locale: locale,
                    markedDays: marked,
                  )
                else
                  MonthGrid(
                    month: _focusDate,
                    selected: _selectedDay,
                    onPick: _pickDay,
                    onPrev: () => _shiftFocus(-1),
                    onNext: () => _shiftFocus(1),
                    locale: locale,
                    markedDays: marked,
                  ),
                const SizedBox(height: AppSpacing.lg),
                Divider(color: AppColors.surfaceBorder, height: 1),
                const SizedBox(height: AppSpacing.lg),

                // ── Selected day ─────────────────────────────────────────
                Text(DateFormat.MMMMEEEEd(locale).format(_selectedDay),
                    style: AppTextStyles.heading3),
                const SizedBox(height: AppSpacing.md),
                _QuickActions(
                  onActivity: () =>
                      _addLog(context, ref, HealthLogType.activity),
                  onMeal: () => _addLog(context, ref, HealthLogType.meal),
                  onWater: () => _addLog(context, ref, HealthLogType.water),
                  onReminder: () => _addReminder(context, ref),
                ),
                const SizedBox(height: AppSpacing.lg),

                if (bookingsState.isLoading)
                  const _SlotSkeleton()
                else ...[
                  // Booking (current week only).
                  if (_isBookable(_selectedDay)) ...[
                    _SectionLabel(l.bookTraining),
                    const SizedBox(height: AppSpacing.sm),
                    for (final slot in daySlots)
                      _SlotTile(slot: slot, locale: locale),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Finished trainings this day.
                  if (dayCompleted.isNotEmpty) ...[
                    _SectionLabel(l.finishedTrainings),
                    const SizedBox(height: AppSpacing.sm),
                    for (final s in dayCompleted)
                      AppCard(
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.success),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(s.label,
                                  style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600)),
                            ),
                            Text(DateFormat.Hm(locale).format(s.lastCompletedAt!),
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Health logs this day.
                  _SectionLabel(l.healthLogs),
                  const SizedBox(height: AppSpacing.sm),
                  if (dayLogs.isEmpty)
                    _Empty(
                        icon: Icons.monitor_heart_outlined, text: l.noLogsYet)
                  else
                    for (final log in dayLogs) _LogTile(log: log),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Reminders (global) ───────────────────────────────────
                Divider(color: AppColors.surfaceBorder, height: 1),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionLabel(l.reminders),
                    TextButton.icon(
                      onPressed: () => _addReminder(context, ref),
                      icon: Icon(Icons.add, size: 18, color: AppColors.primary),
                      label: Text(l.addReminder,
                          style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
                reminders.when(
                  loading: () => const _SlotSkeleton(),
                  error: (_, _) =>
                      _Empty(icon: Icons.alarm, text: l.noReminders),
                  data: (items) => items.isEmpty
                      ? _Empty(icon: Icons.alarm, text: l.noReminders)
                      : Column(
                          children: [
                            for (final r in items) _ReminderTile(reminder: r),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TimeSlot> _slotsForDay(
      DateTime day, List<Booking> all, String? myPersonId) {
    final result = <TimeSlot>[];
    for (var h = BookingRepository.firstHour;
        h <= BookingRepository.lastHour;
        h++) {
      final start = DateTime(day.year, day.month, day.day, h);
      final onSlot = all
          .where((b) => b.isBooked && b.slotStart.isAtSameMomentAs(start))
          .toList();
      Booking? mine;
      for (final b in onSlot) {
        if (b.personId == myPersonId) mine = b;
      }
      result.add(TimeSlot(
        start: start,
        bookedCount: onSlot.length,
        capacity: BookingRepository.slotCapacity,
        myBooking: mine,
      ));
    }
    return result;
  }

  Future<void> _addLog(
      BuildContext context, WidgetRef ref, HealthLogType type) async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    // Stamp the log at noon on the selected day so it lands on that date.
    final at = DateTime(
        _selectedDay.year, _selectedDay.month, _selectedDay.day, 12);
    final input =
        await showHealthLogSheet(context, initialType: type, loggedAt: at);
    if (input == null) return;
    try {
      await HealthRepository.add(
          tenantId: user.tenantId, personId: user.personId, input: input);
      ref.invalidate(healthLogsProvider(null));
      if (context.mounted) AppToast.show(context, title: l.logSaved);
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message);
    }
  }

  Future<void> _addReminder(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final result = await showReminderSheet(context);
    if (result == null) return;
    try {
      await ReminderRepository.create(
        tenantId: user.tenantId,
        personId: user.personId,
        title: result.title,
        type: result.type,
        timeOfDay: result.timeOfDay,
      );
      ref.invalidate(remindersProvider);
      if (context.mounted) AppToast.show(context, title: l.logSaved);
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message);
    }
  }
}

// ─────────────────────────────────────────────────── Quick actions ──────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onActivity,
    required this.onMeal,
    required this.onWater,
    required this.onReminder,
  });

  final VoidCallback onActivity;
  final VoidCallback onMeal;
  final VoidCallback onWater;
  final VoidCallback onReminder;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _QuickAction(
            icon: Icons.directions_run, label: l.logActivity, onTap: onActivity),
        _QuickAction(
            icon: Icons.restaurant_outlined, label: l.logMeal, onTap: onMeal),
        _QuickAction(
            icon: Icons.water_drop_outlined, label: l.logWater, onTap: onWater),
        _QuickAction(
            icon: Icons.alarm_add_outlined,
            label: l.addReminder,
            onTap: onReminder),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTextStyles.label.copyWith(color: AppColors.textTertiary));
  }
}

// ───────────────────────────────────────────────────────── Slot tile ────────

class _SlotTile extends ConsumerStatefulWidget {
  const _SlotTile({required this.slot, required this.locale});
  final TimeSlot slot;
  final String locale;

  @override
  ConsumerState<_SlotTile> createState() => _SlotTileState();
}

class _SlotTileState extends ConsumerState<_SlotTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final slot = widget.slot;
    final time = DateFormat.Hm(widget.locale);
    final label = '${time.format(slot.start)}–${time.format(slot.end)}';
    final disabled = slot.isPast || (slot.isFull && !slot.isMine);

    Color accent;
    String status;
    if (slot.isMine) {
      accent = AppColors.success;
      status = l.bookedLabel;
    } else if (slot.isFull) {
      accent = AppColors.textTertiary;
      status = l.slotFull;
    } else {
      accent = AppColors.primary;
      status = l.placesLeft(slot.remaining);
    }

    return AppCard(
      onTap: _busy || (disabled && !slot.isMine) ? null : _onTap,
      child: Opacity(
        opacity: disabled && !slot.isMine ? 0.55 : 1,
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(status,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (_busy)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            else if (slot.isMine)
              Icon(Icons.check_circle_rounded, color: AppColors.success)
            else if (!disabled)
              Icon(Icons.add_circle_outline, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap() async {
    final slot = widget.slot;
    if (slot.isMine) {
      await _showMine();
    } else {
      await _confirmBook();
    }
  }

  Future<void> _confirmBook() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l.bookConfirmTitle, style: AppTextStyles.heading3),
        content: Text(l.bookConfirmBody, style: AppTextStyles.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel,
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.book, style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (ok != true) return;
    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    try {
      await BookingRepository.book(widget.slot.start);
      if (mounted) AppToast.show(context, title: l.bookingConfirmed);
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showMine() async {
    final l = AppLocalizations.of(context);
    final slot = widget.slot;
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: Icon(Icons.event_available, color: AppColors.primary),
              title: Text(l.addToCalendar, style: AppTextStyles.body),
              onTap: () => Navigator.pop(ctx, 'calendar'),
            ),
            if (slot.canCancel)
              ListTile(
                leading: Icon(Icons.cancel_outlined, color: AppColors.error),
                title: Text(l.cancelBooking,
                    style: AppTextStyles.body.copyWith(color: AppColors.error)),
                onTap: () => Navigator.pop(ctx, 'cancel'),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'calendar') {
      final ok = await DeviceCalendarService.addEvent(
        title: l.bookTraining,
        start: slot.start,
        end: slot.end,
      );
      if (mounted && ok) AppToast.show(context, title: l.addedToCalendar);
    } else if (action == 'cancel') {
      setState(() => _busy = true);
      try {
        await BookingRepository.cancel(slot.myBooking!.id);
        if (mounted) AppToast.show(context, title: l.bookingCancelled);
      } on AppException catch (e) {
        if (mounted) AppToast.show(context, title: e.message);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }
}

// ───────────────────────────────────────────────────────── Log tile ─────────

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});
  final HealthLog log;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final when = DateFormat.Hm(locale).format(log.loggedAt);
    final value =
        log.value == null ? '' : '${_trim(log.value!)} ${log.unit ?? ''}'.trim();
    return AppCard(
      child: Row(
        children: [
          Icon(_icon(log.type), color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_typeLabel(l, log.type),
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(when,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          if (value.isNotEmpty)
            Text(value,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  static String _trim(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  IconData _icon(HealthLogType t) => switch (t) {
        HealthLogType.sleep => Icons.bedtime_outlined,
        HealthLogType.meal => Icons.restaurant_outlined,
        HealthLogType.activity => Icons.directions_run,
        HealthLogType.weight => Icons.monitor_weight_outlined,
        HealthLogType.water => Icons.water_drop_outlined,
        HealthLogType.other => Icons.circle_outlined,
      };
}

String _typeLabel(AppLocalizations l, HealthLogType t) => switch (t) {
      HealthLogType.sleep => l.logSleep,
      HealthLogType.meal => l.logMeal,
      HealthLogType.activity => l.logActivity,
      HealthLogType.weight => l.logWeight,
      HealthLogType.water => l.logWater,
      HealthLogType.other => l.logActivity,
    };

// ─────────────────────────────────────────────────────── Reminder tile ──────

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.reminder});
  final Reminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.alarm, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                if (reminder.timeOfDay != null)
                  Text(reminder.timeOfDay!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          Switch(
            value: reminder.enabled,
            activeThumbColor: AppColors.primary,
            onChanged: user == null
                ? null
                : (v) => _toggle(context, ref, user.tenantId, v),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(
      BuildContext context, WidgetRef ref, String tenantId, bool enabled) async {
    HapticFeedback.selectionClick();
    final base = reminder.id.hashCode.abs() % 100000;
    try {
      await ReminderRepository.setEnabled(
          tenantId: tenantId, id: reminder.id, enabled: enabled);
      if (enabled) {
        final ok = await LocalNotificationsService.requestPermission();
        final parts = (reminder.timeOfDay ?? '09:00').split(':');
        if (ok) {
          await LocalNotificationsService.scheduleDaily(
            baseId: base,
            title: reminder.title,
            body: reminder.title,
            hour: int.tryParse(parts.first) ?? 9,
            minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
            days: reminder.days,
          );
        }
      } else {
        await LocalNotificationsService.cancelReminder(base);
      }
      ref.invalidate(remindersProvider);
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message);
    }
  }
}

// ──────────────────────────────────────────────────────────── shared ────────

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.sm),
          Text(text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SlotSkeleton extends StatelessWidget {
  const _SlotSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SkeletonBox(
                  width: double.infinity, height: 64, borderRadius: AppRadius.lg),
            ),
        ],
      ),
    );
  }
}
