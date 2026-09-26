import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lynx_app/core/config/deeplink_config.dart';
import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';

/// Auth entry points for the password-based flow.
///
/// Login/sign-up use **email + password**. Email verification (after sign-up)
/// and password reset both use a **numeric OTP code** — no magic-link deep
/// links. Every OTP email relies on the Supabase template surfacing
/// `{{ .Token }}`. Optional Google/Apple SSO stays gated off.
class AuthRepository {
  const AuthRepository._();

  static String get _redirect => DeepLinkConfig.signInCallback.toString();

  // ── Sign in ────────────────────────────────────────────────────────────

  /// Email + password sign-in for an existing account.
  static Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await SupabaseClientWrapper.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      throw AppException(
        'Incorrect email or password. Please try again.',
        cause: e,
      );
    } catch (e) {
      throw AppException('Could not sign in. Please try again.', cause: e);
    }
  }

  // ── Sign up (email verification via OTP) ─────────────────────────────────

  /// Creates the account with [email] + [password]. With email confirmation
  /// enabled, Supabase sends a numeric code (no `emailRedirectTo`, so no deep
  /// link). Returns `true` when a session was established immediately
  /// (confirmation disabled), `false` when the OTP still needs verifying.
  static Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final res = await SupabaseClientWrapper.auth.signUp(
        email: email.trim(),
        password: password,
      );
      return res.session != null;
    } on AuthException catch (e) {
      final already = e.message.toLowerCase().contains('registered') ||
          e.message.toLowerCase().contains('already');
      throw AppException(
        already
            ? 'An account with this email already exists.'
            : e.message,
        cause: e,
      );
    } catch (e) {
      throw AppException('Could not create the account. Please try again.',
          cause: e);
    }
  }

  /// Verifies the sign-up confirmation [token] and establishes the session.
  static Future<void> verifySignupOtp({
    required String email,
    required String token,
  }) async {
    try {
      await SupabaseClientWrapper.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.signup,
      );
    } catch (e) {
      throw AppException(
        'That code is invalid or expired. Please try again.',
        cause: e,
      );
    }
  }

  /// Re-sends the sign-up confirmation code to [email].
  static Future<void> resendSignupOtp(String email) async {
    try {
      await SupabaseClientWrapper.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
    } catch (e) {
      throw AppException('Could not resend the code. Please try again.',
          cause: e);
    }
  }

  // ── Password reset (via OTP) ─────────────────────────────────────────────

  /// Sends a password-reset code to [email]. No `redirectTo`, so Supabase
  /// sends a recovery email whose `{{ .Token }}` is the numeric code.
  static Future<void> sendPasswordResetOtp(String email) async {
    try {
      await SupabaseClientWrapper.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      throw AppException('Could not send the reset code. Please try again.',
          cause: e);
    }
  }

  /// Verifies the recovery [token], establishing a temporary recovery session
  /// that authorises [updatePassword].
  static Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    try {
      await SupabaseClientWrapper.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.recovery,
      );
    } catch (e) {
      throw AppException(
        'That code is invalid or expired. Please try again.',
        cause: e,
      );
    }
  }

  /// Sets a new [password] on the current (recovery or normal) session.
  static Future<void> updatePassword(String password) async {
    try {
      await SupabaseClientWrapper.auth.updateUser(
        UserAttributes(password: password),
      );
    } on AuthException catch (e) {
      throw AppException(e.message, cause: e);
    } catch (e) {
      throw AppException('Could not update the password. Please try again.',
          cause: e);
    }
  }

  // ── SSO (gated off) ──────────────────────────────────────────────────────

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

  static Future<void> signOut() => SupabaseClientWrapper.auth.signOut();
}
