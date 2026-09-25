import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/groups/data/group_repository.dart';
import 'package:lynx_app/features/groups/data/models/group.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// Groups in the current tenant.
final groupsProvider = FutureProvider<List<Group>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return GroupRepository.listGroups(user.tenantId);
});

/// Members of one group.
final groupMembersProvider =
    FutureProvider.family<List<GroupMember>, String>((ref, groupId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return GroupRepository.listMembers(tenantId: user.tenantId, groupId: groupId);
});
