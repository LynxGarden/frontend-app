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
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

/// The coach's program template library.
class ProgramListScreen extends ConsumerWidget {
  const ProgramListScreen({super.key});

  Future<void> _openEditor(BuildContext context, WidgetRef ref, String programId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProgramEditorScreen(programId: programId)),
    );
    ref.invalidate(programTemplatesProvider);
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
      if (context.mounted) await _openEditor(context, ref, id);
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final programsAsync = ref.watch(programTemplatesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.programsTitle, style: AppTextStyles.heading3)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l.newProgram),
      ),
      body: SafeArea(
        child: programsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.forest)),
          error: (_, _) =>
              Center(child: Text(l.somethingWentWrong, style: AppTextStyles.bodySmall)),
          data: (programs) => programs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(l.programsEmpty,
                        textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
                  itemCount: programs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _ProgramCard(
                    program: programs[i],
                    onTap: () => _openEditor(context, ref, programs[i].id),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(program.name,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(l.sessionCount(program.sessionCount),
            style: AppTextStyles.bodySmall),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      ),
    );
  }
}
