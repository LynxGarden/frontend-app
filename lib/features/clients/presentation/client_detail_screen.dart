import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/clients/data/assignment_repository.dart';
import 'package:lynx_app/features/clients/data/client_repository.dart';
import 'package:lynx_app/features/clients/data/models/health_flag.dart';
import 'package:lynx_app/features/clients/presentation/health_flag_labels.dart';
import 'package:lynx_app/features/clients/providers/clients_provider.dart';
import 'package:lynx_app/features/programs/data/models/program.dart';
import 'package:lynx_app/features/programs/providers/programs_provider.dart';
import 'package:lynx_app/features/review/presentation/client_review_screen.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

/// Client record: profile + safety flags + assigned programs, with assign and
/// invite actions.
class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.personId});
  final String personId;

  Future<void> _addFlag(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final result = await showDialog<_FlagInput>(
      context: context,
      builder: (_) => const _AddFlagDialog(),
    );
    if (result == null) return;
    try {
      await ClientRepository.addHealthFlag(
        tenantId: user.tenantId,
        personId: personId,
        recordedBy: user.personId,
        flagType: result.type,
        value: result.value,
        notes: result.notes,
      );
      ref.invalidate(clientHealthFlagsProvider(personId));
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _deleteFlag(BuildContext context, WidgetRef ref, HealthFlag flag) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    try {
      await ClientRepository.deleteHealthFlag(tenantId: user.tenantId, flagId: flag.id);
      ref.invalidate(clientHealthFlagsProvider(personId));
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _assign(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final templates = await ref.read(programTemplatesProvider.future);
    if (!context.mounted) return;
    if (templates.isEmpty) {
      AppToast.show(context, title: l.programsEmpty, blur: false);
      return;
    }
    final chosen = await showModalBottomSheet<Program>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(l.assignProgram, style: AppTextStyles.heading3),
            ),
            for (final p in templates)
              ListTile(
                title: Text(p.name, style: AppTextStyles.body),
                trailing: const Icon(Icons.add, color: AppColors.forest),
                onTap: () => Navigator.of(context).pop(p),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    try {
      await AssignmentRepository.assignTemplate(
        programId: chosen.id,
        personId: personId,
      );
      ref.invalidate(clientAssignmentsProvider(personId));
      if (context.mounted) {
        AppToast.show(context, title: chosen.name, subtitle: l.assignmentsTitle, blur: false);
      }
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    try {
      final code = await ClientRepository.createInvite(
        tenantId: user.tenantId,
        personId: personId,
        invitedBy: user.personId,
      );
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(l.inviteCodeTitle, style: AppTextStyles.heading3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.inviteCodeBody, style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.md),
              SelectableText(code,
                  style: AppTextStyles.heading2.copyWith(letterSpacing: 4)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.of(context).pop();
              },
              child: Text(l.done),
            ),
          ],
        ),
      );
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final clientAsync = ref.watch(clientProvider(personId));
    final flagsAsync = ref.watch(clientHealthFlagsProvider(personId));
    final assignmentsAsync = ref.watch(clientAssignmentsProvider(personId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(clientAsync.valueOrNull?.fullName ?? '…',
            style: AppTextStyles.heading3),
        actions: [
          if (clientAsync.valueOrNull?.hasAccount == false)
            TextButton(
              onPressed: () => _invite(context, ref),
              child: Text(l.inviteToApp,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.forest)),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Account status
            Text(
              clientAsync.valueOrNull?.hasAccount == true ? l.accountLinked : l.accountNone,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Safety flags
            _SectionHeader(title: l.healthFlagsTitle, actionLabel: l.addHealthFlag,
                onAction: () => _addFlag(context, ref)),
            const SizedBox(height: AppSpacing.sm),
            flagsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(l.somethingWentWrong, style: AppTextStyles.bodySmall),
              data: (flags) => flags.isEmpty
                  ? Text(l.noHealthFlags, style: AppTextStyles.bodySmall)
                  : Column(
                      children: [
                        for (final f in flags)
                          _FlagRow(
                            flag: f,
                            onDelete: () => _deleteFlag(context, ref, f),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Assignments
            _SectionHeader(title: l.assignmentsTitle, actionLabel: l.assignProgram,
                onAction: () => _assign(context, ref)),
            const SizedBox(height: AppSpacing.sm),
            assignmentsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(l.somethingWentWrong, style: AppTextStyles.bodySmall),
              data: (assignments) => assignments.isEmpty
                  ? Text(l.noAssignments, style: AppTextStyles.bodySmall)
                  : Column(
                      children: [
                        for (final a in assignments)
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              title: Text(a.name,
                                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                              subtitle: Text(l.sessionCount(a.sessionCount),
                                  style: AppTextStyles.bodySmall),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Completed sessions (coach review)
            _SectionHeader(
              title: l.completedSessions,
              actionLabel: l.view,
              onAction: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ClientReviewScreen(
                  personId: personId,
                  clientName: clientAsync.valueOrNull?.fullName ?? '',
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionLabel, required this.onAction});
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.heading3),
        GestureDetector(
          onTap: onAction,
          child: Text('+ $actionLabel',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
        ),
      ],
    );
  }
}

class _FlagRow extends StatelessWidget {
  const _FlagRow({required this.flag, required this.onDelete});
  final HealthFlag flag;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final subtitle = [
      if (flag.value != null && flag.value!.isNotEmpty) flag.value!,
      if (flag.notes != null && flag.notes!.isNotEmpty) flag.notes!,
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(healthFlagLabel(l, flag.flagType),
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textTertiary),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _FlagInput {
  const _FlagInput(this.type, this.value, this.notes);
  final String type;
  final String? value;
  final String? notes;
}

class _AddFlagDialog extends StatefulWidget {
  const _AddFlagDialog();
  @override
  State<_AddFlagDialog> createState() => _AddFlagDialogState();
}

class _AddFlagDialogState extends State<_AddFlagDialog> {
  String _type = kHealthFlagTypes.first;
  final _value = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l.addHealthFlag, style: AppTextStyles.heading3),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: _type,
              isExpanded: true,
              onChanged: (v) => setState(() => _type = v ?? _type),
              items: [
                for (final t in kHealthFlagTypes)
                  DropdownMenuItem(value: t, child: Text(healthFlagLabel(l, t))),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(label: l.flagValue, controller: _value, hintText: ''),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(label: l.flagNotes, controller: _notes, hintText: '', maxLines: 2),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, _FlagInput(_type, _value.text, _notes.text)),
          child: Text(l.save),
        ),
      ],
    );
  }
}
