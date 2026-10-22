import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/exercises/data/exercise_notes_repository.dart';
import 'package:lynx_app/features/exercises/presentation/exercise_video.dart';
import 'package:lynx_app/features/exercises/providers/exercise_notes_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// Opens the exercise detail sheet: description, video, a start/stop/reset
/// timer, and the client's **global** notes for this exercise (persist across
/// programs, visible only to them).
Future<void> showExerciseDetailSheet(
  BuildContext context, {
  required String exerciseId,
  required String exerciseName,
  String? description,
  String? videoUrl,
  String? videoStoragePath,
  String? thumbnailStoragePath,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Draggable sheet provides its own grabber below — opt out of the themed
    // handle so there aren't two.
    showDragHandle: false,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _ExerciseDetailSheet(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      description: description,
      videoUrl: videoUrl,
      videoStoragePath: videoStoragePath,
      thumbnailStoragePath: thumbnailStoragePath,
    ),
  );
}

class _ExerciseDetailSheet extends ConsumerStatefulWidget {
  const _ExerciseDetailSheet({
    required this.exerciseId,
    required this.exerciseName,
    this.description,
    this.videoUrl,
    this.videoStoragePath,
    this.thumbnailStoragePath,
  });

  final String exerciseId;
  final String exerciseName;
  final String? description;
  final String? videoUrl;
  final String? videoStoragePath;
  final String? thumbnailStoragePath;

  @override
  ConsumerState<_ExerciseDetailSheet> createState() =>
      _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends ConsumerState<_ExerciseDetailSheet> {
  final _note = TextEditingController();
  bool _seeded = false;
  bool _saving = false;

  bool get _hasVideo =>
      (widget.videoStoragePath != null &&
          widget.videoStoragePath!.trim().isNotEmpty) ||
      (widget.videoUrl != null && widget.videoUrl!.trim().isNotEmpty);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await ExerciseNotesRepository.saveNote(
        tenantId: user.tenantId,
        personId: user.personId,
        exerciseId: widget.exerciseId,
        note: _note.text,
      );
      ref.invalidate(exerciseNoteProvider(widget.exerciseId));
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.show(context, title: l.noteSaved, blur: false);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.show(context, title: e.message, blur: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final noteAsync = ref.watch(exerciseNoteProvider(widget.exerciseId));
    // Seed the editor once, the first time the note loads.
    noteAsync.whenData((text) {
      if (!_seeded) {
        _seeded = true;
        _note.text = text;
      }
    });

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Header: name + timer top-right.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(widget.exerciseName,
                        style: AppTextStyles.heading3),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const WorkoutTimer(compact: true),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Video.
              if (_hasVideo) ...[
                _DetailActionButton(
                  icon: Icons.play_circle_outline,
                  label: l.watchVideo,
                  onTap: () => playExerciseVideo(context,
                      storagePath: widget.videoStoragePath,
                      url: widget.videoUrl),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              // Description.
              Text(l.exerciseDetails.toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                      color: AppColors.textTertiary, letterSpacing: 0.4)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                (widget.description != null &&
                        widget.description!.trim().isNotEmpty)
                    ? widget.description!
                    : l.noDescription,
                style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Notes.
              Text(l.myNotes.toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4)),
              const SizedBox(height: AppSpacing.xs),
              noteAsync.when(
                loading: () => const SkeletonLoader(
                    child: SkeletonBox(
                        width: double.infinity,
                        height: 96,
                        borderRadius: AppRadius.md)),
                error: (_, _) => _noteField(l),
                data: (_) => _noteField(l),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  onPressed: _saving ? null : _saveNote,
                  child: _saving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.onPrimary))
                      : Text(l.saveNote),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _noteField(AppLocalizations l) {
    return TextField(
      controller: _note,
      minLines: 3,
      maxLines: 6,
      cursorColor: AppColors.primary,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: l.myNotesHint,
        hintStyle:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  const _DetailActionButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(label,
                style:
                    AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// A simple count-up workout timer with start/stop/reset. Used in the exercise
/// detail sheet and inline in the runner card (for interval methods).
class WorkoutTimer extends StatefulWidget {
  const WorkoutTimer({super.key, this.compact = false, this.targetSeconds});

  /// A tighter pill layout for headers / cards.
  final bool compact;

  /// Optional target (e.g. an EMOM interval) shown beside the elapsed time.
  final int? targetSeconds;

  @override
  State<WorkoutTimer> createState() => _WorkoutTimerState();
}

class _WorkoutTimerState extends State<WorkoutTimer> {
  Timer? _ticker;
  int _elapsed = 0;
  bool _running = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
    } else {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed++);
      });
      setState(() => _running = true);
    }
  }

  void _reset() {
    HapticFeedback.selectionClick();
    _ticker?.cancel();
    setState(() {
      _running = false;
      _elapsed = 0;
    });
  }

  static String _fmt(int s) =>
      '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final label = widget.targetSeconds != null
        ? '${_fmt(_elapsed)} / ${_fmt(widget.targetSeconds!)}'
        : _fmt(_elapsed);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: widget.compact ? 4 : AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(width: 6),
          _IconBtn(
            icon: _running ? Icons.pause : Icons.play_arrow,
            onTap: _toggle,
          ),
          _IconBtn(icon: Icons.refresh, onTap: _reset),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}
