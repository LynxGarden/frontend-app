import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/notifications/presentation/notifications_screen.dart';
import 'package:lynx_app/features/notifications/providers/notifications_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/unread_badge.dart';

/// A top-right bell that opens the notifications feed, with an unread badge.
/// Drop into a screen header's action/trailing slot.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppNavBarAction(
          icon: Icons.notifications_none_rounded,
          tooltip: AppLocalizations.of(context).notificationsTitle,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotificationsScreen()));
          },
        ),
        if (unread > 0)
          Positioned(
              right: -4, top: -4, child: UnreadBadge(count: unread)),
      ],
    );
  }
}
