import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/training/data/models/active_assignment.dart';
import 'package:lynx_app/features/training/presentation/session_runner_screen.dart';
import 'package:lynx_app/features/training/providers/training_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_card.dart';
import 'package:lynx_app/shared/widgets/collapsing_header.dart';

/// The client's Train tab: their active program as a menu of sessions. Tapping a
/// session opens the runner. The most-recently-completed session is badged.
class TrainScreen extends ConsumerStatefulWidget {
  const TrainScreen({super.key});

  @override
  ConsumerState<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends ConsumerState<TrainScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(activeAssignmentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.forest,
        onRefresh: () => ref.refresh(activeAssignmentProvider.future),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverCollapsingHeader(title: l.trainTitle, controller: _scroll),
            async.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.forest)),
              ),
              error: (_, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: _Message(
                  icon: Icons.wifi_off_rounded,
                  title: l.somethingWentWrong,
                  body: l.offlineTraining,
                ),
              ),
              data: (assignment) {
                if (assignment == null || assignment.sessions.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Message(
                      icon: Icons.fitness_center,
                      title: l.noProgramAssigned,
                      body: l.noProgramAssignedBody,
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
                  sliver: SliverList.builder(
                    itemCount: assignment.sessions.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(assignment.name,
                              style: AppTextStyles.heading3
                                  .copyWith(color: AppColors.textSecondary)),
                        );
                      }
                      final session = assignment.sessions[i - 1];
                      return _SessionCard(
                        session: session,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SessionRunnerScreen(
                                assignmentId: assignment.id,
                                sessionId: session.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onTap});

  final TrainingAssignmentSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (session.isCompleted) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const _CompletedBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l.sessionCount(session.exercises.length),
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 13, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            l.completedBadge,
            style: AppTextStyles.label.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xxl * 2, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            children: [
              Icon(icon, size: 44, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.md),
              Text(title,
                  textAlign: TextAlign.center, style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.sm),
              Text(body,
                  textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
