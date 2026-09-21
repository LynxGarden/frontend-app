import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';

/// Shared base for tenant-scoped repositories.
///
/// Every domain table carries `tenant_id` and is isolated by RLS. Repositories
/// still scope explicitly (belt-and-braces): reads add `.eq('tenant_id', …)`
/// and inserts stamp `tenant_id`. Feature providers pass the current tenant id
/// (from `currentTenantIdProvider`) into repository methods.
///
/// ```dart
/// static Future<List<Exercise>> listForTenant(String tenantId) async {
///   final rows = await table('exercises')
///       .select('id, name, video_url')
///       .eq('tenant_id', tenantId);
///   ...
/// }
/// ```
abstract class BaseRepository {
  /// Shorthand for a PostgREST query builder on [name].
  static dynamic table(String name) => SupabaseClientWrapper.db(name);

  /// Guard used by feature providers before calling a repository: fail loudly
  /// (not silently query cross-tenant) if there's no resolved tenant.
  static String requireTenant(String? tenantId) {
    if (tenantId == null || tenantId.isEmpty) {
      throw AppException('No active studio. Please sign in again.');
    }
    return tenantId;
  }
}
