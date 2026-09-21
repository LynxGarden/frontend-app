import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/clients/data/assignment_repository.dart';
import 'package:lynx_app/features/clients/data/client_repository.dart';
import 'package:lynx_app/features/clients/data/models/client.dart';
import 'package:lynx_app/features/clients/data/models/client_assignment.dart';
import 'package:lynx_app/features/clients/data/models/health_flag.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// Clients (person + client role) in the current tenant.
final clientsProvider = FutureProvider<List<Client>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return ClientRepository.listClients(user.tenantId);
});

/// A single client record.
final clientProvider =
    FutureProvider.family<Client, String>((ref, personId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No session');
  return ClientRepository.getClient(tenantId: user.tenantId, personId: personId);
});

/// A client's safety-screening flags.
final clientHealthFlagsProvider =
    FutureProvider.family<List<HealthFlag>, String>((ref, personId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return ClientRepository.listHealthFlags(
    tenantId: user.tenantId,
    personId: personId,
  );
});

/// A client's assigned programs (instances).
final clientAssignmentsProvider =
    FutureProvider.family<List<ClientAssignment>, String>((ref, personId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return AssignmentRepository.listForClient(
    tenantId: user.tenantId,
    personId: personId,
  );
});
