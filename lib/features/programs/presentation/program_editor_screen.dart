import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/programs/data/models/program.dart';
import 'package:lynx_app/features/programs/data/models/training_session.dart';
import 'package:lynx_app/features/programs/data/program_repository.dart';
import 'package:lynx_app/features/programs/presentation/session_editor_screen.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

/// Edits a program template: name/description + its ordered sessions.
class ProgramEditorScreen extends ConsumerStatefulWidget {
  const ProgramEditorScreen({super.key, required this.programId});
  final String programId;

  @override
  ConsumerState<ProgramEditorScreen> createState() => _ProgramEditorScreenState();
}

class _ProgramEditorScreenState extends ConsumerState<ProgramEditorScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  Program? _program;
  bool _loading = true;

  String get _tenantId =>
      ref.read(currentUserProvider).valueOrNull?.tenantId ?? '';

  @override
  void initState() {
    super.initState();
    _reload(initial: true);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _reload({bool initial = false}) async {
    try {
      final program = await ProgramRepository.loadProgram(
        tenantId: _tenantId,
        programId: widget.programId,
      );
      if (!mounted) return;
      setState(() {
        _program = program;
        _loading = false;
        if (initial) {
          _name.text = program.name;
          _description.text = program.description ?? '';
        }
      });
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppToast.show(context, title: e.message, blur: false);
      }
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
      await _reload();
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _saveDetails() => _guard(() => ProgramRepository.updateProgram(
        tenantId: _tenantId,
        programId: widget.programId,
        name: _name.text,
        description: _description.text,
      ));

  Future<void> _addSession() async {
    final l = AppLocalizations.of(context);
    final label = await _promptText(title: l.addSession, hint: l.sessionLabelHint);
    if (label == null || label.trim().isEmpty) return;
    await _guard(() => ProgramRepository.addSession(
          tenantId: _tenantId,
          programId: widget.programId,
          label: label,
          orderIndex: _program?.sessions.length ?? 0,
        ));
  }

  Future<void> _renameSession(TrainingSession s) async {
    final l = AppLocalizations.of(context);
    final label = await _promptText(
        title: l.renameSession, hint: l.sessionLabelHint, initial: s.label);
    if (label == null || label.trim().isEmpty) return;
    await _guard(() => ProgramRepository.updateSessionLabel(
        tenantId: _tenantId, sessionId: s.id, label: label));
  }

  Future<void> _deleteSession(TrainingSession s) => _guard(() =>
      ProgramRepository.deleteSession(tenantId: _tenantId, sessionId: s.id));

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final list = [...?_program?.sessions];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    setState(() => _program = _program == null
        ? null
        : Program(
            id: _program!.id,
            ownerId: _program!.ownerId,
            name: _program!.name,
            description: _program!.description,
            isTemplate: _program!.isTemplate,
            sessions: list,
          ));
    await _guard(() => ProgramRepository.setSessionOrder(
        tenantId: _tenantId, orderedIds: list.map((s) => s.id).toList()));
  }

  Future<void> _openSession(TrainingSession s) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          SessionEditorScreen(programId: widget.programId, sessionId: s.id),
    ));
    _reload();
  }

  Future<void> _confirmDeleteProgram() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l.deleteProgramTitle, style: AppTextStyles.heading3),
        content: Text(l.deleteProgramBody, style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.delete, style: AppTextStyles.button.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ProgramRepository.deleteProgram(
          tenantId: _tenantId, programId: widget.programId);
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<String?> _promptText({
    required String title,
    required String hint,
    String initial = '',
  }) {
    final controller = TextEditingController(text: initial);
    final l = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppTextStyles.heading3),
        content: AppTextField(label: title, controller: controller, hintText: hint),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l.done),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final program = _program;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.onPrimary,
        onPressed: _addSession,
        icon: const Icon(Icons.add),
        label: Text(l.addSession),
      ),
      body: Column(
        children: [
          AppNavBar(
            title: l.editProgram,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppNavBarAction(
                  icon: Icons.check,
                  onTap: _saveDetails,
                ),
                const SizedBox(width: AppSpacing.sm),
                AppNavBarAction(
                  icon: Icons.delete_outline,
                  onTap: _confirmDeleteProgram,
                  tint: AppColors.error,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.forest))
                : program == null
                    ? Center(
                        child: Text(l.somethingWentWrong,
                            style: AppTextStyles.bodySmall))
                    : SafeArea(
                        top: false,
                        child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                      child: Column(
                        children: [
                          AppTextField(
                              label: l.programName, controller: _name, hintText: l.programNameHint),
                          const SizedBox(height: AppSpacing.sm),
                          AppTextField(
                              label: l.exerciseDescription,
                              controller: _description,
                              hintText: '',
                              maxLines: 2),
                          const SizedBox(height: AppSpacing.md),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(l.sessionsLabel, style: AppTextStyles.label),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: program.sessions.isEmpty
                          ? Center(child: Text(l.comingSoon, style: AppTextStyles.bodySmall))
                          : ReorderableListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
                              itemCount: program.sessions.length,
                              onReorderItem: _reorder,
                              itemBuilder: (context, i) {
                                final s = program.sessions[i];
                                return _SessionCard(
                                  key: ValueKey(s.id),
                                  session: s,
                                  onTap: () => _openSession(s),
                                  onRename: () => _renameSession(s),
                                  onDelete: () => _deleteSession(s),
                                );
                              },
                            ),
                    ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    super.key,
    required this.session,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final TrainingSession session;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
          onTap: onTap,
          title: Text(session.label,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(l.exerciseCount(session.exercises.length),
              style: AppTextStyles.bodySmall),
          trailing: PopupMenuButton<String>(
            onSelected: (v) => v == 'rename' ? onRename() : onDelete(),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'rename', child: Text(l.renameSession)),
              PopupMenuItem(value: 'delete', child: Text(l.delete)),
            ],
          ),
        ),
    );
  }
}
