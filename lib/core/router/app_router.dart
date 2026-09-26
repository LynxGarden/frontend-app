import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lynx_app/core/supabase/supabase_client.dart';

// Auth screens
import 'package:lynx_app/features/auth/presentation/splash_screen.dart';
import 'package:lynx_app/features/auth/presentation/welcome_screen.dart';
import 'package:lynx_app/features/auth/presentation/login_screen.dart';
import 'package:lynx_app/features/auth/presentation/signup_screen.dart';
import 'package:lynx_app/features/auth/presentation/verify_email_screen.dart';
import 'package:lynx_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:lynx_app/features/auth/presentation/reset_password_screen.dart';
import 'package:lynx_app/features/auth/presentation/change_password_screen.dart';

// App screens
import 'package:lynx_app/features/shell/presentation/root_shell.dart';
import 'package:lynx_app/features/settings/presentation/settings_screen.dart';

// ---------------------------------------------------------------------------
// Navigation keys
// ---------------------------------------------------------------------------

final rootNavigatorKey = GlobalKey<NavigatorState>();

// ---------------------------------------------------------------------------
// Auth state notifier — tells GoRouter to re-evaluate redirects
// ---------------------------------------------------------------------------

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    SupabaseClientWrapper.auth.onAuthStateChange.listen((data) {
      // Verifying a password-reset OTP emits `passwordRecovery` with a
      // temporary session. Latch it so the redirect below pins the user on the
      // reset screen instead of treating recovery as a normal sign-in (which
      // would drop them into the app before they set a new password). Cleared
      // once the password is changed (`userUpdated`) or they sign out.
      switch (data.event) {
        case AuthChangeEvent.passwordRecovery:
          isRecovering = true;
        case AuthChangeEvent.userUpdated:
        case AuthChangeEvent.signedOut:
          isRecovering = false;
        default:
          break;
      }
      notifyListeners();
    });
  }

  bool isRecovering = false;
}

final _authNotifier = _AuthNotifier();

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

/// Public (unauthenticated) auth routes.
const _publicRoutes = <String>[
  '/welcome',
  '/login',
  '/signup',
  '/verify-email',
  '/forgot-password',
  '/reset-password',
];

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: _authNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final currentPath = state.matchedLocation;

      // Splash resolves its own destination.
      if (currentPath == '/splash') return null;

      // Password recovery takes precedence: keep the user on the reset screen
      // (where they verified the code) until the new password is set. Returning
      // null preserves the `?email=` query param they arrived with.
      if (_authNotifier.isRecovering) {
        return currentPath == '/reset-password' ? null : '/reset-password';
      }

      final isAuthenticated =
          SupabaseClientWrapper.auth.currentSession != null;
      final isPublicRoute = _publicRoutes.contains(currentPath);

      // Not authenticated → landing.
      if (!isAuthenticated && !isPublicRoute) return '/welcome';

      // Authenticated but on an auth route → resolve via splash.
      if (isAuthenticated && isPublicRoute) return '/splash';

      return null;
    },
    routes: [
      // ── Auth ───────────────────────────────────────────────────
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (c, s) => const SignupScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (c, s) =>
            VerifyEmailScreen(email: s.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (c, s) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (c, s) =>
            ResetPasswordScreen(email: s.uri.queryParameters['email'] ?? ''),
      ),

      // ── Main app ───────────────────────────────────────────────
      // RootShell resolves the user's role/tenant and shows the client or
      // staff shell (or the finish-setup screen when not linked yet).
      GoRoute(path: '/app', builder: (c, s) => const RootShell()),

      // ── Settings ───────────────────────────────────────────────
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            parentNavigatorKey: rootNavigatorKey,
            path: 'change-password',
            builder: (context, state) => const ChangePasswordScreen(),
          ),
        ],
      ),
    ],
  );
});
