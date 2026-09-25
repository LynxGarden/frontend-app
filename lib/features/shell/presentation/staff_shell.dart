import 'package:flutter/material.dart';

import 'package:lynx_app/features/clients/presentation/clients_list_screen.dart';
import 'package:lynx_app/features/exercises/presentation/exercise_library_screen.dart';
import 'package:lynx_app/features/groups/presentation/groups_list_screen.dart';
import 'package:lynx_app/features/profile/presentation/profile_screen.dart';
import 'package:lynx_app/features/review/presentation/review_screen.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/main_shell.dart';

/// Tabs staff (owner/coach/physio) see: Clients · Library · Groups · Review · Profile.
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
        ),
        ShellTab(
          label: l.navLibrary,
          sfSymbol: 'square.stack',
          materialIcon: Icons.layers_outlined,
          screen: const ExerciseLibraryScreen(),
        ),
        ShellTab(
          label: l.navGroups,
          sfSymbol: 'person.3',
          materialIcon: Icons.groups_outlined,
          screen: const GroupsListScreen(),
        ),
        ShellTab(
          label: l.navReview,
          sfSymbol: 'checkmark.circle',
          materialIcon: Icons.check_circle_outline,
          screen: const ReviewScreen(),
        ),
        ShellTab(
          label: l.navProfile,
          sfSymbol: 'person',
          materialIcon: Icons.person_outline,
          screen: const ProfileScreen(),
        ),
      ],
    );
  }
}
