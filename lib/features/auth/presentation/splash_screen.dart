import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

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
    final session = SupabaseClientWrapper.auth.currentSession;

    // Warm the domain user (role/tenant) while the splash is showing, so
    // RootShell already has it resolved and skips its role-resolution skeleton —
    // otherwise the user sees two skeletons in a row (shell then first tab).
    final warm = session == null
        ? null
        : ref.read(currentUserProvider.future).catchError((_) => null);

    // Give the splash a minimum display time (runs concurrently with the warm).
    await Future.delayed(const Duration(milliseconds: 1500));
    if (warm != null) await warm; // RootShell surfaces any load error/null state

    if (!mounted) return;
    context.go(session == null ? '/welcome' : '/app');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Image.asset(
            'assets/icons/logo.png',
            width: 120,
            height: 120,
          ),
        ),
      ),
    );
  }
}
