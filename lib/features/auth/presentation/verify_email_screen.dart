import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/auth/data/auth_repository.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

/// Enter the 6-digit code emailed after sign-up to confirm the address.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_busy && _code.text.trim().length >= 6;

  Future<void> _verify() async {
    if (!_canSubmit) return;
    setState(() => _busy = true);
    try {
      await AuthRepository.verifySignupOtp(
        email: widget.email,
        token: _code.text.trim(),
      );
      // Verifying the OTP establishes a session — drop stale state so RootShell
      // re-resolves the new user rather than a cached null.
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

  Future<void> _resend() async {
    try {
      await AuthRepository.resendSignupOtp(widget.email);
      if (mounted) {
        AppToast.show(context, title: AppLocalizations.of(context).codeResent);
      }
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

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
                  Text(l.verifyEmailTitle, style: AppTextStyles.heading1),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l.verifyEmailBody(widget.email),
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: l.codeLabel,
                    controller: _code,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    hintText: '••••••',
                    onFieldSubmitted: (_) => _verify(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _resend();
                      },
                      child: Text(
                        l.resendCode,
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
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              keyboardOpen ? AppSpacing.md : AppSpacing.xl,
            ),
            child: AppButton(
              label: l.verifyCode,
              isExpanded: true,
              isLoading: _busy,
              onPressed: _canSubmit ? _verify : null,
            ),
          ),
        ],
      ),
    );
  }
}
