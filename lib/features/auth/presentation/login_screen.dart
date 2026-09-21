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
  bool _isBusy = false;
  bool _magicLinkSent = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
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

  Future<void> _magicLink() async {
    final email = _emailController.text.trim();
    if (!isValidEmailFormat(email)) return;
    await _run(() async {
      await AuthRepository.sendMagicLink(email);
      if (mounted) setState(() => _magicLinkSent = true);
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
                    const Spacer(),
                    Center(
                      child: Text(
                        l.appName,
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.primary,
                          fontSize: 40,
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
                    const SizedBox(height: AppSpacing.xxl),

                    // SSO
                    AppButton(
                      label: l.continueWithGoogle,
                      variant: AppButtonVariant.secondary,
                      isExpanded: true,
                      onPressed:
                          _isBusy ? null : () => _oauth(OAuthProvider.google),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: l.continueWithApple,
                      isExpanded: true,
                      onPressed:
                          _isBusy ? null : () => _oauth(OAuthProvider.apple),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _OrDivider(label: l.orDivider),
                    const SizedBox(height: AppSpacing.lg),

                    // Magic link
                    AppTextField(
                      label: l.emailLabel,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      hintText: l.emailHint,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: l.sendMagicLink,
                      variant: AppButtonVariant.secondary,
                      isExpanded: true,
                      isLoading: _isBusy,
                      onPressed: (!_isBusy && emailValid) ? _magicLink : null,
                    ),
                    if (_magicLinkSent) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l.magicLinkSent,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ],

                    const Spacer(),
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
