import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/features/auth/data/auth_repository.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';

/// Shown when a user is authenticated but their auth account isn't linked to a
/// `person` (tenant) yet — e.g. a fresh SSO sign-in awaiting an invite link.
class FinishSetupScreen extends ConsumerWidget {
  const FinishSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l.finishSetupTitle, style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.md),
              Text(
                l.finishSetupBody,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: l.logout,
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  await AuthRepository.signOut();
                  ref.invalidate(currentUserProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
