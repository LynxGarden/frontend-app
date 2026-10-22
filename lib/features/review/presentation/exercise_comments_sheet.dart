import 'package:flutter/material.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/review/data/feedback_repository.dart';
import 'package:lynx_app/features/review/providers/review_feedback_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the coach comments thread for one assignment-exercise. Shared by the
/// review deep-dive and the per-session actuals screen.
void showExerciseComments(
  BuildContext context, {
  required String personId,
  required String assignmentExerciseId,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Draggable sheet provides its own grabber — opt out of the themed handle.
    showDragHandle: false,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => ExerciseCommentsSheet(
        personId: personId, assignmentExerciseId: assignmentExerciseId),
  );
}

/// The draggable comments thread + composer for one assignment-exercise.
class ExerciseCommentsSheet extends ConsumerStatefulWidget {
  const ExerciseCommentsSheet({
    super.key,
    required this.personId,
    required this.assignmentExerciseId,
  });

  final String personId;
  final String assignmentExerciseId;

  @override
  ConsumerState<ExerciseCommentsSheet> createState() =>
      _ExerciseCommentsSheetState();
}

class _ExerciseCommentsSheetState extends ConsumerState<ExerciseCommentsSheet> {
  final _controller = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    final body = _controller.text.trim();
    if (user == null || body.isEmpty) return;
    setState(() => _posting = true);
    try {
      await FeedbackRepository.addComment(
        tenantId: user.tenantId,
        assignmentExerciseId: widget.assignmentExerciseId,
        authorId: user.personId,
        body: body,
      );
      _controller.clear();
      ref.invalidate(exerciseCommentsProvider(widget.assignmentExerciseId));
      ref.invalidate(clientReviewDataProvider(widget.personId));
      if (mounted) AppToast.show(context, title: l.commentPosted);
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(exerciseCommentsProvider(widget.assignmentExerciseId));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Text(l.comments,
                      style: AppTextStyles.heading3
                          .copyWith(color: AppColors.textPrimary)),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => Center(
                    child: SkeletonLoader(
                        child: SkeletonBox(width: 200, height: 14))),
                error: (_, _) => Center(
                    child: Text(l.somethingWentWrong,
                        style: AppTextStyles.bodySmall)),
                data: (comments) {
                  if (comments.isEmpty) {
                    return Center(
                      child: Text(l.noComments,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textTertiary)),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: comments.length,
                    itemBuilder: (context, i) {
                      final c = comments[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.body, style: AppTextStyles.body),
                            const SizedBox(height: 2),
                            Text(
                              MaterialLocalizations.of(context)
                                  .formatFullDate(c.createdAt),
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: l.commentHint,
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: AppColors.surfaceBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: AppColors.surfaceBorder),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: _posting ? null : _post,
                    icon: Icon(Icons.send, color: AppColors.primary),
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
