import 'package:flutter/material.dart';

import 'package:lynx_app/features/clients/presentation/clients_list_screen.dart';
import 'package:lynx_app/features/clients/providers/clients_provider.dart';
import 'package:lynx_app/features/exercises/presentation/exercise_library_screen.dart';
import 'package:lynx_app/features/exercises/providers/exercises_provider.dart';
import 'package:lynx_app/features/groups/presentation/groups_list_screen.dart';
import 'package:lynx_app/features/groups/providers/groups_provider.dart';
import 'package:lynx_app/features/review/presentation/review_screen.dart';
import 'package:lynx_app/features/review/providers/review_provider.dart';
import 'package:lynx_app/features/settings/presentation/settings_screen.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/main_shell.dart';

/// Tabs staff (owner/coach/physio) see: Clients · Library · Groups · Review · Settings.
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
          label: l.navLibrary,
          sfSymbol: 'square.stack',
          materialIcon: Icons.layers_outlined,
          screen: const ExerciseLibraryScreen(),
          refreshProviders: [exercisesProvider, exerciseTagsProvider],
        ),
        ShellTab(
          label: l.navGroups,
          sfSymbol: 'person.3',
          materialIcon: Icons.groups_outlined,
          screen: const GroupsListScreen(),
          refreshProviders: [groupsProvider],
        ),
        ShellTab(
          label: l.navReview,
          sfSymbol: 'checkmark.circle',
          materialIcon: Icons.check_circle_outline,
          screen: const ReviewScreen(),
          refreshProviders: [reviewFeedProvider],
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
