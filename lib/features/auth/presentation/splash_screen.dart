import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/supabase/supabase_client.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
    _resolveNavigation();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _resolveNavigation() async {
    // Give the splash a minimum display time.
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    try {
      final session = SupabaseClientWrapper.auth.currentSession;

      if (session == null) {
        if (mounted) context.go('/login');
        return;
      }

      // User is authenticated — go to home.
      // TODO: Add onboarding check here if needed:
      // final profile = await SupabaseClientWrapper.db('users')
      //     .select('onboarding_completed')
      //     .eq('id', session.user.id)
      //     .maybeSingle();
      // if (profile?['onboarding_completed'] != true) {
      //   if (mounted) context.go('/onboarding');
      //   return;
      // }

      if (mounted) context.go('/app');
    } catch (_) {
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              'Lynx',
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.primary,
                fontSize: 44,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
