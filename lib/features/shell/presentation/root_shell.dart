import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/features/auth/presentation/finish_setup_screen.dart';
import 'package:lynx_app/features/shell/presentation/client_shell.dart';
import 'package:lynx_app/features/shell/presentation/staff_shell.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// Entry after sign-in. Resolves the signed-in user's role and picks the shell:
/// staff → [StaffShell], client → [ClientShell]. Authenticated-but-unlinked →
/// [FinishSetupScreen].
class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.forest)),
      ),
      error: (_, _) => const FinishSetupScreen(),
      data: (user) {
        if (user == null) return const FinishSetupScreen();
        return user.isStaff ? const StaffShell() : const ClientShell();
      },
    );
  }
}
