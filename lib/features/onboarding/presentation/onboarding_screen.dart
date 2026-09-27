import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/settings/data/profile_repository.dart';
import 'package:lynx_app/features/settings/presentation/avatar/avatar_picker_sheet.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/models/app_user.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_avatar.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_segmented_control.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

/// First-run onboarding: name (required) → avatar (optional) → date of birth
/// (optional). Shown by RootShell while `onboarding_complete` is false.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  DateTime? _dob;
  String? _gender;
  int _step = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).valueOrNull;
    _first.text = user?.firstName ?? '';
    _last.text = user?.lastName ?? '';
    _dob = user?.dateOfBirth;
    _gender = user?.gender ?? 'male'; // Male preselected by default.
    // Toggle Next as the required name-step fields change.
    _first.addListener(() => setState(() {}));
    _last.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  AppUser? get _user => ref.read(currentUserProvider).valueOrNull;

  Future<void> _openAvatarPicker() async {
    final user = _user;
    if (user == null) return;
    await showAvatarPicker(
      context,
      ref,
      personId: user.personId,
      tenantId: user.tenantId,
      role: user.primaryRole,
      gender: _gender,
      currentKind: user.avatarKind,
      currentValue: user.avatarValue,
    );
    // Refresh so the preview reflects the new avatar.
    if (mounted) setState(() {});
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

  Future<void> _finish() async {
    final user = _user;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ProfileRepository.updateProfile(
        personId: user.personId,
        firstName: _first.text,
        lastName: _last.text,
        dateOfBirth: _dob,
        gender: _gender,
        markOnboarded: true,
      );
      ref.invalidate(currentUserProvider); // RootShell → shell
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppToast.show(context, title: e.message, blur: false);
      }
    }
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    // Name step requires first + last name and a gender selection.
    final canProceed = _step != 0 ||
        (_first.text.trim().isNotEmpty &&
            _last.text.trim().isNotEmpty &&
            _gender != null);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back button (top-left) + centered step dots
              SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_step > 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => setState(() => _step--),
                          icon: Icon(Icons.arrow_back,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 3; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _step ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _step
                                  ? AppColors.primary
                                  : AppColors.surfaceBorder,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStep(l, user),
                ),
              ),
              Row(
                children: [
                  if (_step == 1 || _step == 2)
                    AppButton(
                      label: l.skip,
                      variant: AppButtonVariant.secondary,
                      onPressed: _next,
                    ),
                  const Spacer(),
                  SizedBox(
                    width: 160,
                    child: AppButton(
                      label: _step == 2 ? l.finish : l.next,
                      isExpanded: true,
                      isLoading: _saving,
                      onPressed:
                          (_saving || !canProceed) ? null : _next,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(AppLocalizations l, AppUser? user) {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.onboardingNameTitle, style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.sm),
            Text(
                (user?.isStaff ?? false)
                    ? l.onboardingNameSubtitleStaff
                    : l.onboardingNameSubtitle,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
                label: l.firstName,
                controller: _first,
                hintText: '',
                textInputAction: TextInputAction.next),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
                label: l.lastName,
                controller: _last,
                hintText: '',
                textInputAction: TextInputAction.done),
            const SizedBox(height: AppSpacing.lg),
            Text(l.avGender.toUpperCase(),
                style: AppTextStyles.label
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            AppSegmentedControl<String>(
              selected: _gender,
              segments: [
                AppSegment(value: 'male', label: l.genderMale),
                AppSegment(value: 'female', label: l.genderFemale),
              ],
              onChanged: (g) => setState(() => _gender = g),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            Text(l.onboardingAvatarTitle, style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.sm),
            Text(l.onboardingAvatarSubtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: _openAvatarPicker,
              child: AppAvatar(
                avatarKind: user?.avatarKind,
                avatarValue: user?.avatarValue,
                initials: user?.initials ?? '?',
                role: user?.primaryRole,
                radius: 60,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l.chooseAvatar,
              variant: AppButtonVariant.secondary,
              onPressed: _openAvatarPicker,
            ),
          ],
        );
      case 2:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.onboardingDobTitle, style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.sm),
            Text(l.onboardingDobSubtitle,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: _pickDob,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cake_outlined, color: AppColors.textSecondary),
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
        );
    }
  }
}
