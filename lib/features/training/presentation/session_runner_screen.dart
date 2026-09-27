import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/exercises/data/exercise_repository.dart';
import 'package:lynx_app/features/exercises/presentation/exercise_video.dart';
import 'package:lynx_app/features/programs/presentation/exercise_picker_sheet.dart';
import 'package:lynx_app/features/training/data/models/active_assignment.dart';
import 'package:lynx_app/features/training/data/training_repository.dart';
import 'package:lynx_app/features/training/providers/training_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/models/app_user.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/frosted_nav_scaffold.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// The gym-facing session runner: a full-width **carousel** the client swipes
/// through. Swiping cycles through the current exercise's **sets** (the dots
/// under the name) first; once its sets are done, the next swipe moves to the
/// next exercise. Swiping past the last exercise lands on a completion card.
///
/// Under the hood it's one flat `PageView` whose pages are every (exercise, set)
/// pair in order, plus a trailing completion page. The top selector reflects the
/// current exercise; the dots reflect the current set within it.
class SessionRunnerScreen extends ConsumerStatefulWidget {
  const SessionRunnerScreen({
    super.key,
    required this.assignmentId,
    required this.sessionId,
  });

  final String assignmentId;
  final String sessionId;

  @override
  ConsumerState<SessionRunnerScreen> createState() => _SessionRunnerScreenState();
}

class _SessionRunnerScreenState extends ConsumerState<SessionRunnerScreen> {
  // Only the bottom set-input area pages; the card frame stays put, so no peek.
  final _pageController = PageController();
  int _page = 0;
  bool _completing = false;

  /// Per-exercise set slots, keyed by `assignment_exercises.id`. Persists across
  /// rebuilds (and provider refetches) so logged state / dots survive.
  final Map<String, List<_SetSlot>> _slots = {};

