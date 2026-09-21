import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/auth/data/auth_repository.dart';
import 'package:lynx_app/features/clients/data/assignment_repository.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

/// Shown when a user is authenticated but their auth account isn't linked to a
/// `person` (tenant) yet. They can redeem an invite code to link, or sign out.
class FinishSetupScreen extends ConsumerStatefulWidget {
  const FinishSetupScreen({super.key});

  @override
  ConsumerState<FinishSetupScreen> createState() => _FinishSetupScreenState();
}

class _FinishSetupScreenState extends ConsumerState<FinishSetupScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final l = AppLocalizations.of(context);
    final code = _code.text.trim();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    try {
      await AssignmentRepository.redeemInvite(code);
      ref.invalidate(currentUserProvider); // re-resolves the now-linked person
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    } catch (_) {
      if (mounted) AppToast.show(context, title: l.somethingWentWrong, blur: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.finishSetupTitle,
                    textAlign: TextAlign.center, style: AppTextStyles.heading2),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l.finishSetupBody,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(l.haveInviteCode, style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: l.enterInviteCode,
                  controller: _code,
                  hintText: '',
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l.continueLabel,
                  isExpanded: true,
                  isLoading: _busy,
                  onPressed: _busy ? null : _redeem,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l.logout,
                  variant: AppButtonVariant.ghost,
                  onPressed: () async {
                    await AuthRepository.signOut();
                    ref.invalidate(currentUserProvider);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
