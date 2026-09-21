import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/features/auth/data/auth_repository.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/models/app_user.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _roleLabel(AppRole role) {
    switch (role) {
      case AppRole.owner:
        return 'Owner';
      case AppRole.coach:
        return 'Coach';
      case AppRole.physio:
        return 'Physio';
      case AppRole.client:
        return 'Client';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.profileTitle, style: AppTextStyles.heading3)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (user != null) ...[
              _InfoRow(label: l.emailLabel, value: user.email ?? '—'),
              _InfoRow(label: 'Role', value: _roleLabel(user.primaryRole)),
              _InfoRow(
                label: l.language,
                value: user.locale == 'sl'
                    ? l.languageSlovenian
                    : l.languageEnglish,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l.logout,
              variant: AppButtonVariant.secondary,
              isExpanded: true,
              onPressed: () async {
                await AuthRepository.signOut();
                ref.invalidate(currentUserProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