  RunnerKey get _key =>
      (assignmentId: widget.assignmentId, sessionId: widget.sessionId);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Make sure every current exercise has a slot list (creates them the first
  /// time; keeps existing ones so logged state is preserved across refetches).
  void _ensureSlots(List<TrainingExercise> exercises) {
    for (final e in exercises) {
      if (_slots.containsKey(e.id)) continue;
      final n = (e.sets != null && e.sets! > 0) ? e.sets! : 1;
      _slots[e.id] = List.generate(n, (_) => _SetSlot());
    }
  }

  /// Flatten exercises → one entry per (exerciseIndex, setIndex), in order.
  List<({int ex, int set})> _flatten(List<TrainingExercise> exercises) {
    final pages = <({int ex, int set})>[];
    for (var e = 0; e < exercises.length; e++) {
      final count = _slots[exercises[e].id]!.length;
      for (var s = 0; s < count; s++) {
        pages.add((ex: e, set: s));
      }
    }
    return pages;
  }

  int _firstPageOfExercise(List<TrainingExercise> exercises, int exIndex) {
    var idx = 0;
    for (var e = 0; e < exIndex; e++) {
      idx += _slots[exercises[e].id]!.length;
    }
    return idx;
  }

  void _goToPage(int i) {
    // Haptic comes from onPageChanged, so a tap-to-jump and a manual swipe both
    // buzz exactly once.
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  // The bottom pager's own scrolling is disabled; the whole card forwards
  // horizontal drags here so you can swipe anywhere (incl. the thumbnail).
  void _onCardDragUpdate(DragUpdateDetails d) {
    if (!_pageController.hasClients) return;
    final pos = _pageController.position;
    _pageController
        .jumpTo((pos.pixels - d.delta.dx).clamp(0.0, pos.maxScrollExtent));
  }

  void _onCardDragEnd(DragEndDetails d, int lastIndex) {
    if (!_pageController.hasClients) return;
    final page = _pageController.page ?? 0;
    final v = d.primaryVelocity ?? 0;
    int target;
    if (v < -250) {
      target = page.ceil(); // fling left → next
    } else if (v > 250) {
      target = page.floor(); // fling right → prev
    } else {
      target = page.round();
    }
    _pageController.animateToPage(
      target.clamp(0, lastIndex),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Future<void> _swap(TrainingExercise ex) async {
    final l = AppLocalizations.of(context);
    final replacement = await showExercisePicker(context);
    if (replacement == null || !mounted) return;
    try {
      await TrainingRepository.swapExercise(
        assignmentExerciseId: ex.id,
        newExerciseId: replacement.id,
      );
      ref.invalidate(activeAssignmentProvider);
      ref.invalidate(sessionRunnerProvider(_key));
      if (mounted) AppToast.show(context, title: l.exerciseSwappedToast, blur: false);
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _complete(TrainingAssignmentSession session) async {
    final l = AppLocalizations.of(context);
    setState(() => _completing = true);
    try {
      await TrainingRepository.completeSession(session.id);
      ref.invalidate(activeAssignmentProvider);
      HapticFeedback.heavyImpact();
      if (mounted) {
        AppToast.show(context, title: l.sessionDoneToast, blur: false);
        Navigator.of(context).pop();
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _completing = false);
        AppToast.show(context, title: e.message, blur: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final async = ref.watch(sessionRunnerProvider(_key));
    final session = async.valueOrNull;

    return FrostedNavScaffold(
      title: session?.label ?? '…',
      builder: (context, topInset) => async.when(
        loading: () => _RunnerSkeleton(topInset: topInset),
        error: (_, _) => Center(
            child: Text(l.somethingWentWrong, style: AppTextStyles.bodySmall)),
        data: (session) => (session == null || user == null)
            ? Center(
                child: Text(l.somethingWentWrong,
                    style: AppTextStyles.bodySmall))
            : _buildBody(session, user, topInset),
      ),
    );
  }

  Widget _buildBody(
      TrainingAssignmentSession session, AppUser user, double topInset) {
    final l = AppLocalizations.of(context);
    final exercises = session.exercises;
    _ensureSlots(exercises);
    final pages = _flatten(exercises);

    final onCompletion = _page >= pages.length;
    final currentEx = onCompletion
        ? exercises.length
        : (pages.isEmpty ? 0 : pages[_page].ex);
    final currentSet = onCompletion || pages.isEmpty ? 0 : pages[_page].set;
    final currentSlots =
        (onCompletion || exercises.isEmpty) ? const <_SetSlot>[] : _slots[exercises[currentEx].id]!;

    final labels = [for (final e in exercises) e.exerciseName, l.finish];

    return Column(
      children: [
        SizedBox(height: topInset),
        _ExerciseSelector(
          labels: labels,
          selectedIndex: currentEx,
          finishIndex: exercises.length,
          onSelected: (i) {
            if (i >= exercises.length) {
              _goToPage(pages.length); // Finish
            } else {
              _goToPage(_firstPageOfExercise(exercises, i));
            }
          },
        ),
        // Dots = the sets of the current exercise, under the name / above the card.
        SizedBox(
          height: 20,
          child: onCompletion
              ? const SizedBox.shrink()
              : _SetDots(
                  slots: currentSlots,
                  current: currentSet,
                  onSelect: (s) => _goToPage(
                      _firstPageOfExercise(exercises, currentEx) + s),
                ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs,
                MediaQuery.paddingOf(context).bottom + AppSpacing.sm),
            // The whole card captures horizontal drags and drives the bottom
            // pager — so swiping anywhere (incl. the thumbnail/top) moves sets.
            child: GestureDetector(
              onHorizontalDragUpdate: _onCardDragUpdate,
              onHorizontalDragEnd: (d) => _onCardDragEnd(d, pages.length),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: _cardBorder, width: 1.5),
                  boxShadow: AppShadows.card,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg - 1),
                  child: Column(
                    children: [
                      // STATIC TOP — stays put while swiping sets of one exercise;
                      // cross-fades only when the exercise (or completion) changes.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: onCompletion
                            ? const SizedBox.shrink(key: ValueKey('done'))
                            : _ExerciseTop(
                                key: ValueKey(exercises[currentEx].id),
                                exercise: exercises[currentEx],
                                onSwap: () => _swap(exercises[currentEx]),
                              ),
                      ),
                      // BOTTOM PAGER — driven by the card's drag handler above
                      // (its own scrolling is disabled to avoid a gesture fight).
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (i) {
                            HapticFeedback.selectionClick();
                            setState(() => _page = i);
                          },
                          itemCount: pages.length + 1,
                        itemBuilder: (context, i) {
                          if (i >= pages.length) {
                            return _CompletionBottom(
                              completing: _completing,
                              onComplete: () => _complete(session),
                            );
                          }
                          final pr = pages[i];
                          final ex = exercises[pr.ex];
                          final slots = _slots[ex.id]!;
                          return _SetBottom(
                            key: ValueKey('${ex.id}#${pr.set}'),
                            exercise: ex,
                            setIndex: pr.set,
                            setCount: slots.length,
                            slot: slots[pr.set],
                            tenantId: user.tenantId,
                            personId: user.personId,
                            onSlotChanged: () => setState(() {}), // refresh dots
                            onLogged: () {
                              if (_page < pages.length) _goToPage(_page + 1);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
    );
  }
}

/// A slightly stronger border than the default hairline — the runner cards are
/// the focus of the screen, so they read with a clearer edge (esp. light mode).
Color get _cardBorder => AppColors.textTertiary.withValues(alpha: 0.35);

/// Loading placeholder that mirrors the runner layout (selector · dots · card),
/// so the swap to real data doesn't shift anything.
class _RunnerSkeleton extends StatelessWidget {
  const _RunnerSkeleton({required this.topInset});
  final double topInset;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        children: [
          SizedBox(height: topInset),
          const SizedBox(
              height: 40,
              child: Center(child: SkeletonBox(width: 80, height: 16))),
          SizedBox(
            height: 20,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 5; i++)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: SkeletonBox(width: 8, height: 8, borderRadius: 99),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs,
                  MediaQuery.paddingOf(context).bottom + AppSpacing.sm),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: _cardBorder, width: 1.5),
                  boxShadow: AppShadows.card,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg - 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Container(color: AppColors.skeletonBase),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SkeletonBox(width: 60, height: 10),
                            SizedBox(height: AppSpacing.sm),
                            SkeletonBox(width: 150, height: 13),
                            SizedBox(height: AppSpacing.md),
                            SkeletonBox(
                                width: double.infinity,
                                height: 44,
                                borderRadius: AppRadius.md),
                            SizedBox(height: AppSpacing.md),
                            SkeletonBox(width: 50, height: 10),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                    child: SkeletonBox(
                                        height: 48, borderRadius: AppRadius.md)),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                    child: SkeletonBox(
                                        height: 48, borderRadius: AppRadius.md)),
                                SizedBox(width: AppSpacing.sm),
                                SkeletonBox(
                                    width: 88,
                                    height: 48,
                                    borderRadius: AppRadius.md),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Top selector — one cell per exercise (+ Finish), synced with the PageView.
// ─────────────────────────────────────────────────────────────────────────

class _ExerciseSelector extends StatefulWidget {
  const _ExerciseSelector({
    required this.labels,
    required this.selectedIndex,
    required this.finishIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final int finishIndex; // last index = the "Finish" cell
  final ValueChanged<int> onSelected;

  @override
  State<_ExerciseSelector> createState() => _ExerciseSelectorState();
}

class _ExerciseSelectorState extends State<_ExerciseSelector> {
  static const double _itemWidth = 92.0;
  final _scroll = ScrollController();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ready = true;
      _center(animate: false);
    });
  }

  @override
  void didUpdateWidget(_ExerciseSelector old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex && _ready) {
      _center(animate: true);
    }
  }

  void _center({bool animate = true}) {
    if (!_scroll.hasClients) return;
    final target = (widget.selectedIndex * _itemWidth)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    if (animate) {
      _scroll.animateTo(target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic);
    } else {
      _scroll.jumpTo(target);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sidePadding = (screenWidth - _itemWidth) / 2;

    return SizedBox(
      height: 40,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: sidePadding),
        itemExtent: _itemWidth,
        itemCount: widget.labels.length,
        itemBuilder: (context, index) {
          final active = index == widget.selectedIndex;
          final isFinish = index == widget.finishIndex;
          return GestureDetector(
            onTap: () => widget.onSelected(index),
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFinish) ...[
                    Icon(Icons.flag_rounded,
                        size: 15,
                        color: active
                            ? AppColors.primary
                            : AppColors.textTertiary),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: active
                          ? AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)
                          : AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textTertiary),
                      child: Text(
                        widget.labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Per-set indicator (page-indicator style), one dot per set.
// ─────────────────────────────────────────────────────────────────────────

/// One small dot per set: the current set is an elongated forest pill, logged
/// sets are filled forest dots, pending sets are muted. Tapping selects a set.
class _SetDots extends StatelessWidget {
  const _SetDots({
    required this.slots,
    required this.current,
    required this.onSelect,
  });

  final List<_SetSlot> slots;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < slots.length; i++)
          _Dot(
            logged: slots[i].isLogged,
            active: i == current,
            onTap: () => onSelect(i),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.logged,
    required this.active,
    required this.onTap,
  });

  final bool logged;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = (active || logged)
        ? AppColors.primary
        : AppColors.textTertiary.withValues(alpha: 0.35);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// One (exercise, set) card.
// ─────────────────────────────────────────────────────────────────────────

/// One set slot for an exercise — a dot. Empty until logged; once logged it
/// holds the `logged_entries` id so it can be edited.
class _SetSlot {
  String? entryId; // logged_entries id once saved; null = not yet logged
  int? reps;
  num? weight;
  int? timeSeconds;

  bool get isLogged => entryId != null;

  static String trim(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// The **static top** of the card for one exercise — thumbnail/video hero, name +
/// swap, target/notes, and LAST TIME. Stays put while swiping between the
/// exercise's sets; only [_SetBottom] below it slides.
class _ExerciseTop extends ConsumerWidget {
  const _ExerciseTop({
    super.key,
    required this.exercise,
    required this.onSwap,
  });

  final TrainingExercise exercise;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ex = exercise;
    final lastAsync = ref.watch(lastEntriesProvider(ex.exerciseId));
    final hasVideo =
        (ex.videoStoragePath != null && ex.videoStoragePath!.isNotEmpty) ||
            (ex.videoUrl != null && ex.videoUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail with the swap action overlaid top-right (frees the header
        // row so the card has more room and doesn't need to scroll).
        Stack(
          children: [
            _ThumbnailHero(
              path: ex.thumbnailStoragePath,
              hasVideo: hasVideo,
              onPlay: () => playExerciseVideo(context,
                  storagePath: ex.videoStoragePath, url: ex.videoUrl),
            ),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: GestureDetector(
                onTap: onSwap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_horiz,
                      size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ex.targetSummary.isNotEmpty)
                _KeyValueLine(label: l.targetLabel, value: ex.targetSummary),
              if (ex.setTypeNote != null && ex.setTypeNote!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(ex.setTypeNote!,
                      style: AppTextStyles.bodySmall
                          .copyWith(fontStyle: FontStyle.italic)),
                ),
              if (ex.coachNote != null && ex.coachNote!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${l.coachNoteLabel}: ${ex.coachNote!}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ),
              const SizedBox(height: AppSpacing.md),
              _LastTimeBlock(async: lastAsync),
            ],
          ),
        ),
      ],
    );
  }
}

/// The **sliding bottom** of the card: the current set's inputs. One per
/// (exercise, set); swiping between these is what advances sets / exercises.
class _SetBottom extends ConsumerStatefulWidget {
  const _SetBottom({
    super.key,
    required this.exercise,
    required this.setIndex,
    required this.setCount,
    required this.slot,
    required this.tenantId,
    required this.personId,
    required this.onSlotChanged,
    required this.onLogged,
  });

  final TrainingExercise exercise;
  final int setIndex;
  final int setCount;
  final _SetSlot slot;
  final String tenantId;
  final String personId;
  final VoidCallback onSlotChanged; // refresh parent dots
  final VoidCallback onLogged; // advance to next page after a fresh log

  @override
  ConsumerState<_SetBottom> createState() => _SetBottomState();
}

class _SetBottomState extends ConsumerState<_SetBottom>
    with AutomaticKeepAliveClientMixin {
  final _reps = TextEditingController();
  final _weight = TextEditingController();
  final _time = TextEditingController();
  bool _prefilled = false;
  bool _saving = false;

  @override
  bool get wantKeepAlive => true;

  bool get _isTimed => widget.exercise.timeSeconds != null;

  @override
  void initState() {
    super.initState();
    // A logged set shows its stored values immediately.
    final s = widget.slot;
    if (s.isLogged) {
      _reps.text = s.reps?.toString() ?? '';
      _weight.text = s.weight != null ? _SetSlot.trim(s.weight!) : '';
      _time.text = s.timeSeconds?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _reps.dispose();
    _weight.dispose();
    _time.dispose();
    super.dispose();
  }

  /// Prefill an unlogged set from last-time's matching set (minimal taps).
  void _prefillFrom(List<LoggedEntry> last) {
    if (_prefilled) return;
    _prefilled = true;
    if (widget.slot.isLogged || last.isEmpty) return;
    final src =
        widget.setIndex < last.length ? last[widget.setIndex] : last.last;
    if (src.reps != null) _reps.text = '${src.reps}';
    if (src.weight != null) _weight.text = _SetSlot.trim(src.weight!);
    if (src.timeSeconds != null) _time.text = '${src.timeSeconds}';
  }

  Future<void> _logCurrent() async {
    final l = AppLocalizations.of(context);
    final reps = int.tryParse(_reps.text.trim());
    final weight = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    final time = int.tryParse(_time.text.trim());
    if (reps == null && weight == null && time == null) return;

    final slot = widget.slot;
    final wasLogged = slot.isLogged;
    setState(() => _saving = true);
    try {
      if (wasLogged) {
        await TrainingRepository.updateSet(
          tenantId: widget.tenantId,
          entryId: slot.entryId!,
          reps: reps,
          weight: weight,
          timeSeconds: time,
        );
      } else {
        slot.entryId = await TrainingRepository.logSet(
          tenantId: widget.tenantId,
          personId: widget.personId,
          exerciseId: widget.exercise.exerciseId,
          assignmentExerciseId: widget.exercise.id,
          setIndex: widget.setIndex + 1,
          reps: reps,
          weight: weight,
          timeSeconds: time,
        );
      }
      slot
        ..reps = reps
        ..weight = weight
        ..timeSeconds = time;
      HapticFeedback.lightImpact();
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSlotChanged();
      AppToast.show(context, title: l.setLoggedToast, blur: false);
      if (!wasLogged) widget.onLogged(); // advance only on a fresh log
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppToast.show(context, title: e.message, blur: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    final ex = widget.exercise;
    final lastAsync = ref.watch(lastEntriesProvider(ex.exerciseId));
    lastAsync.whenData(_prefillFrom);

    // Only the set inputs live here — the exercise frame (thumbnail, target,
    // last time) is the static [_ExerciseTop] above the pager. Not scrollable;
    // anchored to the bottom of the available space (near the thumb).
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${l.setN(widget.setIndex + 1)} / ${widget.setCount}',
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _NumField(controller: _reps, label: l.repsLabel),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _NumField(
                    controller: _weight, label: l.weightLabel, decimal: true),
              ),
              if (_isTimed) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NumField(controller: _time, label: l.timeSecLabel),
                ),
              ],
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  onPressed: _saving ? null : _logCurrent,
                  child: _saving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.onPrimary),
                        )
                      : Text(widget.slot.isLogged ? l.save : l.logSet),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The cover image at the top of an exercise card, with a play badge over it
/// when the exercise has a video (tap → opens the video player sheet).
class _ThumbnailHero extends StatelessWidget {
  const _ThumbnailHero({
    required this.path,
    required this.hasVideo,
    required this.onPlay,
  });

  final String? path;
  final bool hasVideo;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (path != null && path!.trim().isNotEmpty) {
      image = Image.network(
        ExerciseRepository.thumbnailPublicUrl(path!),
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const _HeroPlaceholder(),
        errorBuilder: (_, _, _) => const _HeroPlaceholder(),
      );
    } else {
      image = const _HeroPlaceholder();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg - 1)),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: GestureDetector(
          onTap: hasVideo ? onPlay : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              if (hasVideo)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        size: 36, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: Icon(Icons.fitness_center, size: 36, color: AppColors.textTertiary),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Completion — the last page of the bottom pager (its top is empty, so this
// content centers in the whole card).
// ─────────────────────────────────────────────────────────────────────────

class _CompletionBottom extends StatelessWidget {
  const _CompletionBottom({
    required this.completing,
    required this.onComplete,
  });

  final bool completing;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 56, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(l.finishSessionTitle,
                style: AppTextStyles.heading3, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(l.finishSessionBody,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l.markComplete,
              isExpanded: true,
              isLoading: completing,
              onPressed: completing ? null : onComplete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared bits.
// ─────────────────────────────────────────────────────────────────────────

class _KeyValueLine extends StatelessWidget {
  const _KeyValueLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.bodySmall,
          children: [
            TextSpan(
              text: '$label · ',
              style: AppTextStyles.label.copyWith(color: AppColors.textTertiary),
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastTimeBlock extends StatelessWidget {
  const _LastTimeBlock({required this.async});
  final AsyncValue<List<LoggedEntry>> async;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.lastTime.toUpperCase(),
              style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4)),
          const SizedBox(height: 4),
          async.when(
            loading: () => Text('…', style: AppTextStyles.bodySmall),
            error: (_, _) =>
                Text(l.noHistoryYet, style: AppTextStyles.bodySmall),
            data: (entries) {
              if (entries.isEmpty) {
                return Text(l.noHistoryYet,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary));
              }
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: 2,
                children: [
                  for (var i = 0; i < entries.length; i++)
                    Text('${i + 1}. ${entries[i].summary}',
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w600)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.controller,
    required this.label,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String label;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.label.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 4),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            keyboardType:
                TextInputType.numberWithOptions(decimal: decimal, signed: false),
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
