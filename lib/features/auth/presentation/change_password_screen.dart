import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/validation_helpers.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/password_requirements.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isSaving = false;
  bool _confirmTouched = false;

  bool get _isPasswordValid {
    final pwd = _newPasswordController.text;
    return hasMinLength(pwd, min: 8) &&
        hasUppercase(pwd) &&
        hasLowercase(pwd) &&
        hasSpecialCharacter(pwd);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
    _newPasswordFocusNode.addListener(() { if (mounted) setState(() {}); });
    _confirmPasswordFocusNode.addListener(() {
      if (!mounted) return;
      if (!_confirmPasswordFocusNode.hasFocus &&
          _confirmPasswordController.text.isNotEmpty) {
        setState(() => _confirmTouched = true);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_onFieldChanged);
    _confirmPasswordController.removeListener(_onFieldChanged);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      await SupabaseClientWrapper.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (!mounted) return;
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      AppToast.show(context, title: 'Password updated', subtitle: 'Your new password is now active.');
    } on AuthException catch (e) {
      if (!mounted) return;
      AppToast.show(context, title: 'Could not update password', subtitle: e.message, blur: false);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, title: 'Something went wrong', subtitle: 'Please try again.', blur: false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pwd = _newPasswordController.text;
    final confirmPwd = _confirmPasswordController.text;
    final passOk = _isPasswordValid;
    final matchOk = pwd == confirmPwd && confirmPwd.isNotEmpty;

    String? confirmErrorText;
    if (_confirmTouched && confirmPwd.isNotEmpty && pwd != confirmPwd) {
      confirmErrorText = 'Passwords must match.';
    }

    final showPasswordRequirements =
        _newPasswordFocusNode.hasFocus || !_isPasswordValid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Change Password',
            style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'New password',
                    controller: _newPasswordController,
                    focusNode: _newPasswordFocusNode,
                    isPassword: true,
                    hintText: 'At least 8 characters',
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: showPasswordRequirements
                        ? PasswordRequirements(key: const ValueKey('pwd-req-visible'), value: pwd)
                        : const SizedBox(key: ValueKey('pwd-req-hidden'), height: 0),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Confirm new password',
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    isPassword: true,
                    hintText: 'Re-enter your password',
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                    errorText: confirmErrorText,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.sm,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            ),
            child: AppButton(
              label: 'Update Password',
              loadingLabel: 'Updating...',
              isExpanded: true,
              isLoading: _isSaving,
              onPressed: !_isSaving && passOk && matchOk ? _handleSave : null,
            ),
          ),
        ],
      ),
    );
  }
}
