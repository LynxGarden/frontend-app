import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/features/programs/data/models/program.dart';
import 'package:lynx_app/features/programs/data/models/training_session.dart';
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

/// A single program (with its sessions) for the program editor. Invalidate
/// after mutating sessions.
final programProvider =
    FutureProvider.family<Program, String>((ref, programId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No session');
  return ProgramRepository.loadProgram(
    tenantId: user.tenantId,
    programId: programId,
  );
});

/// Key for the session editor: which program + session.
typedef SessionEditorKey = ({String programId, String sessionId});

/// One session (with its exercises) for the session editor. Provider-backed so
/// the screen is render-testable. Invalidate after mutating exercises.
final sessionEditorProvider =
    FutureProvider.family<TrainingSession?, SessionEditorKey>((ref, key) async {
  final program = await ref.watch(programProvider(key.programId).future);
  final matches = program.sessions.where((s) => s.id == key.sessionId).toList();
  return matches.isEmpty ? null : matches.first;
});
