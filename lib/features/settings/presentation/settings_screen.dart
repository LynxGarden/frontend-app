import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.heading3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => context.push('/settings/change-password'),
          ),

          // TODO: Add more settings tiles as needed.
          // _SettingsTile(
          //   icon: Icons.person_outline,
          //   title: 'Profile',
          //   onTap: () => context.push('/settings/profile'),
          // ),
          // _SettingsTile(
          //   icon: Icons.notifications_outlined,
          //   title: 'Notifications',
          //   onTap: () => context.push('/settings/notifications'),
          // ),

          const SizedBox(height: AppSpacing.xxl),

          AppButton(
            label: 'Log Out',
            variant: AppButtonVariant.secondary,
            isExpanded: true,
            onPressed: () async {
              await SupabaseClientWrapper.auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),

          const SizedBox(height: AppSpacing.md),

          AppButton(
            label: 'Delete Account',
            variant: AppButtonVariant.ghost,
            onPressed: () {
              // TODO: Implement account deletion with confirmation dialog.
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: Text('Delete Account', style: AppTextStyles.heading3),
                  content: Text(
                    'Are you sure? This action cannot be undone.',
                    style: AppTextStyles.body,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Call Supabase edge function to delete user data,
                        // then sign out.
                        Navigator.pop(ctx);
                      },
                      child: Text('Delete', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(title, style: AppTextStyles.body),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
