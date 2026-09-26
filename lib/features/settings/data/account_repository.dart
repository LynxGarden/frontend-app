import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';

/// Account-level actions that need privileged backend logic.
class AccountRepository {
  const AccountRepository._();

  /// Permanently deletes the signed-in user's account via the `delete-account`
  /// Edge Function (which uses the service role to remove the auth user and
  /// their domain data). The caller should sign out afterwards.
  static Future<void> deleteAccount() async {
    try {
      final res =
          await SupabaseClientWrapper.functions.invoke('delete-account');
      if (res.status != 200) {
        throw AppException(
          'Could not delete your account. Please try again.',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
        'Could not delete your account. Please try again.',
        cause: e,
      );
    }
  }
}
