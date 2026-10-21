import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseQueryBuilder;

import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/programs/data/models/program.dart';
import 'package:lynx_app/features/programs/data/models/training_method.dart';

/// Prescription fields + training method for a session exercise (build-time
/// targets). Mostly text so coaches can write ranges / free-form values.
class PrescriptionInput {
  const PrescriptionInput({
    this.sets,
    this.reps,
    this.weight,
    this.loadIntensity,
    this.rpe,
    this.rir,
    this.timeSeconds,
    this.tempo,
    this.restSeconds,
    this.setTypeNote,
    this.coachNote,
    this.method = TrainingMethod.straight,
    this.methodGroupId,
    this.groupOrder = 0,
    this.methodConfig = const {},
    this.weekLabel,
    this.targetMetrics = const {},
  });

  final int? sets;
  final String? reps;
  final String? weight;
  final String? loadIntensity;
  final String? rpe;
  final String? rir;
  final int? timeSeconds;
  final String? tempo;
  final int? restSeconds;
  final String? setTypeNote;
  final String? coachNote;
  final TrainingMethod method;
  final String? methodGroupId;
  final int groupOrder;
  final Map<String, dynamic> methodConfig;
  final String? weekLabel;

  /// Per-metric prescribed targets keyed by metric-field key. Only meaningful
  /// for method = none (schema-driven exercises); empty otherwise.
  final Map<String, String> targetMetrics;

  Map<String, dynamic> toColumns() => {
        'sets': sets,
        'reps': _blankNull(reps),
        'weight': _blankNull(weight),
        'load_intensity': _blankNull(loadIntensity),
        'rpe': _blankNull(rpe),
        'rir': _blankNull(rir),
        'time_seconds': timeSeconds,
        'tempo': _blankNull(tempo),
        'rest_seconds': restSeconds,
        'set_type_note': _blankNull(setTypeNote),
        'coach_note': _blankNull(coachNote),
        'method': methodToDb(method),
        'method_group_id': methodGroupId,
        'group_order': groupOrder,
        'method_config': methodConfig,
        'week_label': _blankNull(weekLabel),
        'target_metrics': targetMetrics,
      };

  static String? _blankNull(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}

/// Tenant-scoped data access for the program builder + template library.
/// Hierarchy: Program → Phase → Session → SessionExercise.
class ProgramRepository {
  const ProgramRepository._();

  static const _sessionExerciseCols =
      'id, exercise_id, order_index, sets, reps, weight, load_intensity, rpe, '
      'rir, time_seconds, tempo, rest_seconds, set_type_note, coach_note, '
      'method, method_group_id, group_order, method_config, week_label, '
      'target_metrics, '
      'exercises(name, video_url, thumbnail_storage_path, metric_schema)';

  static const _fullSelect = 'id, owner_id, name, description, is_template, '
      'phases(id, name, order_index, '
      'sessions(id, label, order_index, phase_id, '
      'session_exercises($_sessionExerciseCols)))';

  static SupabaseQueryBuilder _t(String table) => SupabaseClientWrapper.db(table);

