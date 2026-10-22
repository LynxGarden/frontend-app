import 'package:flutter/material.dart';

import 'package:lynx_app/features/calendar/presentation/coach_calendar_screen.dart';
import 'package:lynx_app/features/clients/presentation/clients_list_screen.dart';
import 'package:lynx_app/features/clients/providers/clients_provider.dart';
import 'package:lynx_app/features/groups/presentation/groups_list_screen.dart';
import 'package:lynx_app/features/groups/providers/groups_provider.dart';
import 'package:lynx_app/features/programs/presentation/program_list_screen.dart';
import 'package:lynx_app/features/programs/providers/programs_provider.dart';
import 'package:lynx_app/features/settings/presentation/settings_screen.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/main_shell.dart';

/// Tabs staff (owner/coach/physio) see: Clients · Programs · Groups · Schedule ·
/// Settings. Review lives behind the Schedule header's Review action.
class StaffShell extends StatelessWidget {
  const StaffShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return MainShell(
      tabs: [
        ShellTab(
          label: l.navClients,
          sfSymbol: 'person.2',
          materialIcon: Icons.people_outline,
          screen: const ClientsListScreen(),
          refreshProviders: [clientsProvider],
        ),
        ShellTab(
          label: l.navPrograms,
          sfSymbol: 'square.stack.3d.up',
          materialIcon: Icons.dashboard_outlined,
          screen: const ProgramListScreen(),
          refreshProviders: [programTemplatesProvider],
        ),
        ShellTab(
          label: l.navGroups,
          sfSymbol: 'person.3',
          materialIcon: Icons.groups_outlined,
          screen: const GroupsListScreen(),
          refreshProviders: [groupsProvider],
        ),
        ShellTab(
          label: l.navCalendar,
          sfSymbol: 'calendar',
          materialIcon: Icons.calendar_today_outlined,
          screen: const CoachCalendarScreen(),
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
