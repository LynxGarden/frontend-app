import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/groups/data/group_repository.dart';
import 'package:lynx_app/features/groups/presentation/group_detail_screen.dart';
import 'package:lynx_app/features/groups/providers/groups_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/collapsing_header.dart';

/// Staff Groups tab: list rosters, create a new one, drill into a group.
class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewGroupDialog(),
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      final id = await GroupRepository.createGroup(
        tenantId: user.tenantId,
        name: name.trim(),
        ownerId: user.personId,
      );
      ref.invalidate(groupsProvider);
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GroupDetailScreen(groupId: id, groupName: name.trim()),
        ));
      }
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(groupsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.onPrimary,
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(l.newGroup),
      ),
      body: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverCollapsingHeader(title: l.groupsTitle, controller: _scroll),
          async.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.forest)),
            ),
            error: (_, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                  child: Text(l.somethingWentWrong,
                      style: AppTextStyles.bodySmall)),
            ),
            data: (groups) {
              if (groups.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(l.noGroups,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textTertiary)),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
                sliver: SliverList.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        title: Text(g.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body
                                .copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text(l.memberCount(g.memberCount),
                            style: AppTextStyles.bodySmall),
                        trailing: const Icon(Icons.chevron_right,
                            color: AppColors.textTertiary),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(
                                groupId: g.id, groupName: g.name),
                          ));
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NewGroupDialog extends StatefulWidget {
  const _NewGroupDialog();

  @override
  State<_NewGroupDialog> createState() => _NewGroupDialogState();
}

class _NewGroupDialogState extends State<_NewGroupDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l.newGroup, style: AppTextStyles.heading3),
      content: AppTextField(
        label: l.newGroup,
        controller: _controller,
        hintText: l.groupNameHint,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.forest, foregroundColor: AppColors.onPrimary),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l.create),
        ),
      ],
    );
  }
}