  /// Shallow template list (with session ids for a count, nested under phases).
  static Future<List<Program>> listTemplates({
    required String tenantId,
    required String ownerId,
  }) async {
    try {
      final rows = await _t('programs')
          .select(
              'id, owner_id, name, description, is_template, phases(id, order_index, sessions(id))')
          .eq('tenant_id', tenantId)
          .eq('owner_id', ownerId)
          .eq('is_template', true)
          .order('sort_order')
          .order('name');
      return (rows as List)
          .map((r) => Program.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw AppException('Could not load your programs.', cause: e);
    }
  }

  /// Persist a manual drag-to-reorder of the program list.
  static Future<void> setProgramOrder({
    required String tenantId,
    required List<String> orderedIds,
  }) async {
    try {
      for (var i = 0; i < orderedIds.length; i++) {
        await _t('programs')
            .update({'sort_order': i})
            .eq('id', orderedIds[i])
            .eq('tenant_id', tenantId);
      }
    } catch (e) {
      throw AppException('Could not reorder programs.', cause: e);
    }
  }

  /// Full program with phases → sessions → exercises (sorted in the models).
  static Future<Program> loadProgram({
    required String tenantId,
    required String programId,
  }) async {
    try {
      final row = await _t('programs')
          .select(_fullSelect)
          .eq('id', programId)
          .eq('tenant_id', tenantId)
          .single();
      return Program.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException('Could not load the program.', cause: e);
    }
  }

  static Future<String> createProgram({
    required String tenantId,
    required String ownerId,
    required String name,
    String? description,
  }) async {
    try {
      final row = await _t('programs')
          .insert({
            'tenant_id': tenantId,
            'owner_id': ownerId,
            'created_by': ownerId,
            'name': name.trim(),
            'description': PrescriptionInput._blankNull(description),
            'is_template': true,
          })
          .select('id')
          .single();
      final programId = row['id'] as String;
      // A program always starts with one phase so sessions have a home.
      await addPhase(tenantId: tenantId, programId: programId, name: 'Phase 1', orderIndex: 0);
      return programId;
    } catch (e) {
      throw AppException('Could not create the program.', cause: e);
    }
  }

  static Future<void> updateProgram({
    required String tenantId,
    required String programId,
    required String name,
    String? description,
  }) async {
    try {
      await _t('programs').update({
        'name': name.trim(),
        'description': PrescriptionInput._blankNull(description),
      }).eq('id', programId).eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not save the program.', cause: e);
    }
  }

  static Future<void> deleteProgram({
    required String tenantId,
    required String programId,
  }) async {
    try {
      await _t('programs').delete().eq('id', programId).eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not delete the program.', cause: e);
    }
  }

  /// Deep-copy a whole program (phases + sessions + exercises). Returns new id.
  static Future<String> duplicateProgram({
    required String programId,
    String? name,
  }) async {
    try {
      final params = <String, dynamic>{'p_program': programId};
      if (name != null) params['p_name'] = name;
      return await SupabaseClientWrapper.rpc<String>(
        'duplicate_program',
        params: params,
      );
    } catch (e) {
      throw AppException('Could not duplicate the program.', cause: e);
    }
  }

  // --- phases ---------------------------------------------------------------
  static Future<String> addPhase({
    required String tenantId,
    required String programId,
    required String name,
    required int orderIndex,
  }) async {
    try {
      final row = await _t('phases')
          .insert({
            'tenant_id': tenantId,
            'program_id': programId,
            'name': name.trim(),
            'order_index': orderIndex,
          })
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      throw AppException('Could not add the phase.', cause: e);
    }
  }

  static Future<void> updatePhaseName({
    required String tenantId,
    required String phaseId,
    required String name,
  }) async {
    try {
      await _t('phases')
          .update({'name': name.trim()})
          .eq('id', phaseId)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not rename the phase.', cause: e);
    }
  }

  static Future<void> deletePhase({
    required String tenantId,
    required String phaseId,
  }) async {
    try {
      await _t('phases').delete().eq('id', phaseId).eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not delete the phase.', cause: e);
    }
  }

  static Future<void> setPhaseOrder({
    required String tenantId,
    required List<String> orderedIds,
  }) async {
    try {
      for (var i = 0; i < orderedIds.length; i++) {
        await _t('phases')
            .update({'order_index': i})
            .eq('id', orderedIds[i])
            .eq('tenant_id', tenantId);
      }
    } catch (e) {
      throw AppException('Could not reorder phases.', cause: e);
    }
  }

  static Future<String> duplicatePhase({required String phaseId}) async {
    try {
      return await SupabaseClientWrapper.rpc<String>(
        'duplicate_phase',
        params: {'p_phase': phaseId},
      );
    } catch (e) {
      throw AppException('Could not duplicate the phase.', cause: e);
    }
  }

  // --- sessions -------------------------------------------------------------
  static Future<String> addSession({
    required String tenantId,
    required String programId,
    required String phaseId,
    required String label,
    required int orderIndex,
  }) async {
    try {
      final row = await _t('sessions')
          .insert({
            'tenant_id': tenantId,
            'program_id': programId,
            'phase_id': phaseId,
            'label': label.trim(),
            'order_index': orderIndex,
          })
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      throw AppException('Could not add the session.', cause: e);
    }
  }

  static Future<void> updateSessionLabel({
    required String tenantId,
    required String sessionId,
    required String label,
  }) async {
    try {
      await _t('sessions')
          .update({'label': label.trim()})
          .eq('id', sessionId)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not rename the session.', cause: e);
    }
  }

  static Future<void> deleteSession({
    required String tenantId,
    required String sessionId,
  }) async {
    try {
      await _t('sessions').delete().eq('id', sessionId).eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not delete the session.', cause: e);
    }
  }

  static Future<void> setSessionOrder({
    required String tenantId,
    required List<String> orderedIds,
  }) async {
    try {
      for (var i = 0; i < orderedIds.length; i++) {
        await _t('sessions')
            .update({'order_index': i})
            .eq('id', orderedIds[i])
            .eq('tenant_id', tenantId);
      }
    } catch (e) {
      throw AppException('Could not reorder sessions.', cause: e);
    }
  }

  static Future<String> duplicateSession({required String sessionId}) async {
    try {
      return await SupabaseClientWrapper.rpc<String>(
        'duplicate_session',
        params: {'p_session': sessionId},
      );
    } catch (e) {
      throw AppException('Could not duplicate the session.', cause: e);
    }
  }

  // --- session exercises ----------------------------------------------------
  static Future<String> addSessionExercise({
    required String tenantId,
    required String sessionId,
    required String exerciseId,
    required int orderIndex,
    PrescriptionInput prescription = const PrescriptionInput(),
  }) async {
    try {
      final row = await _t('session_exercises')
          .insert({
            'tenant_id': tenantId,
            'session_id': sessionId,
            'exercise_id': exerciseId,
            'order_index': orderIndex,
            ...prescription.toColumns(),
          })
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      throw AppException('Could not add the exercise.', cause: e);
    }
  }

  static Future<void> updateSessionExercise({
    required String tenantId,
    required String sessionExerciseId,
    required PrescriptionInput prescription,
  }) async {
    try {
      await _t('session_exercises')
          .update(prescription.toColumns())
          .eq('id', sessionExerciseId)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not save the prescription.', cause: e);
    }
  }

  static Future<void> deleteSessionExercise({
    required String tenantId,
    required String sessionExerciseId,
  }) async {
    try {
      await _t('session_exercises')
          .delete()
          .eq('id', sessionExerciseId)
          .eq('tenant_id', tenantId);
    } catch (e) {
      throw AppException('Could not remove the exercise.', cause: e);
    }
  }

  static Future<void> setExerciseOrder({
    required String tenantId,
    required List<String> orderedIds,
  }) async {
    try {
      for (var i = 0; i < orderedIds.length; i++) {
        await _t('session_exercises')
            .update({'order_index': i})
            .eq('id', orderedIds[i])
            .eq('tenant_id', tenantId);
      }
    } catch (e) {
      throw AppException('Could not reorder exercises.', cause: e);
    }
  }
}
