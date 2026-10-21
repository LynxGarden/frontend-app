import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/exercises/presentation/exercise_library_screen.dart';
import 'package:lynx_app/features/programs/data/models/program.dart';
import 'package:lynx_app/features/programs/data/program_repository.dart';
import 'package:lynx_app/features/programs/presentation/program_editor_screen.dart';
import 'package:lynx_app/features/programs/providers/programs_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_action_sheet.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/main_shell.dart';
import 'package:lynx_app/shared/widgets/reorder_proxy.dart';
import 'package:lynx_app/shared/widgets/skeleton_list.dart';

enum _ProgramAction { duplicate, delete }

/// The coach's program template library — the top-level "Programs" tab.
class ProgramListScreen extends ConsumerStatefulWidget {
  const ProgramListScreen({super.key});

  @override
  ConsumerState<ProgramListScreen> createState() => _ProgramListScreenState();
}

class _ProgramListScreenState extends ConsumerState<ProgramListScreen> {
  /// Local copy for optimistic drag-reorder; kept in sync with the provider.
  List<Program>? _programs;

  String get _tenantId =>
      ref.read(currentUserProvider).valueOrNull?.tenantId ?? '';

  Future<void> _openEditor(String programId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProgramEditorScreen(programId: programId)),
    );
    ref.invalidate(programTemplatesProvider);
  }

  void _openAllExercises() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen(pushed: true)),
    );
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final list = [...?_programs];
    if (oldIndex < 0 || oldIndex >= list.length) return;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    setState(() => _programs = list);
    try {
      await ProgramRepository.setProgramOrder(
        tenantId: _tenantId,
        orderedIds: list.map((p) => p.id).toList(),
      );
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l.newProgram, style: AppTextStyles.heading3),
        content: AppTextField(
            label: l.programName, controller: controller, hintText: l.programNameHint),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(l.done)),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      final id = await ProgramRepository.createProgram(
        tenantId: user.tenantId,
        ownerId: user.personId,
        name: name,
      );
      ref.invalidate(programTemplatesProvider);
      if (context.mounted) await _openEditor(id);
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _openActions(Program program) async {
    final l = AppLocalizations.of(context);
    HapticFeedback.selectionClick();
    final action = await showActionSheet<_ProgramAction>(
      context,
      title: program.name,
      actions: [
        AppSheetAction(
            value: _ProgramAction.duplicate,
            label: l.duplicate,
            icon: Icons.copy_outlined),
        AppSheetAction(
            value: _ProgramAction.delete,
            label: l.delete,
            icon: Icons.delete_outline,
            destructive: true),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _ProgramAction.duplicate:
        await _duplicate(program.id);
      case _ProgramAction.delete:
        await _delete(program.id);
    }
  }

  Future<void> _duplicate(String programId) async {
    final l = AppLocalizations.of(context);
    try {
      await ProgramRepository.duplicateProgram(programId: programId);
      ref.invalidate(programTemplatesProvider);
      if (mounted) AppToast.show(context, title: l.duplicatedToast, blur: false);
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _delete(String programId) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l.deleteProgramTitle, style: AppTextStyles.heading3),
        content: Text(l.deleteProgramBody, style: AppTextStyles.bodySmall),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ProgramRepository.deleteProgram(tenantId: _tenantId, programId: programId);
      ref.invalidate(programTemplatesProvider);
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Keep the local (optimistically-reorderable) copy in sync with the provider.
    ref.listen(programTemplatesProvider, (prev, next) {
      next.whenData((p) {
        if (mounted) setState(() => _programs = p);
      });
    });
    final programsAsync = ref.watch(programTemplatesProvider);
    // Prefer the optimistic local copy (for drag-reorder), but fall back to the
    // provider's current value: `ref.listen` only fires on *changes*.
    final programs = _programs ?? programsAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.programsTitle, style: AppTextStyles.heading3),
        actions: [
          IconButton(
            tooltip: l.allExercises,
            icon: const Icon(Icons.fitness_center_outlined),
            onPressed: _openAllExercises,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: AppBottomBar.fabBottomInset(context)),
        child: FloatingActionButton.extended(
          heroTag: 'fab_programs',
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          onPressed: () => _create(context, ref),
          icon: const Icon(Icons.add),
          label: Text(l.newProgram),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _body(l, programs, programsAsync),
      ),
    );
  }

  Widget _body(
    AppLocalizations l,
    List<Program>? programs,
    AsyncValue<List<Program>> programsAsync,
  ) {
    if (programs == null && programsAsync.isLoading) {
      return const ProgramSkeletonList();
    }
    if (programs == null && programsAsync.hasError) {
      return Center(
          child: Text(l.somethingWentWrong, style: AppTextStyles.bodySmall));
    }
    if (programs == null || programs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(l.programsEmpty,
              textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
        ),
      );
    }

    return ReorderableListView.builder(
      padding:
          const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      itemCount: programs.length,
      proxyDecorator: roundedReorderProxy,
      onReorderItem: _reorder,
      itemBuilder: (_, i) => Padding(
        key: ValueKey(programs[i].id),
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: _ProgramCard(
          program: programs[i],
          onTap: () => _openEditor(programs[i].id),
          onMore: () => _openActions(programs[i]),
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard(
      {required this.program, required this.onTap, required this.onMore});
  final Program program;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        title: Text(program.name,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(l.sessionCount(program.sessionCount),
            style: AppTextStyles.bodySmall),
        trailing: IconButton(
          icon: Icon(Icons.more_horiz, color: AppColors.textTertiary),
          onPressed: onMore,
        ),
      ),
    );
  }
}

