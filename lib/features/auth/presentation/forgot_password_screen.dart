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

/// Step 1 of password reset: request a numeric reset code by email.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_busy && isValidEmailFormat(_email.text.trim());

  Future<void> _send() async {
    if (!_canSubmit) return;
    setState(() => _busy = true);
    try {
      await AuthRepository.sendPasswordResetOtp(_email.text.trim());
      if (!mounted) return;
      final email = Uri.encodeComponent(_email.text.trim());
      context.push('/reset-password?email=$email');
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
                  Text(l.forgotTitle, style: AppTextStyles.heading1),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l.forgotBody,
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    label: l.emailLabel,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    hintText: l.emailHint,
                    onFieldSubmitted: (_) => _send(),
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
              label: l.sendResetCode,
              isExpanded: true,
              isLoading: _busy,
              onPressed: _canSubmit ? _send : null,
            ),
          ),
        ],
      ),
    );
  }
}
