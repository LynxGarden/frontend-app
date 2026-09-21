import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/programs/data/models/program.dart';
import 'package:lynx_app/features/programs/data/program_repository.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';

/// The signed-in coach's program templates (shallow). Invalidate after
/// create/delete to refresh the list.
final programTemplatesProvider = FutureProvider<List<Program>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return const [];
  return ProgramRepository.listTemplates(
    tenantId: user.tenantId,
    ownerId: user.personId,
  );
});
