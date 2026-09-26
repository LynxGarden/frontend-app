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
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

/// Email + password sign-in for an existing account.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_busy &&
      isValidEmailFormat(_email.text.trim()) &&
      _password.text.isNotEmpty;

  Future<void> _login() async {
    if (!_canSubmit) return;
    setState(() => _busy = true);
    try {
      await AuthRepository.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      // Drop any cached (logged-out) session state so RootShell re-resolves the
      // freshly signed-in user instead of a stale null → wrong-screen.
      ref.invalidate(currentUserProvider);
      if (!mounted) return;
      context.go('/splash');
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
                  Text(l.loginHeading, style: AppTextStyles.heading1),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l.loginHeadingSub,
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
                    textInputAction: TextInputAction.done,
                    hintText: l.passwordHint,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/forgot-password');
                      },
                      child: Text(
                        l.forgotPassword,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _BottomActions(
            busy: _busy,
            canSubmit: _canSubmit,
            onSubmit: _login,
            promptText: l.noAccountPrompt,
            linkText: l.signUpLink,
            onLink: () => context.push('/signup'),
            submitLabel: l.continueLabel,
          ),
        ],
      ),
    );
  }
}

/// Shared sticky bottom for auth forms: primary button + a prompt/link row.
class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.busy,
    required this.canSubmit,
    required this.onSubmit,
    required this.submitLabel,
    required this.promptText,
    required this.linkText,
    required this.onLink,
  });

  final bool busy;
  final bool canSubmit;
  final VoidCallback onSubmit;
  final String submitLabel;
  final String promptText;
  final String linkText;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        keyboardOpen ? AppSpacing.md : AppSpacing.xl,
      ),
      child: Column(
        children: [
          AppButton(
            label: submitLabel,
            isExpanded: true,
            isLoading: busy,
            onPressed: canSubmit ? onSubmit : null,
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onLink();
            },
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: promptText, style: AppTextStyles.bodySmall),
                  TextSpan(
                    text: linkText,
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
    );
  }
}
