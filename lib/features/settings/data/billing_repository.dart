import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/settings/data/models/invoice.dart';

/// Data access for billing invoices (mock data in v1).
class BillingRepository {
  const BillingRepository._();

  static const _select =
      'id, amount_cents, currency, description, status, issued_at, paid_at';

  static Future<List<Invoice>> listForPerson({
    required String tenantId,
    required String personId,
  }) async {
    try {
      final rows = await SupabaseClientWrapper.db('invoices')
          .select(_select)
          .eq('tenant_id', tenantId)
          .eq('person_id', personId)
          .order('issued_at', ascending: false);
      return (rows as List)
          .map((r) => Invoice.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw AppException('Could not load your billing history.', cause: e);
    }
  }
}
