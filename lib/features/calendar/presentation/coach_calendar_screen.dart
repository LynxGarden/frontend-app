import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/calendar/data/models/booking.dart';
import 'package:lynx_app/features/calendar/presentation/widgets/calendar_views.dart';
import 'package:lynx_app/features/calendar/providers/calendar_providers.dart';
import 'package:lynx_app/features/clients/data/models/client.dart';
import 'package:lynx_app/features/clients/providers/clients_provider.dart';
import 'package:lynx_app/features/review/presentation/review_screen.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_avatar.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/collapsing_header.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// The coach's Schedule tab: a week/month calendar of the sessions assigned to
/// them (bookings where `coach_id` = this coach). Replaces the old Review tab in
/// the staff nav; Review is reachable from the header action here.
class CoachCalendarScreen extends ConsumerStatefulWidget {
  const CoachCalendarScreen({super.key});

  @override
  ConsumerState<CoachCalendarScreen> createState() =>
      _CoachCalendarScreenState();
}

class _CoachCalendarScreenState extends ConsumerState<CoachCalendarScreen> {
  final _scroll = ScrollController();
  CalView _calView = CalView.week;
  late DateTime _selectedDay;
  late DateTime _focusDate;

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final sessions = ref.watch(coachSessionsProvider);
    final bookingsLoading =
        ref.watch(tenantBookingsProvider).isLoading;
    final clientsAsync = ref.watch(clientsProvider);

    final marked = {for (final b in sessions) dateOnly(b.slotStart)};
    final forDay = [
      for (final b in sessions)
        if (dateOnly(b.slotStart) == _selectedDay) b,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverCollapsingHeader(
            title: l.coachCalendarTitle,
            controller: _scroll,
            action: _ReviewButton(label: l.navReview),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
            ),
            sliver: bookingsLoading
                ? const SliverToBoxAdapter(child: _SessionsSkeleton())
                : SliverList.list(
                    children: [
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
                      Text(
                        DateFormat.MMMMEEEEd(locale).format(_selectedDay),
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (forDay.isEmpty)
                        _Empty(
                          text: sessions.isEmpty
                              ? l.noSessionsScheduled
                              : l.noSessionsThisDay,
                        )
                      else
                        for (final b in forDay)
                          _SessionTile(
                            booking: b,
                            client: _clientFor(clientsAsync, b.personId),
                            locale: locale,
                          ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Client? _clientFor(AsyncValue<List<Client>> async, String personId) {
    final list = async.valueOrNull;
    if (list == null) return null;
    for (final c in list) {
      if (c.id == personId) return c;
    }
    return null;
  }
}

/// One scheduled session row: time, client avatar + name.
class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.booking,
    required this.client,
    required this.locale,
  });

  final Booking booking;
  final Client? client;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final time = DateFormat.Hm(locale);
    final label =
        '${time.format(booking.slotStart)}–${time.format(booking.slotEnd)}';
    final name = client?.fullName ?? l.sessionWithClient;

    return AppCard(
      child: Row(
        children: [
          if (client != null)
            AppAvatar(
              avatarKind: client!.avatarKind,
              avatarValue: client!.avatarValue,
              initials: client!.initials,
              radius: 20,
            )
          else
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surfaceLight,
              child: Icon(Icons.person_outline,
                  color: AppColors.textTertiary, size: 20),
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  const _ReviewButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReviewScreen()),
        );
      },
      icon: Icon(Icons.checklist_rounded, size: 18, color: AppColors.primary),
      label: Text(label, style: TextStyle(color: AppColors.primary)),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.event_available_outlined,
              size: 40, color: AppColors.textTertiary),
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

class _SessionsSkeleton extends StatelessWidget {
  const _SessionsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SkeletonBox(width: 140, height: 34, borderRadius: 99),
          ),
          const SizedBox(height: AppSpacing.md),
          SkeletonBox(
              width: double.infinity, height: 80, borderRadius: AppRadius.lg),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SkeletonBox(
                  width: double.infinity,
                  height: 64,
                  borderRadius: AppRadius.lg),
            ),
        ],
      ),
    );
  }
}
