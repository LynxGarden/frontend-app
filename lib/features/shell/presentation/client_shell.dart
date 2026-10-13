import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/calendar/presentation/calendar_screen.dart';
import 'package:lynx_app/features/calendar/providers/calendar_providers.dart';
import 'package:lynx_app/features/chat/presentation/chat_list_screen.dart';
import 'package:lynx_app/features/chat/providers/chat_providers.dart';
import 'package:lynx_app/features/progress/presentation/progress_screen.dart';
import 'package:lynx_app/features/progress/providers/progress_provider.dart';
import 'package:lynx_app/features/settings/presentation/settings_screen.dart';
import 'package:lynx_app/features/training/presentation/train_screen.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/main_shell.dart';

/// Tabs a client sees: Train · Progress · Chat · Settings. The Chat tab carries
/// a red badge when there are unread messages from their coach.
class ClientShell extends ConsumerWidget {
  const ClientShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final unread = ref.watch(clientUnreadCountProvider).valueOrNull ?? 0;

    return MainShell(
      tabs: [
        ShellTab(
          label: l.navTrain,
          sfSymbol: 'figure.run',
          materialIcon: Icons.fitness_center,
          screen: const TrainScreen(),
        ),
        ShellTab(
          label: l.navProgress,
          sfSymbol: 'chart.line.uptrend.xyaxis',
          materialIcon: Icons.trending_up,
          screen: const ProgressScreen(),
          refreshProviders: [progressSummaryProvider, trackedExercisesProvider],
        ),
        ShellTab(
          label: l.navCalendar,
          sfSymbol: 'calendar',
          materialIcon: Icons.calendar_today,
          screen: const CalendarScreen(),
          refreshProviders: [
            tenantBookingsProvider,
            healthLogsProvider(null),
            remindersProvider,
          ],
        ),
        ShellTab(
          label: l.navChat,
          sfSymbol: 'bubble.left.and.bubble.right',
          materialIcon: Icons.chat_bubble_outline,
          showBadge: unread > 0,
          screen: const ChatListScreen(),
        ),
        ShellTab(
          label: l.navSettings,
          sfSymbol: 'gearshape',
          materialIcon: Icons.settings_outlined,
          screen: const SettingsScreen(),
        ),
      ],
    );
  }
}
