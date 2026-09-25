import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lynx_app/core/config/deeplink_config.dart';
import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';

/// Auth entry points shared by the login UI. Passwordless **email OTP** (a
/// 6-digit code — no magic-link deep links) + optional Google/Apple SSO
/// (email/password kept as a fallback).
class AuthRepository {
  const AuthRepository._();

  static String get _redirect => DeepLinkConfig.signInCallback.toString();

  /// Passwordless email sign-in/up. Sends a numeric OTP code to [email]
  /// (no `emailRedirectTo`, so Supabase sends the code, not a magic link).
  /// The Supabase email template must surface `{{ .Token }}`.
  static Future<void> sendEmailOtp(String email) async {
    try {
      await SupabaseClientWrapper.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: true,
      );
    } catch (e) {
      throw AppException('Could not send the code. Please try again.', cause: e);
    }
  }

  /// Verifies the emailed OTP [token] and establishes the session.
  static Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      await SupabaseClientWrapper.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.email,
      );
    } catch (e) {
      throw AppException('That code is invalid or expired. Please try again.', cause: e);
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
