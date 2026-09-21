import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lynx_app/core/supabase/supabase_client.dart';

// Auth screens
import 'package:lynx_app/features/auth/presentation/splash_screen.dart';
import 'package:lynx_app/features/auth/presentation/login_screen.dart';
import 'package:lynx_app/features/auth/presentation/signup_screen.dart';
import 'package:lynx_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:lynx_app/features/auth/presentation/check_email_screen.dart';
import 'package:lynx_app/features/auth/presentation/verification_successful_screen.dart';
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
      // A password-reset deep link makes Supabase emit `passwordRecovery`
      // (with a temporary session). Latch it so the redirect below forces the
      // user onto the reset screen instead of treating the recovery session
      // as a normal sign-in and dropping them on /home. Cleared once the
      // password is actually changed (`userUpdated`) or they sign out.
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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: _authNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final currentPath = state.matchedLocation;

      // Allow splash to handle its own navigation.
      if (currentPath == '/splash') return null;

      // Password recovery takes precedence: keep the user on the reset screen
      // (reached via the /auth/reset-password deep link) until they set a new
      // password, rather than bouncing the recovery session to /home.
      if (_authNotifier.isRecovering) {
        return currentPath == '/auth/reset-password'
            ? null
            : '/auth/reset-password';
      }

      final session = SupabaseClientWrapper.auth.currentSession;
      final isAuthenticated = session != null;

      // Recovery just finished (password changed → `userUpdated` cleared the
      // flag): move off the reset screen into the app.
      if (currentPath == '/auth/reset-password' && isAuthenticated) {
        return '/app';
      }

      const publicRoutes = [
        '/login',
        '/signup',
        '/forgot-password',
        '/check-email',
        '/verification-successful',
      ];

      final isPublicRoute = publicRoutes.contains(currentPath);

      // Not authenticated → go to login.
      if (!isAuthenticated && !isPublicRoute) return '/login';

      // Authenticated but on a public auth route → go to splash to resolve.
      if (isAuthenticated && isPublicRoute) return '/splash';

      return null;
    },
    routes: [
      // ── Auth routes ────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/check-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return CheckEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: '/verification-successful',
        builder: (context, state) => const VerificationSuccessfulScreen(),
      ),
      // Landing route for the password-reset deep link
      // (`DeepLinkConfig.authCallback`). The `passwordRecovery` redirect above
      // forces the user here; ChangePasswordScreen sets the new password.
      GoRoute(
        path: '/auth/reset-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // ── Main app ───────────────────────────────────────────────
      // RootShell resolves the user's role/tenant and shows the client or
      // staff shell (or the finish-setup screen when not linked yet).
      GoRoute(
        path: '/app',
        builder: (context, state) => const RootShell(),
      ),

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

      // TODO: Add more routes as needed.
      // Example:
      // GoRoute(
      //   path: '/dates',
      //   builder: (context, state) => const DatesScreen(),
      // ),
    ],
  );
});
