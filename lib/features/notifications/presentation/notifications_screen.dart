import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/notifications/data/models/app_notification.dart';
import 'package:lynx_app/features/notifications/data/notifications_repository.dart';
import 'package:lynx_app/features/notifications/providers/notifications_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// The in-app notifications inbox (comments / likes / difficulty ratings).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppNavBar(
            title: l.notificationsTitle,
            trailing: unread > 0
                ? AppNavBarAction(
                    icon: Icons.done_all,
                    tooltip: l.markAllRead,
                    onTap: () => _markAll(context, ref),
                  )
                : null,
          ),
          Expanded(
            child: async.when(
              loading: () => const _NotificationsSkeleton(),
              error: (e, _) => _Empty(message: l.noNotifications),
              data: (items) {
                if (items.isEmpty) return _Empty(message: l.noNotifications);
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      _NotificationTile(item: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAll(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    HapticFeedback.selectionClick();
    try {
      await NotificationsRepository.markAllRead(
          tenantId: user.tenantId, recipientId: user.personId);
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message);
    }
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toString();
    final color = item.isRead ? AppColors.textSecondary : AppColors.textPrimary;

    return AppCard(
      onTap: () => _onTap(context, ref),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(_iconFor(item.type), size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.body.copyWith(
                    color: color,
                    fontWeight:
                        item.isRead ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                if (item.body != null && item.body!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.body!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _relativeTime(context, item.createdAt, locale),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          if (!item.isRead) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 9,
              height: 9,
              decoration:
                  BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    if (item.isRead) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    try {
      await NotificationsRepository.markRead(
          tenantId: user.tenantId, id: item.id);
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message);
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'comment':
        return Icons.chat_bubble_outline;
      case 'like':
        return Icons.favorite_outline;
      case 'feedback':
        return Icons.star_outline;
      default:
        return Icons.notifications_none;
    }
  }

  String _relativeTime(BuildContext context, DateTime when, String locale) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat.yMMMd(locale).format(when);
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none,
                size: 40, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
        itemCount: 6,
        itemBuilder: (context, i) => AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 40, height: 40, borderRadius: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 160, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
