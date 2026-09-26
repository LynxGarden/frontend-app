import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/notifications/onesignal_service.dart';
import 'package:lynx_app/core/purchases/revenue_cat_service.dart';
import 'package:lynx_app/core/storage/secure_storage_service.dart';
import 'package:lynx_app/features/auth/data/auth_repository.dart';
import 'package:lynx_app/features/clients/providers/clients_provider.dart';
import 'package:lynx_app/features/exercises/providers/exercises_provider.dart';
import 'package:lynx_app/features/groups/providers/groups_provider.dart';
import 'package:lynx_app/features/programs/providers/programs_provider.dart';
import 'package:lynx_app/features/review/providers/review_provider.dart';
import 'package:lynx_app/features/training/providers/training_provider.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// The single teardown authority for ending a session — used by both **log out**
/// and **delete account**. It signs out of Supabase, clears external-service
/// identities, wipes sensitive local storage, and drops every in-memory piece of
/// user-scoped Riverpod state so the next user can never see the previous one's
/// data (belt-and-braces on top of RLS).
///
/// Device-level preferences (theme, language) live in [LocalStorageService] and
/// are intentionally **kept** — they aren't user data and resetting them on
/// logout would be jarring.
class SessionService {
  const SessionService._();

  /// Every user-scoped provider. Invalidating a family (no argument) drops all
  /// of its instances at once.
  ///
  /// ⚠️ Rule: any NEW provider that returns user- or tenant-scoped data MUST be
  /// added here, or its cache will leak across accounts on a shared device.
  static final List<ProviderOrFamily> _userScoped = [
    // shared
    currentUserProvider,
    currentTenantIdProvider,
    // clients
    clientsProvider,
    clientProvider,
    clientHealthFlagsProvider,
    clientAssignmentsProvider,
    // exercises
    exercisesProvider,
    exerciseTagsProvider,
    // groups
    groupsProvider,
    groupMembersProvider,
    // programs
    programTemplatesProvider,
    programProvider,
    sessionEditorProvider,
    // review
    reviewFeedProvider,
    clientCompletedProvider,
    sessionActualsProvider,
    // training
    activeAssignmentProvider,
    sessionRunnerProvider,
    lastEntriesProvider,
  ];

  /// Tears everything down. Safe to call when the backend session is already
  /// gone (e.g. right after account deletion) — every step is best-effort and a
  /// failure in one never blocks the others.
  ///
  /// [alreadySignedOut] skips the Supabase `signOut` call when the account was
  /// just deleted server-side (the token is already invalid).
  static Future<void> clear(
    WidgetRef ref, {
    bool alreadySignedOut = false,
  }) async {
    // 1. External-service identities (stubs today; real calls when enabled).
    try {
      await OneSignalService.clearUser();
    } catch (_) {}
    try {
      await RevenueCatService.logOut();
    } catch (_) {}

    // 2. Supabase auth — clears its own persisted session/token store.
    if (!alreadySignedOut) {
      try {
        await AuthRepository.signOut();
      } catch (_) {}
    }

    // 3. Sensitive local values (any tokens/secrets we may have stashed).
    try {
      await SecureStorageService.deleteAll();
    } catch (_) {}

    // 4. In-memory app state — drop every user-scoped provider so nothing
    // survives into the next session. Done last, after sign-out, so any
    // dependent recompute sees the signed-out state.
    for (final p in _userScoped) {
      ref.invalidate(p);
    }
  }
}
