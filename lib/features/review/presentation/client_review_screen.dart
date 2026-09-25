import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/review/presentation/session_actuals_screen.dart';
import 'package:lynx_app/features/review/providers/review_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';

/// A single client's completed sessions (from the client record). Tap one to see
/// the logged actuals.
class ClientReviewScreen extends ConsumerWidget {
  const ClientReviewScreen({
    super.key,
    required this.personId,
    required this.clientName,
  });

  final String personId;
  final String clientName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(clientCompletedProvider(personId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.completedSessions, style: AppTextStyles.heading3),
        backgroundColor: AppColors.background,
      ),
      body: async.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.forest)),
        error: (_, _) =>
            Center(child: Text(l.somethingWentWrong, style: AppTextStyles.bodySmall)),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Text(l.reviewEmpty,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textTertiary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: sessions.length,
            itemBuilder: (context, i) {
              final s = sessions[i];
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: ListTile(
                  title: Text('${s.assignmentName} · ${s.label}',
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    MaterialLocalizations.of(context)
                        .formatFullDate(s.completedAt.toLocal()),
                    style: AppTextStyles.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SessionActualsScreen(
                        sessionId: s.assignmentSessionId,
                        personId: personId,
                        title: '${s.label} · $clientName',
                      ),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
