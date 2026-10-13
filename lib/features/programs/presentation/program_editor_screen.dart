import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/programs/data/models/phase.dart';
import 'package:lynx_app/features/programs/data/models/program.dart';
import 'package:lynx_app/features/programs/data/models/training_session.dart';
import 'package:lynx_app/features/programs/data/program_repository.dart';
import 'package:lynx_app/features/programs/presentation/session_editor_screen.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_action_sheet.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/reorder_proxy.dart';
import 'package:lynx_app/shared/widgets/skeleton_list.dart';

/// Edits a program template: name/description + its phases → sessions.
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

  // --- phases ---------------------------------------------------------------
  Future<void> _addPhase() async {
    final l = AppLocalizations.of(context);
    final name = await _promptText(title: l.addPhase, hint: l.phaseNameHint);
    if (name == null || name.trim().isEmpty) return;
    await _guard(() => ProgramRepository.addPhase(
          tenantId: _tenantId,
          programId: widget.programId,
          name: name,
          orderIndex: _program?.phases.length ?? 0,
        ));
  }

  Future<void> _renamePhase(Phase p) async {
    final l = AppLocalizations.of(context);
    final name = await _promptText(
        title: l.renamePhase, hint: l.phaseNameHint, initial: p.name);
    if (name == null || name.trim().isEmpty) return;
    await _guard(() => ProgramRepository.updatePhaseName(
        tenantId: _tenantId, phaseId: p.id, name: name));
  }

  Future<void> _duplicatePhase(Phase p) async {
    final l = AppLocalizations.of(context);
    await _guard(() async {
      await ProgramRepository.duplicatePhase(phaseId: p.id);
    });
    if (mounted) AppToast.show(context, title: l.duplicatedToast, blur: false);
  }

  Future<void> _deletePhase(Phase p) async {
    final l = AppLocalizations.of(context);
    final ok = await _confirm(l.deletePhaseTitle, l.deletePhaseBody);
    if (ok != true) return;
    await _guard(() =>
        ProgramRepository.deletePhase(tenantId: _tenantId, phaseId: p.id));
  }

  Future<void> _movePhase(int index, int delta) async {
    final phases = [...?_program?.phases];
    final target = index + delta;
    if (target < 0 || target >= phases.length) return;
    HapticFeedback.selectionClick();
    final item = phases.removeAt(index);
    phases.insert(target, item);
    _patch(phases: phases);
    await _guard(() => ProgramRepository.setPhaseOrder(
        tenantId: _tenantId, orderedIds: phases.map((p) => p.id).toList()));
  }

  Future<void> _phaseMenu(Phase p) async {
    final l = AppLocalizations.of(context);
    final action = await showActionSheet<String>(
      context,
      title: p.name,
      actions: [
        AppSheetAction(value: 'rename', label: l.renamePhase, icon: Icons.edit_outlined),
        AppSheetAction(value: 'duplicate', label: l.duplicate, icon: Icons.copy_outlined),
        AppSheetAction(
            value: 'delete',
            label: l.delete,
            icon: Icons.delete_outline,
            destructive: true),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case 'rename':
        await _renamePhase(p);
      case 'duplicate':
        await _duplicatePhase(p);
      case 'delete':
        await _deletePhase(p);
    }
  }

  // --- sessions -------------------------------------------------------------
  Future<void> _addSession(Phase phase) async {
    final l = AppLocalizations.of(context);
    final label = await _promptText(title: l.addSession, hint: l.sessionLabelHint);
    if (label == null || label.trim().isEmpty) return;
    await _guard(() => ProgramRepository.addSession(
          tenantId: _tenantId,
          programId: widget.programId,
          phaseId: phase.id,
          label: label,
          orderIndex: phase.sessions.length,
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

  Future<void> _duplicateSession(TrainingSession s) async {
    final l = AppLocalizations.of(context);
    await _guard(() async {
      await ProgramRepository.duplicateSession(sessionId: s.id);
    });
    if (mounted) AppToast.show(context, title: l.duplicatedToast, blur: false);
  }

  Future<void> _deleteSession(TrainingSession s) async {
    final l = AppLocalizations.of(context);
    final ok = await _confirm(l.deleteSessionTitle, l.deleteSessionBody);
    if (ok != true) return;
    await _guard(() =>
        ProgramRepository.deleteSession(tenantId: _tenantId, sessionId: s.id));
  }

  Future<void> _reorderSessions(Phase phase, int oldIndex, int newIndex) async {
    final phases = [...?_program?.phases];
    final idx = phases.indexWhere((p) => p.id == phase.id);
    if (idx < 0) return;
    final sessions = [...phases[idx].sessions];
    final item = sessions.removeAt(oldIndex);
    sessions.insert(newIndex, item);
    phases[idx] = Phase(
      id: phase.id,
      name: phase.name,
      orderIndex: phase.orderIndex,
      sessions: sessions,
    );
    _patch(phases: phases);
    await _guard(() => ProgramRepository.setSessionOrder(
        tenantId: _tenantId, orderedIds: sessions.map((s) => s.id).toList()));
  }

  Future<void> _openSession(TrainingSession s) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          SessionEditorScreen(programId: widget.programId, sessionId: s.id),
    ));
    _reload();
  }

  Future<void> _sessionMenu(TrainingSession s) async {
    final l = AppLocalizations.of(context);
    final action = await showActionSheet<String>(
      context,
      title: s.label,
      actions: [
        AppSheetAction(value: 'edit', label: l.editSession, icon: Icons.tune),
        AppSheetAction(value: 'rename', label: l.renameSession, icon: Icons.edit_outlined),
        AppSheetAction(value: 'duplicate', label: l.duplicate, icon: Icons.copy_outlined),
        AppSheetAction(
            value: 'delete',
            label: l.delete,
            icon: Icons.delete_outline,
            destructive: true),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case 'edit':
        await _openSession(s);
      case 'rename':
        await _renameSession(s);
      case 'duplicate':
        await _duplicateSession(s);
      case 'delete':
        await _deleteSession(s);
    }
  }

  // --- helpers --------------------------------------------------------------
  void _patch({List<Phase>? phases}) {
    final p = _program;
    if (p == null) return;
    setState(() => _program = Program(
          id: p.id,
          ownerId: p.ownerId,
          name: p.name,
          description: p.description,
          isTemplate: p.isTemplate,
          phases: phases ?? p.phases,
        ));
  }

  Future<void> _confirmDeleteProgram() async {
    final l = AppLocalizations.of(context);
    final ok = await _confirm(l.deleteProgramTitle, l.deleteProgramBody);
    if (ok != true) return;
    try {
      await ProgramRepository.deleteProgram(
          tenantId: _tenantId, programId: widget.programId);
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<bool?> _confirm(String title, String body) {
    final l = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppTextStyles.heading3),
        content: Text(body, style: AppTextStyles.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.delete,
                style:
                    AppTextStyles.button.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
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
    final topInset = AppNavBar.estimatedHeight(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_program_editor',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: _addPhase,
        icon: const Icon(Icons.add),
        label: Text(l.addPhase),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _loading
                ? ProgramEditorSkeleton(topInset: topInset)
                : program == null
                    ? Padding(
                        padding: EdgeInsets.only(top: topInset),
                        child: Center(
                            child: Text(l.somethingWentWrong,
                                style: AppTextStyles.bodySmall)),
                      )
                    : SafeArea(
                        top: false,
                        bottom: false,
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(AppSpacing.lg,
                              topInset + AppSpacing.md, AppSpacing.lg, 96),
                          children: [
                            AppTextField(
                                label: l.programName,
                                controller: _name,
                                hintText: l.programNameHint),
                            const SizedBox(height: AppSpacing.sm),
                            AppTextField(
                                label: l.exerciseDescription,
                                controller: _description,
                                hintText: '',
                                maxLines: 2),
                            const SizedBox(height: AppSpacing.md),
                            Align(
                              alignment: Alignment.centerLeft,
                              child:
                                  Text(l.phasesLabel, style: AppTextStyles.label),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (program.phases.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: Text(l.phasesEmpty,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodySmall),
                              )
                            else
                              for (var i = 0; i < program.phases.length; i++)
                                _PhaseSection(
                                  key: ValueKey(program.phases[i].id),
                                  phase: program.phases[i],
                                  isFirst: i == 0,
                                  isLast: i == program.phases.length - 1,
                                  onMenu: () => _phaseMenu(program.phases[i]),
                                  onMoveUp: () => _movePhase(i, -1),
                                  onMoveDown: () => _movePhase(i, 1),
                                  onAddSession: () =>
                                      _addSession(program.phases[i]),
                                  onOpenSession: _openSession,
                                  onSessionMenu: _sessionMenu,
                                  onReorderSessions: (o, n) =>
                                      _reorderSessions(program.phases[i], o, n),
                                ),
                          ],
                        ),
                      ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppNavBar(
              title: l.editProgram,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppNavBarAction(icon: Icons.check, onTap: _saveDetails),
                  const SizedBox(width: AppSpacing.sm),
                  AppNavBarAction(
                    icon: Icons.delete_outline,
                    onTap: _confirmDeleteProgram,
                    tint: AppColors.error,
                  ),
                ],
              ),
              blurred: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// One phase: a titled section with up/down + menu controls and its sessions.
class _PhaseSection extends StatelessWidget {
  const _PhaseSection({
    super.key,
    required this.phase,
    required this.isFirst,
    required this.isLast,
    required this.onMenu,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onAddSession,
    required this.onOpenSession,
    required this.onSessionMenu,
    required this.onReorderSessions,
  });

  final Phase phase;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMenu;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onAddSession;
  final void Function(TrainingSession) onOpenSession;
  final void Function(TrainingSession) onSessionMenu;
  final void Function(int oldIndex, int newIndex) onReorderSessions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  phase.name,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: isFirst ? null : onMoveUp,
                icon: Icon(Icons.keyboard_arrow_up,
                    color: isFirst
                        ? AppColors.textTertiary
                        : AppColors.textSecondary),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: isLast ? null : onMoveDown,
                icon: Icon(Icons.keyboard_arrow_down,
                    color: isLast
                        ? AppColors.textTertiary
                        : AppColors.textSecondary),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onMenu,
                icon: Icon(Icons.more_horiz, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (phase.sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(l.sessionsEmpty, style: AppTextStyles.bodySmall),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: phase.sessions.length,
              proxyDecorator: roundedReorderProxy,
              onReorderItem: onReorderSessions,
              itemBuilder: (context, i) {
                final s = phase.sessions[i];
                return _SessionCard(
                  key: ValueKey(s.id),
                  session: s,
                  onTap: () => onOpenSession(s),
                  onMenu: () => onSessionMenu(s),
                );
              },
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onAddSession();
              },
              icon: Icon(Icons.add, size: 18, color: AppColors.primary),
              label: Text(l.addSession,
                  style: AppTextStyles.button.copyWith(color: AppColors.primary)),
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
    required this.onMenu,
  });

  final TrainingSession session;
  final VoidCallback onTap;
  final VoidCallback onMenu;

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
        trailing: IconButton(
          onPressed: onMenu,
          icon: Icon(Icons.more_horiz, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
