import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lynx_app/core/config/deeplink_config.dart';
import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';

/// Auth entry points shared by the login UI. Unified with the website:
/// email magic link + Google/Apple SSO (email/password kept as a fallback).
class AuthRepository {
  const AuthRepository._();

  static String get _redirect => DeepLinkConfig.signInCallback.toString();

  /// Passwordless email sign-in. Sends a magic link to [email].
  static Future<void> sendMagicLink(String email) async {
    try {
      await SupabaseClientWrapper.auth.signInWithOtp(
        email: email.trim(),
        emailRedirectTo: _redirect,
      );
    } catch (e) {
      throw AppException('Could not send the sign-in link. Please try again.', cause: e);
    }
  }

  /// Google / Apple SSO via the platform browser; returns via the deep link.
  static Future<void> signInWithOAuth(OAuthProvider provider) async {
    try {
      await SupabaseClientWrapper.auth.signInWithOAuth(
        provider,
        redirectTo: _redirect,
      );
    } catch (e) {
      throw AppException('Sign-in failed. Please try again.', cause: e);
    }
  }

  /// Email/password fallback (kept from the starter).
  static Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await SupabaseClientWrapper.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> signOut() => SupabaseClientWrapper.auth.signOut();
}
