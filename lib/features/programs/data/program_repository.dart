import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseQueryBuilder;

import 'package:lynx_app/core/supabase/supabase_client.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/programs/data/models/program.dart';

/// Prescription fields for a session exercise (build-time targets). Mostly text
/// so coaches can write ranges / free-form values.
class PrescriptionInput {
  const PrescriptionInput({
    this.sets,
    this.reps,
    this.weight,
    this.loadIntensity,
    this.rpe,
    this.timeSeconds,
    this.tempo,
    this.restSeconds,
    this.setTypeNote,
    this.coachNote,
  });

  final int? sets;
  final String? reps;
  final String? weight;
  final String? loadIntensity;
  final String? rpe;
  final int? timeSeconds;
  final String? tempo;
  final int? restSeconds;
  final String? setTypeNote;
  final String? coachNote;

  Map<String, dynamic> toColumns() => {
        'sets': sets,
        'reps': _blankNull(reps),
        'weight': _blankNull(weight),
        'load_intensity': _blankNull(loadIntensity),
        'rpe': _blankNull(rpe),
        'time_seconds': timeSeconds,
        'tempo': _blankNull(tempo),
        'rest_seconds': restSeconds,
        'set_type_note': _blankNull(setTypeNote),
        'coach_note': _blankNull(coachNote),
      };

  static String? _blankNull(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}

/// Tenant-scoped data access for the program builder + template library.
class ProgramRepository {
  const ProgramRepository._();

  static const _fullSelect =
      'id, owner_id, name, description, is_template, '
      'sessions(id, label, order_index, '
      'session_exercises(id, exercise_id, order_index, sets, reps, weight, '
      'load_intensity, rpe, time_seconds, tempo, rest_seconds, set_type_note, '
      'coach_note, exercises(name, video_url)))';

  static SupabaseQueryBuilder _t(String table) => SupabaseClientWrapper.db(table);

  /// Shallow template list (with session ids for a count).
  static Future<List<Program>> listTemplates({
    required String tenantId,
    required String ownerId,
  }) async {
    try {
      final rows = await _t('programs')
          .select('id, owner_id, name, description, is_template, sessions(id)')
          .eq('tenant_id', tenantId)
          .eq('owner_id', ownerId)
          .eq('is_template', true)
          .order('name');
      return (rows as List)
          .map((r) => Program.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw AppException('Could not load your programs.', cause: e);
    }
  }

  /// Full program with sessions + exercises (sorted in the models).
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
      return row['id'] as String;
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

  // --- sessions -------------------------------------------------------------
  static Future<String> addSession({
    required String tenantId,
    required String programId,
    required String label,
    required int orderIndex,
  }) async {
    try {
      final row = await _t('sessions')
          .insert({
            'tenant_id': tenantId,
            'program_id': programId,
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
