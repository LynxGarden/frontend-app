import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/settings/data/billing_repository.dart';
import 'package:lynx_app/features/settings/data/models/invoice.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// The current user's invoices (mock billing history), newest first.
final invoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return BillingRepository.listForPerson(
    tenantId: user.tenantId,
    personId: user.personId,
  );
});
