import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/clients/data/assignment_repository.dart';
import 'package:lynx_app/features/clients/data/models/client_assignment.dart';
import 'package:lynx_app/features/clients/data/client_repository.dart';
import 'package:lynx_app/features/clients/data/models/health_flag.dart';
import 'package:lynx_app/features/clients/presentation/health_flag_labels.dart';
import 'package:lynx_app/features/chat/data/chat_repository.dart';
import 'package:lynx_app/features/chat/data/models/assigned_staff.dart';
import 'package:lynx_app/features/chat/presentation/chat_screen.dart';
import 'package:lynx_app/features/chat/providers/chat_providers.dart';
import 'package:lynx_app/features/clients/providers/clients_provider.dart';
import 'package:lynx_app/features/programs/data/models/program.dart';
import 'package:lynx_app/features/programs/providers/programs_provider.dart';
import 'package:lynx_app/features/review/presentation/client_review_screen.dart';
import 'package:lynx_app/features/review/presentation/session_actuals_screen.dart';
import 'package:lynx_app/features/review/providers/review_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/models/app_user.dart';
import 'package:lynx_app/shared/widgets/app_avatar.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/frosted_nav_scaffold.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';
import 'package:lynx_app/shared/widgets/unread_badge.dart';

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
              // Tight top: the theme drag handle already reserves space above.
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
              child: Text(l.assignProgram, style: AppTextStyles.heading3),
            ),
            for (final p in templates)
              ListTile(
                title: Text(p.name, style: AppTextStyles.body),
                trailing: Icon(Icons.add, color: AppColors.primary),
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

  /// Push new template phases/sessions into an existing assignment so the client
  /// sees the coach's latest edits (additive — existing sessions are untouched).
  Future<void> _pushLatest(
      BuildContext context, WidgetRef ref, ClientAssignment a) async {
    final l = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    try {
      final added = await AssignmentRepository.resyncAssignment(a.id);
      ref.invalidate(clientAssignmentsProvider(personId));
      if (context.mounted) {
        AppToast.show(context,
            title: added > 0 ? l.assignmentSynced(added) : l.assignmentUpToDate);
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

  Future<void> _assignStaff(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    try {
      final all = await ChatRepository.listAssignableStaff(user.tenantId);
      final assigned =
          ref.read(assignedStaffProvider(personId)).valueOrNull ?? const [];
      final assignedIds = assigned.map((s) => s.staffPersonId).toSet();
      final candidates = all
          .where((s) =>
              s.staffPersonId != personId &&
              !assignedIds.contains(s.staffPersonId))
          .toList();
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                // Tight top: the theme drag handle already reserves space above.
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
                child: Text(l.assignStaff, style: AppTextStyles.heading3),
              ),
              if (candidates.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  child: Text(l.noCareTeam, style: AppTextStyles.bodySmall),
                )
              else
                for (final s in candidates)
                  ListTile(
                    leading: AppAvatar(
                      avatarKind: s.avatarKind,
                      avatarValue: s.avatarValue,
                      initials: s.initials,
                      role: s.role,
                    ),
                    title: Text(s.fullName,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(_roleLabel(l, s.role),
                        style: AppTextStyles.bodySmall),
                    trailing: Icon(Icons.add, color: AppColors.primary),
                    onTap: () async {
                      try {
                        await ChatRepository.assignStaff(
                          tenantId: user.tenantId,
                          clientPersonId: personId,
                          staffPersonId: s.staffPersonId,
                          createdBy: user.personId,
                        );
                        ref.invalidate(assignedStaffProvider(personId));
                        if (context.mounted) Navigator.of(context).pop();
                      } on AppException catch (e) {
                        if (context.mounted) {
                          AppToast.show(context, title: e.message, blur: false);
                        }
                      }
                    },
                  ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      );
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _unassignStaff(
      BuildContext context, WidgetRef ref, AssignedStaff s) async {
    try {
      await ChatRepository.unassignStaff(
        clientPersonId: personId,
        staffPersonId: s.staffPersonId,
      );
      ref.invalidate(assignedStaffProvider(personId));
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  static String _roleLabel(AppLocalizations l, AppRole role) {
    switch (role) {
      case AppRole.owner:
        return l.roleOwner;
      case AppRole.physio:
        return l.rolePhysio;
      case AppRole.coach:
      case AppRole.client:
        return l.roleCoach;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final clientAsync = ref.watch(clientProvider(personId));
    final flagsAsync = ref.watch(clientHealthFlagsProvider(personId));
    final assignmentsAsync = ref.watch(clientAssignmentsProvider(personId));
    final careTeamAsync = ref.watch(assignedStaffProvider(personId));
    final completedAsync = ref.watch(clientCompletedProvider(personId));
    final unread =
        ref.watch(coachUnreadCountsProvider).valueOrNull?[personId] ?? 0;

    return FrostedNavScaffold(
      title: clientAsync.valueOrNull?.fullName ?? '…',
      trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppNavBarAction(
                      icon: Icons.chat_bubble_outline,
                      onTap: () {
                        final me =
                            ref.read(currentUserProvider).valueOrNull?.personId;
                        if (me == null) return;
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            clientPersonId: personId,
                            staffPersonId: me,
                            title: clientAsync.valueOrNull?.fullName ??
                                l.chatTitle,
                          ),
                        ));
                      },
                      tooltip: l.openChat,
                    ),
                    if (unread > 0)
                      Positioned(
                          right: -4, top: -4, child: UnreadBadge(count: unread)),
                  ],
                ),
                if (clientAsync.valueOrNull?.hasAccount == false) ...[
                  const SizedBox(width: AppSpacing.sm),
                  AppNavBarAction(
                    icon: Icons.person_add_alt_1,
                    onTap: () => _invite(context, ref),
                    tooltip: l.inviteToApp,
                  ),
                ],
              ],
            ),
      builder: (context, topInset) => SafeArea(
        top: false,
        child: clientAsync.isLoading
            ? _ClientDetailSkeleton(topInset: topInset)
            : ListView(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg,
                    topInset + AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
                children: [
            // Account status
            Text(
              clientAsync.valueOrNull?.hasAccount == true ? l.accountLinked : l.accountNone,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Care team
            _SectionHeader(title: l.careTeam, actionLabel: l.assignStaff,
                onAction: () => _assignStaff(context, ref)),
            const SizedBox(height: AppSpacing.sm),
            careTeamAsync.when(
              loading: () => const _SkeletonRows(height: 64, count: 1),
              error: (_, _) => Text(l.somethingWentWrong, style: AppTextStyles.bodySmall),
              data: (staff) => staff.isEmpty
                  ? Text(l.noCareTeam, style: AppTextStyles.bodySmall)
                  : Column(
                      children: [
                        for (final s in staff)
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              leading: AppAvatar(
                                avatarKind: s.avatarKind,
                                avatarValue: s.avatarValue,
                                initials: s.initials,
                                role: s.role,
                              ),
                              title: Text(s.fullName,
                                  style: AppTextStyles.body
                                      .copyWith(fontWeight: FontWeight.w600)),
                              subtitle: Text(_roleLabel(l, s.role),
                                  style: AppTextStyles.bodySmall),
                              trailing: IconButton(
                                icon: Icon(Icons.close,
                                    color: AppColors.textTertiary),
                                onPressed: () => _unassignStaff(context, ref, s),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Safety flags
            _SectionHeader(title: l.healthFlagsTitle, actionLabel: l.addHealthFlag,
                onAction: () => _addFlag(context, ref)),
            const SizedBox(height: AppSpacing.sm),
            flagsAsync.when(
              loading: () => const _SkeletonRows(height: 44, count: 1),
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
              loading: () => const _SkeletonRows(height: 64, count: 2),
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
                              trailing: IconButton(
                                icon: Icon(Icons.sync, color: AppColors.primary),
                                tooltip: l.pushLatest,
                                onPressed: () => _pushLatest(context, ref, a),
                              ),
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
            const SizedBox(height: AppSpacing.sm),
            completedAsync.when(
              loading: () => const _SkeletonRows(height: 64, count: 1),
              error: (_, _) =>
                  Text(l.somethingWentWrong, style: AppTextStyles.bodySmall),
              data: (sessions) => sessions.isEmpty
                  ? Text(l.reviewEmpty, style: AppTextStyles.bodySmall)
                  : Column(
                      children: [
                        // Preview the few most recent; "View" opens the full list.
                        for (final s in sessions.take(3))
                          AppCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              title: Text('${s.assignmentName} · ${s.label}',
                                  style: AppTextStyles.body
                                      .copyWith(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                MaterialLocalizations.of(context)
                                    .formatFullDate(s.completedAt.toLocal()),
                                style: AppTextStyles.bodySmall,
                              ),
                              trailing: Icon(Icons.chevron_right,
                                  color: AppColors.textTertiary),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => SessionActualsScreen(
                                    sessionId: s.assignmentSessionId,
                                    personId: personId,
                                    title:
                                        '${s.label} · ${clientAsync.valueOrNull?.fullName ?? ''}',
                                  ),
                                ));
                              },
                            ),
                          ),
                      ],
                    ),
            ),
                ],
              ),
            ),
    );
  }
}

/// Full-screen loading placeholder that mirrors the loaded layout: an account
/// status line, then three sections (header + rows) matching the real content.
class _ClientDetailSkeleton extends StatelessWidget {
  const _ClientDetailSkeleton({this.topInset = 0});
  final double topInset;

  @override
  Widget build(BuildContext context) {
    Widget header() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            SkeletonBox(width: 160, height: 20),
            SkeletonBox(width: 96, height: 13),
          ],
        );
    Widget card({double height = 64}) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: SkeletonBox(
              width: double.infinity, height: height, borderRadius: AppRadius.lg),
        );

    return SkeletonLoader(
      child: ListView(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, topInset + AppSpacing.md,
            AppSpacing.lg, AppSpacing.lg),
        children: [
          const SkeletonBox(width: 150, height: 12),
          const SizedBox(height: AppSpacing.lg),
          // Health flags
          header(),
          const SizedBox(height: AppSpacing.sm),
          card(height: 44),
          const SizedBox(height: AppSpacing.xl),
          // Assignments
          header(),
          const SizedBox(height: AppSpacing.sm),
          card(),
          card(),
          const SizedBox(height: AppSpacing.xl),
          // Completed sessions
          header(),
        ],
      ),
    );
  }
}

/// A small shimmering placeholder for a section that's still loading while the
/// rest of the screen is already shown (health flags / assignments).
class _SkeletonRows extends StatelessWidget {
  const _SkeletonRows({required this.height, required this.count});
  final double height;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SkeletonBox(
                  width: double.infinity,
                  height: height,
                  borderRadius: AppRadius.md),
            ),
        ],
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
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
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
            icon: Icon(Icons.close, size: 18, color: AppColors.textTertiary),
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
