import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';

class CheckEmailScreen extends ConsumerStatefulWidget {
  const CheckEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends ConsumerState<CheckEmailScreen> {
  static const _cooldownSeconds = 60;

  Timer? _timer;
  int _secondsLeft = _cooldownSeconds;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  Future<void> _resend() async {
    if (_isResending || _secondsLeft > 0) return;
    final email = widget.email.trim();
    if (email.isEmpty) return;

    setState(() => _isResending = true);
    try {
      await SupabaseClientWrapper.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email sent. Check your inbox.',
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _startCooldown();
    } catch (e) {
      debugPrint('CheckEmailScreen: resend failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not resend email. Please try again.',
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email.trim();
    final canResend = !_isResending && _secondsLeft == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Check your inbox',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading1.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      "You're almost in!",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_rounded,
                          color: AppColors.primary,
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'We sent a confirmation link to:',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      email.isEmpty ? '\u2014' : email,
                      style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      "Didn't get it? Check your spam folder\nor resend the link.",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Material(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.pop(),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  AppButton(
                    label: canResend
                        ? 'Resend Link'
                        : (_isResending
                            ? 'Resending...'
                            : 'Resend Link (${_secondsLeft}s)'),
                    variant: AppButtonVariant.secondary,
                    isLoading: _isResending,
                    onPressed: canResend ? _resend : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
