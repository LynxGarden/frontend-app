import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/config/deeplink_config.dart';
import 'package:lynx_app/core/utils/validation_helpers.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/password_requirements.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _emailError = false;
  String _emailErrorText = 'Please check your email.';
  bool _emailTouched = false;
  bool _confirmTouched = false;

  bool get _isPasswordValid {
    final pwd = _passwordController.text;
    return hasMinLength(pwd, min: 8) &&
        hasUppercase(pwd) &&
        hasLowercase(pwd) &&
        hasSpecialCharacter(pwd);
  }

  void _onFieldChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      _onFieldChanged();
      setState(() {
        _emailError = false;
        _emailErrorText = 'Please check your email.';
      });
    });
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);

    _emailFocusNode.addListener(() {
      if (!mounted) return;
      if (!_emailFocusNode.hasFocus && _emailController.text.isNotEmpty) {
        setState(() => _emailTouched = true);
      }
      setState(() {});
    });

    _passwordFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {});
    });

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
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _confirmPasswordController.removeListener(_onFieldChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final emailOk = isValidEmailFormat(_emailController.text);
    final passOk = _isPasswordValid;
    final matchOk = _passwordController.text == _confirmPasswordController.text &&
        _confirmPasswordController.text.isNotEmpty;

    if (!emailOk || !passOk || !matchOk) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseClientWrapper.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailRedirectTo: DeepLinkConfig.verificationSuccessful.toString(),
      );

      if (!mounted) return;
      final encodedEmail = Uri.encodeComponent(_emailController.text.trim());
      context.push('/check-email?email=$encodedEmail');
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.message.toLowerCase().contains('already') ||
          e.message.toLowerCase().contains('exists')) {
        setState(() {
          _emailError = true;
          _emailErrorText = 'An account with this email already exists.';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _emailController.text;
    final emailOk = isValidEmailFormat(email);
    final passOk = _isPasswordValid;
    final pwd = _passwordController.text;
    final confirmPwd = _confirmPasswordController.text;
    final matchOk = pwd == confirmPwd && confirmPwd.isNotEmpty;

    String? emailErrorText;
    if (_emailError) {
      emailErrorText = _emailErrorText;
    } else if (_emailTouched && email.isNotEmpty && !emailOk) {
      emailErrorText = 'Enter a valid email address.';
    }

    String? confirmErrorText;
    if (_confirmTouched && confirmPwd.isNotEmpty && pwd != confirmPwd) {
      confirmErrorText = 'Passwords must match.';
    }

    final showPasswordRequirements =
        _passwordFocusNode.hasFocus || !_isPasswordValid;

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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      Text(
                        'APP NAME',
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.primary,
                          fontSize: 36,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      Text(
                        'Create Account',
                        style: AppTextStyles.heading1.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: AppTextStyles.bodySmall,
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Email
                      AppTextField(
                        label: 'Email',
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'you@example.com',
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                        errorText: emailErrorText,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Password
                      AppTextField(
                        label: 'Password',
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        isPassword: true,
                        hintText: 'At least 8 characters',
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: showPasswordRequirements
                            ? PasswordRequirements(
                                key: const ValueKey('pwd-req-visible'),
                                value: pwd,
                              )
                            : const SizedBox(key: ValueKey('pwd-req-hidden'), height: 0),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Confirm password
                      AppTextField(
                        label: 'Confirm Password',
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        isPassword: true,
                        hintText: 'Re-enter your password',
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                        errorText: confirmErrorText,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Create Account button
                      AppButton(
                        label: 'Create Account',
                        loadingLabel: 'Creating Account...',
                        isExpanded: true,
                        isLoading: _isLoading,
                        onPressed: !_isLoading && emailOk && passOk && matchOk
                            ? _handleSignup
                            : null,
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
