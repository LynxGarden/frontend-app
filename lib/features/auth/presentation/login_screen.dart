import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/core/utils/validation_helpers.dart';
import 'package:lynx_app/features/auth/data/auth_repository.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isBusy = false;
  bool _codeSent = false;

  /// SSO is off until Google/Apple providers are configured in Supabase.
  /// Enable at build time: --dart-define=ENABLE_SSO=true
  static const bool _ssoEnabled = bool.fromEnvironment('ENABLE_SSO');

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _codeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isBusy = true);
    try {
      await action();
    } on AppException catch (e) {
      if (mounted) {
        AppToast.show(context, title: e.message, blur: false);
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          title: AppLocalizations.of(context).somethingWentWrong,
          blur: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _oauth(OAuthProvider provider) =>
      _run(() => AuthRepository.signInWithOAuth(provider));

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (!isValidEmailFormat(email)) return;
    await _run(() async {
      await AuthRepository.sendEmailOtp(email);
      if (mounted) setState(() => _codeSent = true);
    });
  }

  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (code.length < 6) return;
    // On success the auth-state listener redirects; no explicit nav needed.
    await _run(() => AuthRepository.verifyEmailOtp(email: email, token: code));
  }

  void _resetToEmail() {
    setState(() {
      _codeSent = false;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final emailValid = isValidEmailFormat(_emailController.text.trim());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 3),
                    // Brand mark
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.forest,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: AppShadows.floating,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'L',
                          style: AppTextStyles.heading1.copyWith(
                            color: AppColors.onPrimary,
                            fontSize: 40,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Text(
                        l.appName,
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.primary,
                          fontSize: 36,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Text(
                        l.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Sign-in card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: AppColors.surfaceBorder),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // SSO — hidden until Google/Apple providers are
                          // configured. Re-enable with --dart-define=ENABLE_SSO=true.
                          if (_ssoEnabled) ...[
                            AppButton(
                              label: l.continueWithGoogle,
                              variant: AppButtonVariant.secondary,
                              isExpanded: true,
                              onPressed: _isBusy
                                  ? null
                                  : () => _oauth(OAuthProvider.google),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppButton(
                              label: l.continueWithApple,
                              isExpanded: true,
                              onPressed: _isBusy
                                  ? null
                                  : () => _oauth(OAuthProvider.apple),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _OrDivider(label: l.orDivider),
                            const SizedBox(height: AppSpacing.lg),
                          ],

                          // Email → OTP code (no magic-link deep links)
                          if (!_codeSent) ...[
                            AppTextField(
                              label: l.emailLabel,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              hintText: l.emailHint,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: l.sendCode,
                              isExpanded: true,
                              isLoading: _isBusy,
                              onPressed:
                                  (!_isBusy && emailValid) ? _sendCode : null,
                            ),
                          ] else ...[
                            Text(
                              l.codeSentTo(_emailController.text.trim()),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              label: l.codeLabel,
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              hintText: '••••••',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppButton(
                              label: l.verifyCode,
                              isExpanded: true,
                              isLoading: _isBusy,
                              onPressed: (!_isBusy && _codeController.text.trim().length >= 6)
                                  ? _verifyCode
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Center(
                              child: TextButton(
                                onPressed: _isBusy ? null : _resetToEmail,
                                child: Text(l.changeEmail,
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.primary)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Spacer(flex: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: AppColors.surfaceBorder, height: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(label.toUpperCase(), style: AppTextStyles.label),
        ),
        line,
      ],
    );
  }
}
