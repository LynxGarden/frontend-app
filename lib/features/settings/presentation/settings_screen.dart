import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/settings/data/account_repository.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/data/session_service.dart';
import 'package:lynx_app/shared/models/app_user.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/providers/locale_provider.dart';
import 'package:lynx_app/shared/providers/theme_mode_provider.dart';
import 'package:lynx_app/shared/widgets/app_avatar.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/collapsing_header.dart';

/// Settings: profile info, language, security, and account actions.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _scroll = ScrollController();
  bool _busy = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _roleLabel(AppLocalizations l, AppRole role) {
    switch (role) {
      case AppRole.owner:
        return l.roleOwner;
      case AppRole.coach:
        return l.roleCoach;
      case AppRole.physio:
        return l.rolePhysio;
      case AppRole.client:
        return l.roleClient;
    }
  }

  String _languageLabel(AppLocalizations l, String code) =>
      code == 'sl' ? l.languageSlovenian : l.languageEnglish;

  Future<void> _pickLanguage() async {
    final l = AppLocalizations.of(context);
    final current = ref.read(localeProvider)?.languageCode ??
        Localizations.localeOf(context).languageCode;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(l.language, style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.sm),
            for (final code in const ['en', 'sl'])
              ListTile(
                title: Text(_languageLabel(l, code), style: AppTextStyles.body),
                trailing: code == current
                    ? Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(code),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (selected != null && selected != current) {
      HapticFeedback.selectionClick();
      await ref.read(localeProvider.notifier).setLocale(Locale(selected));
    }
  }

  String _themeLabel(AppLocalizations l, ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return l.themeLight;
      case ThemeMode.dark:
        return l.themeDark;
      case ThemeMode.system:
        return l.themeSystem;
    }
  }

  Future<void> _pickTheme() async {
    final l = AppLocalizations.of(context);
    final current = ref.read(themeModeProvider);

    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(l.appearance, style: AppTextStyles.heading3),
            const SizedBox(height: AppSpacing.sm),
            for (final m in ThemeMode.values)
              ListTile(
                title: Text(_themeLabel(l, m), style: AppTextStyles.body),
                trailing: m == current
                    ? Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(m),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (selected != null && selected != current) {
      HapticFeedback.selectionClick();
      await ref.read(themeModeProvider.notifier).setMode(selected);
    }
  }

  Future<void> _confirmLogout() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l.logoutTitle, style: AppTextStyles.heading3),
        content: Text(l.logoutBody, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.logout,
                style: AppTextStyles.body.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _logout();
  }

  Future<void> _logout() async {
    // Full teardown: Supabase sign-out, external services, secure storage, and
    // every user-scoped provider — so nothing leaks into the next session.
    await SessionService.clear(ref);
    if (mounted) context.go('/welcome');
  }

  Future<void> _confirmDelete() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l.deleteAccountTitle, style: AppTextStyles.heading3),
        content: Text(l.deleteAccountBody, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.deleteAccount,
                style: AppTextStyles.body.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await AccountRepository.deleteAccount();
      // The account is gone server-side; run the same full teardown as logout
      // (each step is best-effort and won't mask the successful deletion).
      await SessionService.clear(ref, alreadySignedOut: false);
      if (!mounted) return;
      AppToast.show(context, title: l.accountDeleted);
      context.go('/welcome');
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    } catch (_) {
      if (mounted) {
        AppToast.show(context, title: l.couldNotDeleteAccount, blur: false);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final localeCode = ref.watch(localeProvider)?.languageCode ??
        Localizations.localeOf(context).languageCode;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverCollapsingHeader(title: l.settingsTitle, controller: _scroll),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Profile header ───────────────────────────────
                  if (user != null) ...[
                    _ProfileHeader(
                      user: user,
                      roleLabel: _roleLabel(l, user.primaryRole),
                      onTap: () => context.push('/settings/profile'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // ── Account ──────────────────────────────────────
                  _Section(
                    header: l.secProfile,
                    rows: [
                      _Row.value(
                        icon: Icons.mail_outline,
                        title: l.emailLabel,
                        value: user?.email ?? '—',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── General ──────────────────────────────────────
                  _Section(
                    header: l.secGeneral,
                    rows: [
                      _Row.nav(
                        icon: Icons.language_outlined,
                        title: l.language,
                        value: _languageLabel(l, localeCode),
                        onTap: _pickLanguage,
                      ),
                      _Row.nav(
                        icon: Icons.brightness_6_outlined,
                        title: l.appearance,
                        value: _themeLabel(l, themeMode),
                        onTap: _pickTheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Security ─────────────────────────────────────
                  _Section(
                    header: l.secSecurity,
                    rows: [
                      _Row.nav(
                        icon: Icons.lock_outline,
                        title: l.changePassword,
                        onTap: () => context.push('/settings/change-password'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Account ──────────────────────────────────────
                  _Section(
                    header: l.secAccount,
                    rows: [
                      _Row.action(
                        icon: Icons.logout,
                        title: l.logout,
                        onTap: _busy ? null : _confirmLogout,
                      ),
                      _Row.action(
                        icon: Icons.delete_outline,
                        title: l.deleteAccount,
                        destructive: true,
                        onTap: _busy ? null : _confirmDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An iOS-style grouped section: a small header label above a rounded card that
/// holds [rows] separated by hairline dividers.
class _Section extends StatelessWidget {
  const _Section({required this.header, required this.rows});

  final String header;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.sm, bottom: AppSpacing.sm),
          child: Text(header.toUpperCase(),
              style: AppTextStyles.label.copyWith(color: AppColors.textTertiary)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                      height: 1, thickness: 1, color: AppColors.surfaceBorder),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A single settings row: leading icon, title, and either a static value, a
/// value + chevron (navigable), or a tappable action (optionally destructive).
class _Row extends StatelessWidget {
  const _Row._({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.showChevron = false,
    this.destructive = false,
  });

  factory _Row.value({
    required IconData icon,
    required String title,
    required String value,
  }) =>
      _Row._(icon: icon, title: title, value: value);

  factory _Row.nav({
    required IconData icon,
    required String title,
    String? value,
    required VoidCallback onTap,
  }) =>
      _Row._(
          icon: icon,
          title: title,
          value: value,
          onTap: onTap,
          showChevron: true);

  factory _Row.action({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    bool destructive = false,
  }) =>
      _Row._(icon: icon, title: title, onTap: onTap, destructive: destructive);

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final tint = destructive ? AppColors.error : AppColors.primary;
    final titleColor =
        destructive ? AppColors.error : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 20, color: tint),
              const SizedBox(width: AppSpacing.md),
              // Title keeps its natural width; the value takes ALL the remaining
              // space (right-aligned) so long values like an email aren't cut off.
              // The right-alignment provides the gap, so no fixed spacer is needed
              // (which also keeps the row from overflowing on narrow screens).
              Text(title, style: AppTextStyles.body.copyWith(color: titleColor)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Text(
                    value ?? '',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right,
                    size: 20, color: AppColors.textTertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable profile header: avatar + name + role, opens Profile settings.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.roleLabel,
    required this.onTap,
  });

  final AppUser user;
  final String roleLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          AppAvatar(
            avatarKind: user.avatarKind,
            avatarValue: user.avatarValue,
            initials: user.initials,
            role: user.primaryRole,
            radius: 30,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading3.copyWith(fontSize: 18)),
                const SizedBox(height: 2),
                Text(roleLabel, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
