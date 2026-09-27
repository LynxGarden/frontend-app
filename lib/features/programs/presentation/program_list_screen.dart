import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/programs/data/models/program.dart';
import 'package:lynx_app/features/programs/data/program_repository.dart';
import 'package:lynx_app/features/programs/presentation/program_editor_screen.dart';
import 'package:lynx_app/features/programs/providers/programs_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/reorder_proxy.dart';
import 'package:lynx_app/shared/widgets/skeleton_list.dart';

/// The coach's program template library.
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
    // provider's current value: `ref.listen` only fires on *changes*, so it
    // misses a value that was already resolved before this screen mounted —
    // which otherwise renders the empty state over real data.
    final programs = _programs ?? programsAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.programsTitle, style: AppTextStyles.heading3)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_programs',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.newProgram),
      ),
      body: SafeArea(
        bottom: false,
        child: programs == null && programsAsync.isLoading
            ? const ProgramSkeletonList()
            : programs == null && programsAsync.hasError
                ? Center(
                    child: Text(l.somethingWentWrong,
                        style: AppTextStyles.bodySmall))
                : (programs == null || programs.isEmpty)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(l.programsEmpty,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall),
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
                        itemCount: programs.length,
                        proxyDecorator: roundedReorderProxy,
                        onReorderItem: _reorder,
                        itemBuilder: (_, i) => Padding(
                          key: ValueKey(programs[i].id),
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ProgramCard(
                            program: programs[i],
                            onTap: () => _openEditor(programs[i].id),
                          ),
                        ),
                      ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program, required this.onTap});
  final Program program;
  final VoidCallback onTap;

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
        trailing: Icon(Icons.chevron_right, color: AppColors.textTertiary),
      ),
    );
  }
}
