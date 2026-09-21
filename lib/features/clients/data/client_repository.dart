import 'dart:math';

import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/clients/data/models/client.dart';
import 'package:lynx_app/features/clients/data/models/health_flag.dart';

/// Tenant-scoped data access for client records (persons with the client role),
/// their safety-screening flags, and invites.
class ClientRepository {
  const ClientRepository._();

  /// Clients (persons holding the client role) in the tenant.
  static Future<List<Client>> listClients(String tenantId) async {
    try {
      final rows = await SupabaseClientWrapper.db('persons')
          .select(
              'id, first_name, last_name, email, phone, lifecycle_stage, locale, auth_user_id, person_roles!inner(role)')
          .eq('tenant_id', tenantId)
          .eq('person_roles.role', 'client')
          .order('first_name');
      return (rows as List)
          .map((r) => Client.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw AppException('Could not load clients.', cause: e);
    }
  }

  static Future<Client> getClient({
    required String tenantId,
    required String personId,
  }) async {
    try {
      final row = await SupabaseClientWrapper.db('persons')
          .select(
              'id, first_name, last_name, email, phone, lifecycle_stage, locale, auth_user_id')
          .eq('id', personId)
          .eq('tenant_id', tenantId)
          .single();
      return Client.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException('Could not load the client.', cause: e);
    }
  }

  /// Creates an account-less client (person + client role). Returns the id.
  static Future<String> createClient({
    required String tenantId,
    required String createdBy,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
  }) async {
    try {
      final person = await SupabaseClientWrapper.db('persons')
          .insert({
            'tenant_id': tenantId,
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'email': _blankNull(email),
            'phone': _blankNull(phone),
            'created_by': createdBy,
          })
          .select('id')
          .single();
      final id = person['id'] as String;
      await SupabaseClientWrapper.db('person_roles').insert({
        'tenant_id': tenantId,
        'person_id': id,
        'role': 'client',
      });
      return id;
    } catch (e) {
      throw AppException('Could not create the client.', cause: e);
    }
  }

  // --- health flags ---------------------------------------------------------
  static Future<List<HealthFlag>> listHealthFlags({
    required String tenantId,
    required String personId,
  }) async {
    try {
      final rows = await SupabaseClientWrapper.db('health_flags')
          .select('id, flag_type, value, notes')
          .eq('tenant_id', tenantId)
          .eq('person_id', personId)
          .order('flag_type');
      return (rows as List)
          .map((r) => HealthFlag.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw AppException('Could not load health flags.', cause: e);
    }
  }

  static Future<void> addHealthFlag({
    required String tenantId,
    required String personId,
    required String recordedBy,
    required String flagType,
    String? value,
    String? notes,
  }) async {
    try {
      await SupabaseClientWrapper.db('health_flags').insert({
        'tenant_id': tenantId,
        'person_id': personId,
        'recorded_by': recordedBy,
        'flag_type': flagType,
        'value': _blankNull(value),
        'notes': _blankNull(notes),
      });
    } catch (e) {
      throw AppException('Could not save the flag.', cause: e);
    }
  }

  static Future<void> deleteHealthFlag({
    required String tenantId,
    required String flagId,
  }) async {
    try {
      await SupabaseClientWrapper.db('health_flags')
          .delete()
          .eq('id', flagId)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not remove the flag.', cause: e);
    }
  }

  // --- invites --------------------------------------------------------------
  /// Creates an invite for the client and returns the code to share.
  static Future<String> createInvite({
    required String tenantId,
    required String personId,
    required String invitedBy,
  }) async {
    final code = _generateCode();
    try {
      await SupabaseClientWrapper.db('invites').insert({
        'tenant_id': tenantId,
        'person_id': personId,
        'invited_by': invitedBy,
        'code': code,
        'status': 'pending',
      });
      return code;
    } catch (e) {
      throw AppException('Could not create an invite.', cause: e);
    }
  }

  static String _generateCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => alphabet[rand.nextInt(alphabet.length)]).join();
  }

  static String? _blankNull(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}
