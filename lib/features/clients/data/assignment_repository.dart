import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/clients/data/models/client_assignment.dart';

/// Assignment (instance) data access. Assigning snapshots a template via the
/// `assign_template` RPC; the client daily loop (CP4) reads the instance.
class AssignmentRepository {
  const AssignmentRepository._();

  /// Snapshots [programId] into a per-client instance. Returns the new id.
  static Future<String> assignTemplate({
    required String programId,
    required String personId,
    String? name,
  }) async {
    try {
      final id = await SupabaseClientWrapper.rpc<String>(
        'assign_template',
        params: {
          'p_program': programId,
          'p_person': personId,
          'p_name': name,
        },
      );
      return id;
    } catch (e) {
      throw AppException('Could not assign the program.', cause: e);
    }
  }

  /// A client's assignments (with a session count).
  static Future<List<ClientAssignment>> listForClient({
    required String tenantId,
    required String personId,
  }) async {
    try {
      final rows = await SupabaseClientWrapper.db('assignments')
          .select('id, name, is_active, assignment_sessions(id)')
          .eq('tenant_id', tenantId)
          .eq('person_id', personId)
          .order('assigned_at', ascending: false);
      return (rows as List)
          .map((r) => ClientAssignment.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw AppException('Could not load assignments.', cause: e);
    }
  }

  /// Links the current auth user to an invited person. Returns the person id.
  static Future<String> redeemInvite(String code) async {
    try {
      return await SupabaseClientWrapper.rpc<String>(
        'redeem_invite',
        params: {'p_code': code.trim().toUpperCase()},
      );
    } catch (e) {
      throw AppException('That invite code is invalid or already used.', cause: e);
    }
  }
}
