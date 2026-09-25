import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/groups/data/models/group.dart';

/// Groups / rosters data access (CP5). Group-assignment fans out via the
/// `assign_template_to_group` RPC (SECURITY DEFINER, staff-only).
class GroupRepository {
  const GroupRepository._();

  static Future<List<Group>> listGroups(String tenantId) async {
    try {
      final rows = await SupabaseClientWrapper.db('groups')
          .select('id, name, group_members(id)')
          .eq('tenant_id', tenantId)
          .order('name');
      return (rows as List)
          .map((r) => Group.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw AppException('Could not load groups.', cause: e);
    }
  }

  static Future<String> createGroup({
    required String tenantId,
    required String name,
    required String ownerId,
  }) async {
    try {
      final row = await SupabaseClientWrapper.db('groups')
          .insert({
            'tenant_id': tenantId,
            'name': name,
            'owner_id': ownerId,
            'created_by': ownerId,
          })
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      throw AppException('Could not create the group.', cause: e);
    }
  }

  static Future<void> deleteGroup({
    required String tenantId,
    required String groupId,
  }) async {
    try {
      await SupabaseClientWrapper.db('groups')
          .delete()
          .eq('id', groupId)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not delete the group.', cause: e);
    }
  }

  static Future<List<GroupMember>> listMembers({
    required String tenantId,
    required String groupId,
  }) async {
    try {
      final rows = await SupabaseClientWrapper.db('group_members')
          .select('id, person_id, persons!inner(first_name, last_name)')
          .eq('tenant_id', tenantId)
          .eq('group_id', groupId);
      return (rows as List)
          .map((r) => GroupMember.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      throw AppException('Could not load members.', cause: e);
    }
  }

  static Future<void> addMember({
    required String tenantId,
    required String groupId,
    required String personId,
  }) async {
    try {
      await SupabaseClientWrapper.db('group_members').insert({
        'tenant_id': tenantId,
        'group_id': groupId,
        'person_id': personId,
      });
    } catch (e) {
      throw AppException('Could not add the member.', cause: e);
    }
  }

  static Future<void> removeMember({
    required String tenantId,
    required String memberId,
  }) async {
    try {
      await SupabaseClientWrapper.db('group_members')
          .delete()
          .eq('id', memberId)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not remove the member.', cause: e);
    }
  }

  /// Fans the program out to every member. Returns how many instances were made.
  static Future<int> assignToGroup({
    required String programId,
    required String groupId,
  }) async {
    try {
      return await SupabaseClientWrapper.rpc<int>(
        'assign_template_to_group',
        params: {'p_program': programId, 'p_group': groupId},
      );
    } catch (e) {
      throw AppException('Could not assign the program to the group.', cause: e);
    }
  }
}
