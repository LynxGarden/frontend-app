import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/settings/data/profile_repository.dart';
import 'package:lynx_app/features/settings/presentation/avatar/avatar_picker_sheet.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_avatar.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

/// Edit the signed-in user's profile: name, date of birth, avatar.
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  DateTime? _dob;
  bool _seeded = false;
  bool _saving = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save(String personId) async {
    setState(() => _saving = true);
    try {
      await ProfileRepository.updateProfile(
        personId: personId,
        firstName: _first.text,
        lastName: _last.text,
        dateOfBirth: _dob,
      );
      ref.invalidate(currentUserProvider);
      if (!mounted) return;
      AppToast.show(context, title: AppLocalizations.of(context).save);
      Navigator.of(context).maybePop();
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;

    if (user != null && !_seeded) {
      _first.text = user.firstName ?? '';
      _last.text = user.lastName ?? '';
      _dob = user.dateOfBirth;
      _seeded = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppNavBar(title: l.profileSettings),
          Expanded(
            child: user == null
                ? const SizedBox.shrink()
                : SafeArea(
                    top: false,
                    bottom: false,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: () => showAvatarPicker(
                              context,
                              ref,
                              personId: user.personId,
                              tenantId: user.tenantId,
                              role: user.primaryRole,
                              currentKind: user.avatarKind,
                              currentValue: user.avatarValue,
                            ),
                            child: Column(
                              children: [
                                AppAvatar(
                                  avatarKind: user.avatarKind,
                                  avatarValue: user.avatarValue,
                                  initials: user.initials,
                                  role: user.primaryRole,
                                  radius: 48,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(l.editAvatar,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppTextField(
                          label: l.firstName,
                          controller: _first,
                          hintText: '',
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: l.lastName,
                          controller: _last,
                          hintText: '',
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(l.dateOfBirth,
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.sm),
                        GestureDetector(
                          onTap: _pickDob,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border:
                                  Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.cake_outlined,
                                    size: 20, color: AppColors.textSecondary),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  _dob == null
                                      ? l.notSet
                                      : _dob!.toIso8601String().split('T').first,
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (user != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                    AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
                child: AppButton(
                  label: l.save,
                  isExpanded: true,
                  isLoading: _saving,
                  onPressed: _saving ? null : () => _save(user.personId),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
