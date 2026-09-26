import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/auth/presentation/finish_setup_screen.dart';
import 'package:lynx_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:lynx_app/features/shell/presentation/client_shell.dart';
import 'package:lynx_app/features/shell/presentation/staff_shell.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/skeleton_list.dart';

/// Entry after sign-in. Resolves the signed-in user's role and picks the shell:
/// staff → [StaffShell], client → [ClientShell]. Authenticated-but-unlinked →
/// [FinishSetupScreen]. Linked but not onboarded → [OnboardingScreen].
class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      skipLoadingOnReload: true, // keep the current screen while re-fetching
      loading: () => const ShellSkeleton(),
      error: (_, _) => const FinishSetupScreen(),
      data: (user) {
        if (user == null) return const FinishSetupScreen();
        if (!user.onboardingComplete) return const OnboardingScreen();
        return user.isStaff ? const StaffShell() : const ClientShell();
      },
    );
  }
}
