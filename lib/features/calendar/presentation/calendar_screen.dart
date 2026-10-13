import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lynx_app/core/integrations/device_calendar_service.dart';
import 'package:lynx_app/core/integrations/health_sync_service.dart';
import 'package:lynx_app/core/integrations/local_notifications_service.dart';
import 'package:lynx_app/core/integrations/strava_service.dart';
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
import 'package:lynx_app/features/calendar/presentation/widgets/health_log_sheet.dart';
import 'package:lynx_app/features/calendar/presentation/widgets/reminder_sheet.dart';
import 'package:lynx_app/features/calendar/providers/calendar_providers.dart';
import 'package:lynx_app/features/training/providers/training_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/app_segmented_control.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/collapsing_header.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

enum _Tab { book, activity, history }

/// The client's Calendar tab: realtime slot booking, health/activity logging +
/// reminders, and finished-training history.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final _scroll = ScrollController();
  _Tab _tab = _Tab.book;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _weekStart {
    final now = _dateOnly(DateTime.now());
    return now.subtract(Duration(days: now.weekday - 1)); // Monday
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverCollapsingHeader(title: l.calendarTitle, controller: _scroll),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: AppSegmentedControl<_Tab>(
                segments: [
                  AppSegment(value: _Tab.book, label: l.calendarBook),
                  AppSegment(value: _Tab.activity, label: l.calendarActivity),
                  AppSegment(value: _Tab.history, label: l.calendarHistory),
                ],
                selected: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
            ),
            sliver: switch (_tab) {
              _Tab.book => _BookSliver(
                  weekStart: _weekStart,
                  selectedDay: _selectedDay,
                  onPickDay: (d) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDay = d);
                  },
                ),
              _Tab.activity => const _ActivitySliver(),
              _Tab.history => const _HistorySliver(),
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── Book ──────────

class _BookSliver extends ConsumerWidget {
  const _BookSliver({
    required this.weekStart,
    required this.selectedDay,
    required this.onPickDay,
  });

  final DateTime weekStart;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onPickDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final bookingsAsync = ref.watch(tenantBookingsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final locale = Localizations.localeOf(context).toString();

    return bookingsAsync.when(
      loading: () => const SliverToBoxAdapter(child: _SlotSkeleton()),
      error: (_, _) => SliverToBoxAdapter(
        child: _Empty(icon: Icons.wifi_off_rounded, text: l.noBookingThisWeek),
      ),
      data: (bookings) {
        final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
        final slots = _slotsFor(selectedDay, bookings, user?.personId);
        return SliverList.list(
          children: [
            _DayStrip(
              days: days,
              selected: selectedDay,
              onPick: onPickDay,
              locale: locale,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final slot in slots)
              _SlotTile(slot: slot, locale: locale),
          ],
        );
      },
    );
  }

  List<TimeSlot> _slotsFor(
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
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.days,
    required this.selected,
    required this.onPick,
    required this.locale,
  });

  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onPick;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final dow = DateFormat.E(locale);
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final d = days[i];
          final isSel = d == selected;
          final isPast = d.isBefore(today);
          final fg = isSel
              ? AppColors.onPrimary
              : (isPast ? AppColors.textTertiary : AppColors.textPrimary);
          return GestureDetector(
            onTap: () => onPick(d),
            child: Container(
              width: 52,
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dow.format(d).toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(color: fg)),
                  const SizedBox(height: 2),
                  Text('${d.day}',
                      style: AppTextStyles.body
                          .copyWith(color: fg, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

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

// ──────────────────────────────────────────────────────── Activity ─────────

class _ActivitySliver extends ConsumerWidget {
  const _ActivitySliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final logsAsync = ref.watch(healthLogsProvider(null));
    final reminders = ref.watch(remindersProvider);

    return SliverList.list(
      children: [
        // Import + add actions.
        Row(
          children: [
            Expanded(
              child: _ActionChip(
                icon: Icons.add,
                label: l.addLog,
                onTap: () => _addLog(context, ref),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionChip(
                icon: Icons.favorite_border,
                label: l.importFromHealth,
                onTap: () => _importHealth(context, ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActionChip(
          icon: Icons.directions_run,
          label: l.importFromStrava,
          onTap: () => _importStrava(context, ref),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l.healthLogs,
            style: AppTextStyles.label.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: AppSpacing.sm),
        logsAsync.when(
          loading: () => const _SlotSkeleton(),
          error: (_, _) => _Empty(icon: Icons.wifi_off_rounded, text: l.noLogsYet),
          data: (logs) => logs.isEmpty
              ? _Empty(icon: Icons.monitor_heart_outlined, text: l.noLogsYet)
              : Column(children: [for (final log in logs) _LogTile(log: log)]),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l.reminders,
                style: AppTextStyles.label
                    .copyWith(color: AppColors.textTertiary)),
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
              _Empty(icon: Icons.wifi_off_rounded, text: l.noReminders),
          data: (items) => items.isEmpty
              ? _Empty(icon: Icons.alarm, text: l.noReminders)
              : Column(
                  children: [
                    for (final r in items) _ReminderTile(reminder: r),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _addLog(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final input = await showHealthLogSheet(context);
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

  Future<void> _importHealth(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final count = await HealthSyncService.importAndSave(
        tenantId: user.tenantId, personId: user.personId);
    ref.invalidate(healthLogsProvider(null));
    if (context.mounted) {
      AppToast.show(context,
          title: count > 0 ? l.imported(count) : l.importUnavailable);
    }
  }

  Future<void> _importStrava(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    if (!StravaService.isConfigured) {
      AppToast.show(context, title: l.importUnavailable);
      return;
    }
    final connected = await StravaService.isConnected;
    if (!connected) {
      await StravaService.connect();
      return; // OAuth redirect completes the link out-of-band.
    }
    final count = await StravaService.importAndSave(
        tenantId: user.tenantId, personId: user.personId);
    ref.invalidate(healthLogsProvider(null));
    if (context.mounted) {
      AppToast.show(context,
          title: count > 0 ? l.imported(count) : l.importUnavailable);
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

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});
  final HealthLog log;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final when = DateFormat.MMMEd(locale).add_Hm().format(log.loggedAt);
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

// ───────────────────────────────────────────────────────── History ─────────

class _HistorySliver extends ConsumerWidget {
  const _HistorySliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final async = ref.watch(activeAssignmentProvider);

    return async.when(
      loading: () => const SliverToBoxAdapter(child: _SlotSkeleton()),
      error: (_, _) => SliverToBoxAdapter(
          child: _Empty(icon: Icons.wifi_off_rounded, text: l.noFinishedTrainings)),
      data: (assignment) {
        final done = [
          for (final s in (assignment?.sessions ?? const []))
            if (s.isCompleted) s,
        ]..sort((a, b) => b.lastCompletedAt!.compareTo(a.lastCompletedAt!));
        if (done.isEmpty) {
          return SliverToBoxAdapter(
            child: _Empty(
                icon: Icons.history, text: l.noFinishedTrainings),
          );
        }
        final fmt = DateFormat.MMMEd(locale).add_Hm();
        return SliverList.list(
          children: [
            for (final s in done)
              AppCard(
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.label,
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text(fmt.format(s.lastCompletedAt!),
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────── shared ───────────

class _ActionChip extends StatelessWidget {
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textTertiary),
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
          for (var i = 0; i < 6; i++)
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
