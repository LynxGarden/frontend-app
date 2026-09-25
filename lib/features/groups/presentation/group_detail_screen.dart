import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/clients/providers/clients_provider.dart';
import 'package:lynx_app/features/groups/data/group_repository.dart';
import 'package:lynx_app/features/groups/providers/groups_provider.dart';
import 'package:lynx_app/features/programs/data/models/program.dart';
import 'package:lynx_app/features/programs/providers/programs_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

/// A single group: its members (add/remove) and the group-assign action.
class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  Future<void> _addMember(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final clients = await ref.read(clientsProvider.future);
    final members = await ref.read(groupMembersProvider(groupId).future);
    if (!context.mounted) return;
    final memberIds = members.map((m) => m.personId).toSet();
    final candidates = clients.where((c) => !memberIds.contains(c.id)).toList();
    if (candidates.isEmpty) {
      AppToast.show(context, title: l.noClientsToAdd, blur: false);
      return;
    }
    final chosenId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(l.addMember, style: AppTextStyles.heading3),
            ),
            for (final c in candidates)
              ListTile(
                title: Text(c.fullName, style: AppTextStyles.body),
                trailing: const Icon(Icons.add, color: AppColors.forest),
                onTap: () => Navigator.of(context).pop(c.id),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
    if (chosenId == null) return;
    try {
      await GroupRepository.addMember(
          tenantId: user.tenantId, groupId: groupId, personId: chosenId);
      ref.invalidate(groupMembersProvider(groupId));
      ref.invalidate(groupsProvider);
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _removeMember(
      BuildContext context, WidgetRef ref, String memberId) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    try {
      await GroupRepository.removeMember(tenantId: user.tenantId, memberId: memberId);
      ref.invalidate(groupMembersProvider(groupId));
      ref.invalidate(groupsProvider);
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _assign(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final templates = await ref.read(programTemplatesProvider.future);
    if (!context.mounted) return;
    if (templates.isEmpty) {
      AppToast.show(context, title: l.programsEmpty, blur: false);
      return;
    }
    final chosen = await showModalBottomSheet<Program>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(l.assignProgram, style: AppTextStyles.heading3),
            ),
            for (final p in templates)
              ListTile(
                title: Text(p.name, style: AppTextStyles.body),
                trailing: const Icon(Icons.add, color: AppColors.forest),
                onTap: () => Navigator.of(context).pop(p),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    try {
      final count =
          await GroupRepository.assignToGroup(programId: chosen.id, groupId: groupId);
      if (context.mounted) {
        AppToast.show(context, title: chosen.name, subtitle: l.groupAssigned(count), blur: false);
      }
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l.deleteGroupTitle, style: AppTextStyles.heading3),
        content: Text(l.deleteGroupBody, style: AppTextStyles.bodySmall),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: AppColors.onPrimary),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await GroupRepository.deleteGroup(tenantId: user.tenantId, groupId: groupId);
      ref.invalidate(groupsProvider);
      if (context.mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(groupName, style: AppTextStyles.heading3),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: l.delete,
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => _assign(context, ref),
        icon: const Icon(Icons.assignment_outlined),
        label: Text(l.assignProgram),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.members, style: AppTextStyles.heading3),
                  GestureDetector(
                    onTap: () => _addMember(context, ref),
                    child: Text('+ ${l.addMember}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.forest, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: membersAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.forest)),
                error: (_, _) => Center(
                    child: Text(l.somethingWentWrong, style: AppTextStyles.bodySmall)),
                data: (members) {
                  if (members.isEmpty) {
                    return Center(
                      child: Text(l.noMembers,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textTertiary)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, 96),
                    itemCount: members.length,
                    itemBuilder: (context, i) {
                      final m = members[i];
                      return AppCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          title: Text(m.name, style: AppTextStyles.body),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textTertiary),
                            tooltip: l.remove,
                            onPressed: () => _removeMember(context, ref, m.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
