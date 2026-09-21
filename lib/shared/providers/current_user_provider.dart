import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/shared/data/session_repository.dart';
import 'package:lynx_app/shared/models/app_user.dart';

/// The signed-in user's domain identity (person + tenant + roles), or null if
/// there's no session / the auth user isn't linked to a person yet.
///
/// Feature providers read `currentUserProvider` to get the active `tenantId`
/// and scope their queries to it (belt-and-braces on top of RLS).
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  return SessionRepository.loadCurrentUser();
});

/// Convenience: the current tenant id (null until loaded/linked).
final currentTenantIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider).maybeWhen(
        data: (user) => user?.tenantId,
        orElse: () => null,
      );
});
