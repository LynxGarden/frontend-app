import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/features/auth/presentation/finish_setup_screen.dart';
import 'package:lynx_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:lynx_app/features/shell/presentation/client_shell.dart';
import 'package:lynx_app/features/shell/presentation/staff_shell.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/skeleton_list.dart';

/// Entry after sign-in. Resolves the signed-in user's role and picks the shell:
/// staff → [StaffShell], client → [ClientShell]. Authenticated-but-unlinked →
/// [FinishSetupScreen]. Linked but not onboarded → [OnboardingScreen].
///
/// The shell must never render for the *wrong* role — a client must not glimpse
/// the staff shell (the "New client" button) while their role loads. So we show a
/// full-page [ShellSkeleton] whenever role data isn't ready, **including** when a
/// cached user from a previous session belongs to a different auth account (an
/// account switch mid-reload). A same-user refetch (e.g. an avatar change) keeps
/// the current shell — no skeleton flash — because its `authUserId` still matches.
class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final sessionUserId = SupabaseClientWrapper.auth.currentUser?.id;
    final user = userAsync.valueOrNull;

    // The cached value belongs to a different auth session than the one that's
    // now signed in — treat it as not-yet-loaded so the wrong shell can't show.
    final identityMismatch = user != null &&
        sessionUserId != null &&
        user.authUserId != sessionUserId;

    if (identityMismatch || (userAsync.isLoading && user == null)) {
      return const ShellSkeleton();
    }
    if (user == null) return const FinishSetupScreen();
    if (!user.onboardingComplete) return const OnboardingScreen();
    return user.isStaff ? const StaffShell() : const ClientShell();
  }
}
