import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/notifications/data/models/app_notification.dart';
import 'package:lynx_app/features/notifications/data/notifications_repository.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// Realtime stream of the current user's notifications (newest first).
final notificationsProvider =
    StreamProvider<List<AppNotification>>((ref) async* {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* NotificationsRepository.stream(user.personId);
});

/// Unread notification count (drives the tab badge).
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return items.where((n) => !n.isRead).length;
});
