import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Email + password sign-up. Email is verified with a numeric OTP code.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
    _repeat.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
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
      isValidEmailFormat(_email.text.trim()) &&
      _passwordValid &&
      _passwordsMatch;

  Future<void> _signup() async {
    if (!_canSubmit) return;
    setState(() => _busy = true);
    try {
      final hasSession = await AuthRepository.signUp(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      if (hasSession) {
        // Email confirmation disabled — straight into the app.
        context.go('/splash');
      } else {
        final email = Uri.encodeComponent(_email.text.trim());
        context.push('/verify-email?email=$email');
      }
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
                  Text(l.signupTitle, style: AppTextStyles.heading1),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l.signupSubtitle,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: l.emailLabel,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    hintText: l.emailHint,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: l.passwordLabel,
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
                    onFieldSubmitted: (_) => _signup(),
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
            child: Column(
              children: [
                AppButton(
                  label: l.createAccountButton,
                  isExpanded: true,
                  isLoading: _busy,
                  onPressed: _canSubmit ? _signup : null,
                ),
                const SizedBox(height: AppSpacing.md),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.canPop() ? context.pop() : context.push('/login');
                  },
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                            text: l.alreadyHaveAccount,
                            style: AppTextStyles.bodySmall),
                        TextSpan(
                          text: l.login,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
