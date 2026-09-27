import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/chat/data/models/assigned_staff.dart';
import 'package:lynx_app/features/chat/presentation/chat_screen.dart';
import 'package:lynx_app/features/chat/providers/chat_providers.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/models/app_user.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_avatar.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/skeleton_list.dart';
import 'package:lynx_app/shared/widgets/unread_badge.dart';

/// The CLIENT's master chat list (the Chat tab root — no back button). Lists the
/// coaches/physios assigned to them; tapping one opens that 1:1 conversation.
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  String _roleLabel(AppLocalizations l, AppRole role) => switch (role) {
        AppRole.owner => l.roleOwner,
        AppRole.physio => l.rolePhysio,
        AppRole.coach || AppRole.client => l.roleCoach,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final me = ref.watch(currentUserProvider).valueOrNull;
    final unread = ref.watch(clientUnreadByStaffProvider).valueOrNull ?? const {};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Text(l.chatTitle, style: AppTextStyles.heading1),
            ),
          ),
          Expanded(
            child: me == null
                ? const SizedBox.shrink()
                : ref.watch(assignedStaffProvider(me.personId)).when(
                      loading: () => const SkeletonList(),
                      error: (_, _) => _Empty(message: l.somethingWentWrong),
                      data: (staff) {
                        if (staff.isEmpty) {
                          return _Empty(message: l.chatNoCoach);
                        }
                        return ListView.separated(
                          padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs,
                              AppSpacing.lg, MediaQuery.paddingOf(context).bottom + AppSpacing.md),
                          itemCount: staff.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) => _StaffRow(
                            staff: staff[i],
                            unread: unread[staff[i].staffPersonId] ?? 0,
                            roleLabel: _roleLabel(l, staff[i].role),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  clientPersonId: me.personId,
                                  staffPersonId: staff[i].staffPersonId,
                                  title: staff[i].fullName,
                                ),
                              ));
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.staff,
    required this.unread,
    required this.roleLabel,
    required this.onTap,
  });

  final AssignedStaff staff;
  final int unread;
  final String roleLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            AppAvatar(
              avatarKind: staff.avatarKind,
              avatarValue: staff.avatarValue,
              initials: staff.initials,
              role: staff.role,
            ),
            if (unread > 0)
              Positioned(right: -2, top: -2, child: UnreadBadge(count: unread)),
          ],
        ),
        title: Text(staff.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(roleLabel, style: AppTextStyles.bodySmall),
        trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
      ),
    );
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
        child: Text(message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textTertiary)),
      ),
    );
  }
}
