import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/shared/models/app_user.dart';

/// Resolves the signed-in auth user into their domain [AppUser] (person +
/// tenant + roles). Returns null when there is no session, or when the auth
/// user has no linked `person` row yet (freshly-signed-up SSO user awaiting an
/// invite link). RLS guarantees only the user's own record is visible.
class SessionRepository {
  const SessionRepository._();

  static Future<AppUser?> loadCurrentUser() async {
    final authUser = SupabaseClientWrapper.auth.currentUser;
    if (authUser == null) return null;

    try {
      final personRow = await SupabaseClientWrapper.db('persons')
          .select('id, tenant_id, first_name, last_name, email, locale')
          .eq('auth_user_id', authUser.id)
          .maybeSingle();

      if (personRow == null) return null; // authenticated but not linked yet

      final roleRows = await SupabaseClientWrapper.db('person_roles')
          .select('role')
          .eq('person_id', personRow['id'] as String);

      final roles = <AppRole>{};
      for (final row in roleRows as List) {
        final parsed = appRoleFromString((row as Map)['role'] as String);
        if (parsed != null) roles.add(parsed);
      }
      // A linked person with no explicit role row is treated as a client.
      if (roles.isEmpty) roles.add(AppRole.client);

      return AppUser.fromJson(Map<String, dynamic>.from(personRow), roles);
    } catch (e) {
      throw AppException(
        'Could not load your profile. Please try again.',
        cause: e,
      );
    }
  }
}
