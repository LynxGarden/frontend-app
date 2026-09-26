import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/core/utils/validation_helpers.dart';
import 'package:lynx_app/features/auth/data/auth_repository.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/password_requirements.dart';

/// Step 2 of password reset: verify the emailed code and set a new password.
///
/// Verifying the recovery OTP establishes a temporary recovery session (the
/// router's `isRecovering` latch pins the user here); setting the password
/// clears it and returns to the login screen.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
    _repeat.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  bool get _passwordValid {
    final p = _password.text;
    return hasMinLength(p, min: 8) &&
        hasUppercase(p) &&
        hasLowercase(p) &&
        hasSpecialCharacter(p);
  }

  bool get _passwordsMatch =>
      _repeat.text.isNotEmpty && _password.text == _repeat.text;

  bool get _canSubmit =>
      !_busy &&
      _code.text.trim().length >= 6 &&
      _passwordValid &&
      _passwordsMatch;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _busy = true);
    try {
      await AuthRepository.verifyRecoveryOtp(
        email: widget.email,
        token: _code.text.trim(),
      );
      await AuthRepository.updatePassword(_password.text);
      // Drop the recovery session; the user logs in fresh with the new password.
      await AuthRepository.signOut();
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      AppToast.show(context, title: l.resetSuccess);
      context.go('/login');
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    } catch (_) {
      if (mounted) {
        AppToast.show(context,
            title: AppLocalizations.of(context).somethingWentWrong, blur: false);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showMismatch = _repeat.text.isNotEmpty && !_passwordsMatch;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppNavBar(title: ''),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.resetTitle, style: AppTextStyles.heading1),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l.resetCodeBody(widget.email),
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: l.codeLabel,
                    controller: _code,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    hintText: '••••••',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: l.newPasswordLabel,
                    controller: _password,
                    isPassword: true,
                    textInputAction: TextInputAction.next,
                    hintText: l.createPasswordHint,
                  ),
                  PasswordRequirements(value: _password.text),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: l.repeatPasswordLabel,
                    controller: _repeat,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    hintText: l.repeatPasswordHint,
                    errorText: showMismatch ? l.passwordsDontMatch : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              keyboardOpen ? AppSpacing.md : AppSpacing.xl,
            ),
            child: AppButton(
              label: l.resetTitle,
              isExpanded: true,
              isLoading: _busy,
              onPressed: _canSubmit ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }
}
