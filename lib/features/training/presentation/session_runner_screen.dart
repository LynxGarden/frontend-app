import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/exercises/data/exercise_repository.dart';
import 'package:lynx_app/features/exercises/data/models/metric_field.dart';
import 'package:lynx_app/features/exercises/presentation/widgets/metric_form_renderer.dart';
import 'package:lynx_app/features/programs/data/models/training_method.dart';
import 'package:lynx_app/features/programs/presentation/exercise_picker_sheet.dart';
import 'package:lynx_app/features/programs/presentation/method_labels.dart';
import 'package:lynx_app/features/training/data/models/active_assignment.dart';
import 'package:lynx_app/features/training/data/training_repository.dart';
import 'package:lynx_app/features/training/presentation/exercise_detail_sheet.dart';
import 'package:lynx_app/features/training/providers/training_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/models/app_user.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/frosted_nav_scaffold.dart';
import 'package:lynx_app/shared/widgets/keyboard_dismisser.dart';
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

  /// Save hooks registered by the live set pages (keyed `exerciseId#setIndex`):
  /// swiping away from a page flushes its unsaved inputs.
  final Map<String, Future<void> Function()> _savers = {};

  /// The screen-level rest countdown, surfaced top-right in the nav bar and
  /// started from a set card's "Start timer" button.
  Timer? _restTimer;
  int _restRemaining = 0;

  RunnerKey get _key =>
      (assignmentId: widget.assignmentId, sessionId: widget.sessionId);

  @override
  void dispose() {
    _restTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    HapticFeedback.lightImpact();
    setState(() => _restRemaining = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_restRemaining <= 1) {
        t.cancel();
        HapticFeedback.heavyImpact();
        setState(() => _restRemaining = 0);
      } else {
        setState(() => _restRemaining--);
      }
    });
  }

  void _cancelRest() {
    _restTimer?.cancel();
    setState(() => _restRemaining = 0);
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

  void _openDetail(TrainingExercise ex) {
    showExerciseDetailSheet(
      context,
      exerciseId: ex.exerciseId,
      exerciseName: ex.exerciseName,
      description: ex.description,
      videoUrl: ex.videoUrl,
      videoStoragePath: ex.videoStoragePath,
      thumbnailStoragePath: ex.thumbnailStoragePath,
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

  Future<void> _complete(TrainingAssignmentSession session, int rating) async {
    final l = AppLocalizations.of(context);
    setState(() => _completing = true);
    try {
      // Flush any set inputs that were typed but never explicitly logged.
      for (final save in List.of(_savers.values)) {
        await save();
      }
      await TrainingRepository.completeSession(session.id, rating: rating);
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

    return KeyboardDismisser(
      child: FrostedNavScaffold(
        title: session?.label ?? '…',
        trailing: _restRemaining > 0
            ? _RestTimerPill(remaining: _restRemaining, onTap: _cancelRest)
            : null,
        builder: (context, topInset) => async.when(
          loading: () => _RunnerSkeleton(topInset: topInset),
          error: (_, _) => Center(
              child:
                  Text(l.somethingWentWrong, style: AppTextStyles.bodySmall)),
          data: (session) => (session == null || user == null)
              ? Center(
                  child: Text(l.somethingWentWrong,
                      style: AppTextStyles.bodySmall))
              : _buildBody(session, user, topInset),
        ),
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

    // One rail segment per structured method, each positioned over its own
    // selector cells and scrolling with them — so EVERY group's indicator is
    // visible at once, not just the current one. Grouped methods bracket their
    // members with a line; single-exercise methods (drop set…) show just a
    // centred name.
    bool isMethod(TrainingMethod m) =>
        m != TrainingMethod.straight && m != TrainingMethod.none;
    final segments = <_RailSegmentData>[];
    var si = 0;
    while (si < exercises.length) {
      final e = exercises[si];
      final gid = e.methodGroupId;
      if (gid != null && gid.isNotEmpty) {
        var last = si;
        while (last + 1 < exercises.length &&
            exercises[last + 1].methodGroupId == gid) {
          last++;
        }
        final count = last - si + 1;
        var m = e.method;
        if (!isMethod(m)) {
          for (var k = si; k <= last; k++) {
            if (isMethod(exercises[k].method)) {
              m = exercises[k].method;
              break;
            }
          }
        }
        if (isMethod(m) || count > 1) {
          segments.add(_RailSegmentData(
            startIndex: si,
            count: count,
            label: methodLabel(l, m),
            bracket: count > 1,
          ));
        }
        si = last + 1;
      } else {
        if (isMethod(e.method)) {
          segments.add(_RailSegmentData(
            startIndex: si,
            count: 1,
            label: methodLabel(l, e.method),
            bracket: false,
          ));
        }
        si++;
      }
    }

    return Column(
      children: [
        SizedBox(height: topInset),
        _ExerciseSelector(
          labels: labels,
          segments: segments,
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
              onHorizontalDragStart: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
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
                                siblings: exercises,
                                onSwap: () => _swap(exercises[currentEx]),
                                onOpenDetail: () =>
                                    _openDetail(exercises[currentEx]),
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
                            FocusManager.instance.primaryFocus?.unfocus();
                            // Swiping away from a set saves what was typed.
                            final prev = _page;
                            if (prev != i && prev < pages.length) {
                              final prevEx = exercises[pages[prev].ex];
                              _savers['${prevEx.id}#${pages[prev].set}']
                                  ?.call();
                            }
                            setState(() => _page = i);
                          },
                          itemCount: pages.length + 1,
                        itemBuilder: (context, i) {
                          if (i >= pages.length) {
                            return _CompletionBottom(
                              completing: _completing,
                              onComplete: (rating) =>
                                  _complete(session, rating),
                            );
                          }
                          final pr = pages[i];
                          final ex = exercises[pr.ex];
                          final slots = _slots[ex.id]!;
                          final saverKey = '${ex.id}#${pr.set}';
                          return _SetBottom(
                            key: ValueKey('${ex.id}#${pr.set}'),
                            exercise: ex,
                            setIndex: pr.set,
                            setCount: slots.length,
                            slot: slots[pr.set],
                            tenantId: user.tenantId,
                            personId: user.personId,
                            onSlotChanged: () => setState(() {}), // refresh dots
                            onStartRest: _startRest,
                            registerSaver: (fn) {
                              if (fn == null) {
                                _savers.remove(saverKey);
                              } else {
                                _savers[saverKey] = fn;
                              }
                            },
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
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            SkeletonBox(
                                width: 60, height: 60, borderRadius: AppRadius.md),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SkeletonBox(width: 150, height: 14),
                                  SizedBox(height: 8),
                                  SkeletonBox(width: 90, height: 11),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.md),
                        SkeletonBox(
                            width: double.infinity,
                            height: 52,
                            borderRadius: AppRadius.md),
                        SizedBox(height: AppSpacing.md),
                        SkeletonBox(width: 50, height: 10),
                        SizedBox(height: 8),
                        SkeletonBox(
                            width: double.infinity,
                            height: 48,
                            borderRadius: AppRadius.md),
                        SizedBox(height: AppSpacing.md),
                        SkeletonBox(
                            width: double.infinity,
                            height: 48,
                            borderRadius: AppRadius.md),
                      ],
                    ),
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

/// Fixed cell width of the top exercise selector — shared so the method rail
/// can align its brackets to the cells.
const double _kSelectorItemWidth = 92.0;
const double _kRailHeight = 18.0;

/// One method indicator in the rail above the selector: either a bracketed
/// group ("——— Superset ———" spanning [count] cells) or a single-exercise
/// method shown as a plain centred name ([bracket] = false).
class _RailSegmentData {
  const _RailSegmentData({
    required this.startIndex,
    required this.count,
    required this.label,
    required this.bracket,
  });

  final int startIndex;
  final int count;
  final String label;
  final bool bracket;
}

class _ExerciseSelector extends StatefulWidget {
  const _ExerciseSelector({
    required this.labels,
    required this.segments,
    required this.selectedIndex,
    required this.finishIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final List<_RailSegmentData> segments;
  final int selectedIndex;
  final int finishIndex; // last index = the "Finish" cell
  final ValueChanged<int> onSelected;

  @override
  State<_ExerciseSelector> createState() => _ExerciseSelectorState();
}

class _ExerciseSelectorState extends State<_ExerciseSelector> {
  static const double _itemWidth = _kSelectorItemWidth;
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
    final count = widget.labels.length;
    final contentWidth = _itemWidth * count;
    final hasRail = widget.segments.isNotEmpty;

    final namesRow = SizedBox(
      height: 40,
      child: Row(
        children: [
          for (var index = 0; index < count; index++)
            SizedBox(
              width: _itemWidth,
              child: _cell(index),
            ),
        ],
      ),
    );

    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: sidePadding),
      child: SizedBox(
        width: contentWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rail — all method indicators at once, each over its own cells and
            // scrolling with them.
            if (hasRail)
              SizedBox(
                height: _kRailHeight,
                child: Stack(
                  children: [
                    for (final seg in widget.segments)
                      Positioned(
                        left: seg.startIndex * _itemWidth,
                        width: seg.count * _itemWidth,
                        top: 0,
                        bottom: 0,
                        child: _RailSegment(data: seg),
                      ),
                  ],
                ),
              ),
            namesRow,
          ],
        ),
      ),
    );
  }

  Widget _cell(int index) {
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
                  color: active ? AppColors.primary : AppColors.textTertiary),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: active
                    ? AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.primary)
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
  }
}

/// One method indicator in the rail. A grouped method ([data.bracket]) draws a
/// thin line spanning its cells with the name in the middle; a single-exercise
/// method shows just its centred name (no lines, which would over-stretch).
class _RailSegment extends StatelessWidget {
  const _RailSegment({required this.data});

  final _RailSegmentData data;

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      data.label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.label.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5),
    );

    if (!data.bracket) {
      // Single-exercise method — centred name, allowed to overflow its one cell
      // a little rather than stretch lines across the width.
      return Center(
        child: OverflowBox(
          minWidth: 0,
          maxWidth: _kSelectorItemWidth * 2.2,
          alignment: Alignment.center,
          child: labelWidget,
        ),
      );
    }

    final lineColor = AppColors.primary.withValues(alpha: 0.35);
    Widget line() => Container(height: 1.5, color: lineColor);
    // Vertical end cap so the bracket reads as a closed span: |——— LABEL ———|
    Widget cap() => Container(width: 1.5, height: 9, color: lineColor);
    return Row(
      children: [
        cap(),
        Expanded(child: line()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: labelWidget,
        ),
        Expanded(child: line()),
        cap(),
      ],
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

  /// Config-driven actuals for this set, keyed by metric-field key.
  Map<String, dynamic> values = {};

  bool get isLogged => entryId != null;
}

/// The **static top** of the card for one exercise — compact thumbnail, title +
/// subtitle, method badge, swap + detail affordances, notes, and LAST TIME.
/// Stays put while swiping between the exercise's sets; only [_SetBottom] slides.
class _ExerciseTop extends ConsumerWidget {
  const _ExerciseTop({
    super.key,
    required this.exercise,
    required this.siblings,
    required this.onSwap,
    required this.onOpenDetail,
  });

  final TrainingExercise exercise;
  final List<TrainingExercise> siblings;
  final VoidCallback onSwap;
  final VoidCallback onOpenDetail;

  String? _methodBadge(AppLocalizations l) {
    if (exercise.method == TrainingMethod.straight ||
        exercise.method == TrainingMethod.none) {
      return null;
    }
    final label = methodLabel(l, exercise.method);
    if (exercise.isGrouped) {
      final group = siblings
          .where((e) => e.methodGroupId == exercise.methodGroupId)
          .toList()
        ..sort((a, b) => a.groupOrder.compareTo(b.groupOrder));
      final pos = group.indexWhere((e) => e.id == exercise.id) + 1;
      if (group.length > 1) return '$label · $pos/${group.length}';
    }
    return label;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ex = exercise;
    final lastAsync = ref.watch(lastEntriesProvider(ex.exerciseId));
    final badge = _methodBadge(l);
    final interval = methodIsInterval(ex.method)
        ? (ex.methodConfig['interval_seconds'] as num?)?.toInt()
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Method indicator — a full-width banner at the top of the card so
          // the client always knows which method they're training.
          if (badge != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(path: ex.thumbnailStoragePath, onTap: onOpenDetail),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onOpenDetail,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(ex.exerciseName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.info_outline,
                              size: 16, color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                    if (ex.targetSummary.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(ex.targetSummary,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onSwap,
                icon: Icon(Icons.swap_horiz, color: AppColors.textSecondary),
                tooltip: null,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (interval != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: WorkoutTimer(targetSeconds: interval),
            ),
          if (ex.setTypeNote != null && ex.setTypeNote!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
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
    );
  }
}

/// A compact rounded thumbnail (tap → exercise detail sheet).
class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, required this.onTap});
  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget inner;
    if (path != null && path!.trim().isNotEmpty) {
      inner = Image.network(
        ExerciseRepository.thumbnailPublicUrl(path!),
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const _ThumbPlaceholder(),
        errorBuilder: (_, _, _) => const _ThumbPlaceholder(),
      );
    } else {
      inner = const _ThumbPlaceholder();
    }
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(width: 60, height: 60, child: inner),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: Icon(Icons.fitness_center, size: 24, color: AppColors.textTertiary),
    );
  }
}

/// The top-right rest countdown pill (in the nav bar). Tap to cancel.
class _RestTimerPill extends StatelessWidget {
  const _RestTimerPill({required this.remaining, required this.onTap});
  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = remaining ~/ 60;
    final s = remaining % 60;
    final label = m > 0 ? '$m:${s.toString().padLeft(2, '0')}' : '${s}s';
    final urgent = remaining <= 5;
    final color = urgent ? AppColors.error : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 15, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
      ),
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
    required this.onStartRest,
    required this.registerSaver,
    required this.onLogged,
  });

  final TrainingExercise exercise;
  final int setIndex;
  final int setCount;
  final _SetSlot slot;
  final String tenantId;
  final String personId;
  final VoidCallback onSlotChanged; // refresh parent dots
  final ValueChanged<int> onStartRest; // start the screen-level rest timer
  /// Registers (fn) / unregisters (null) this page's save-if-dirty hook with
  /// the runner, so swiping away persists what was typed.
  final void Function(Future<void> Function()? fn) registerSaver;
  final VoidCallback onLogged; // advance to next page after a fresh log

  @override
  ConsumerState<_SetBottom> createState() => _SetBottomState();
}

class _SetBottomState extends ConsumerState<_SetBottom>
    with AutomaticKeepAliveClientMixin {
  late Map<String, dynamic> _values;
  bool _prefilled = false;
  bool _saving = false;

  @override
  bool get wantKeepAlive => true;

  /// The schema driving the inputs. Config-driven when present; a reps/weight
  /// (+time for timed exercises) fallback keeps legacy exercises loggable.
  List<MetricField> get _schema {
    final ex = widget.exercise;
    if (ex.metricSchema.isNotEmpty) return ex.metricSchema;
    if (ex.timeSeconds != null) return _timedFallbackSchema;
    return const []; // renderer falls back to reps + weight
  }

  @override
  void initState() {
    super.initState();
    // A logged set shows its stored values immediately.
    _values = Map<String, dynamic>.from(widget.slot.values);
    widget.registerSaver(_saveIfDirty);
  }

  @override
  void dispose() {
    widget.registerSaver(null);
    super.dispose();
  }

  /// Prefill an unlogged set from last-time's matching set (minimal taps).
  void _prefillFrom(List<LoggedEntry> last) {
    if (_prefilled) return;
    _prefilled = true;
    if (widget.slot.isLogged || last.isEmpty || _values.isNotEmpty) return;
    final src =
        widget.setIndex < last.length ? last[widget.setIndex] : last.last;
    setState(() => _values = Map<String, dynamic>.from(_lastValuesOf(src)));
  }

  /// A value-map view of a prior entry, keyed to match the current schema.
  Map<String, dynamic> _lastValuesOf(LoggedEntry e) {
    if (e.data.isNotEmpty) return e.data;
    return {
      'reps': e.reps,
      'weight': e.weight,
      'time': e.timeSeconds,
    }..removeWhere((_, v) => v == null);
  }

  int? _asInt(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
  num? _asNum(dynamic v) =>
      v is num ? v : num.tryParse('${v ?? ''}'.replaceAll(',', '.'));

  Map<String, dynamic> get _cleanValues => Map<String, dynamic>.from(_values)
    ..removeWhere((_, v) => v == null || (v is String && v.trim().isEmpty));

  /// Whether [a] and [b] hold the same values (string-compared, so 60 == "60").
  static bool _sameData(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (!b.containsKey(e.key) || '${b[e.key]}' != '${e.value}') return false;
    }
    return true;
  }

  /// Called by the runner when the user swipes away from this set (or finishes
  /// the session): persists typed-but-unlogged input, silently.
  Future<void> _saveIfDirty() async {
    if (_saving) return;
    final data = _cleanValues;
    if (data.isEmpty) return;
    if (widget.slot.isLogged && _sameData(data, widget.slot.values)) return;
    await _logCurrent(silent: true);
  }

  Future<void> _logCurrent({bool silent = false}) async {
    final l = AppLocalizations.of(context);
    if (!silent) FocusManager.instance.primaryFocus?.unfocus();
    final data = _cleanValues;
    if (data.isEmpty) return;

    // Derive legacy columns so "last time", review and progress keep working.
    final reps = _asInt(data['reps']);
    final weight = _asNum(data['weight']);
    int? time;
    final durationKey = _schema
        .where((f) => f.type == MetricFieldType.duration)
        .map((f) => f.key)
        .cast<String?>()
        .firstWhere((_) => true, orElse: () => null);
    if (durationKey != null) {
      time = _asInt(data[durationKey]);
    } else {
      time = _asInt(data['time'] ?? data['time_seconds']);
    }

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
          data: data,
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
          data: data,
        );
      }
      slot
        ..reps = reps
        ..weight = weight
        ..timeSeconds = time
        ..values = data;
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSlotChanged();
      if (!silent) {
        HapticFeedback.lightImpact();
        AppToast.show(context, title: l.setLoggedToast, blur: false);
        if (!wasLogged) widget.onLogged(); // advance only on a fresh log
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        if (!silent) AppToast.show(context, title: e.message, blur: false);
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
    final lastValues = lastAsync.valueOrNull != null &&
            lastAsync.value!.isNotEmpty
        ? _lastValuesOf(widget.setIndex < lastAsync.value!.length
            ? lastAsync.value![widget.setIndex]
            : lastAsync.value!.last)
        : null;

    // Form scrolls; the Log Set button is pinned to the bottom of the card.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l.setN(widget.setIndex + 1)} / ${widget.setCount}',
                      style: AppTextStyles.label
                          .copyWith(color: AppColors.textTertiary)),
                  const SizedBox(height: AppSpacing.sm),
                  MetricFormRenderer(
                    key: ValueKey('${widget.exercise.id}#${widget.setIndex}'),
                    schema: _schema,
                    values: _values,
                    lastValues: lastValues,
                    onChanged: (key, value) => _values[key] = value,
                  ),
                  if (ex.restSeconds != null && ex.restSeconds! > 0) ...[
                    const SizedBox(height: AppSpacing.md),
                    _RestRow(
                      seconds: ex.restSeconds!,
                      onStart: () => widget.onStartRest(ex.restSeconds!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                // Keep the forest fill while saving (disabled) so the spinner
                // stays visible instead of washing out on a grey disabled bg.
                disabledBackgroundColor: AppColors.primary,
                disabledForegroundColor: AppColors.onPrimary,
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
    );
  }
}

/// Fallback logging schema for a legacy timed exercise (no custom schema).
const List<MetricField> _timedFallbackSchema = [
  MetricField(key: 'reps', label: 'Reps', type: MetricFieldType.number),
  MetricField(
      key: 'weight',
      label: 'Weight',
      type: MetricFieldType.decimal,
      unit: 'kg'),
  MetricField(key: 'time', label: 'Time', type: MetricFieldType.duration),
];

/// "Rest: 120 s · [Start timer]" — shown on a set card when the prescription
/// has a pause. Starting it surfaces the countdown top-right in the nav bar.
class _RestRow extends StatelessWidget {
  const _RestRow({required this.seconds, required this.onStart});
  final int seconds;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(l.restNSeconds(seconds),
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onStart();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            child: Text(l.startTimer,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Completion — the last page of the bottom pager (its top is empty, so this
// content centers in the whole card).
// ─────────────────────────────────────────────────────────────────────────

class _CompletionBottom extends StatefulWidget {
  const _CompletionBottom({
    required this.completing,
    required this.onComplete,
  });

  final bool completing;
  final ValueChanged<int> onComplete; // 1–10 session difficulty

  @override
  State<_CompletionBottom> createState() => _CompletionBottomState();
}

class _CompletionBottomState extends State<_CompletionBottom> {
  int _rating = 5;

  static String _emojiFor(int r) {
    if (r <= 2) return '😄';
    if (r <= 4) return '🙂';
    if (r <= 6) return '😐';
    if (r <= 8) return '😣';
    return '🥵';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = (_rating - 1) / 9.0;
    final accent =
        Color.lerp(AppColors.success, AppColors.error, t) ?? AppColors.primary;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.finishSessionTitle,
                style: AppTextStyles.heading3, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(l.finishSessionBody,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            // 1–10 difficulty: smiley + slider.
            Text(l.sessionDifficultyTitle,
                style: AppTextStyles.body
                    .copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(_emojiFor(_rating),
                  key: ValueKey(_emojiFor(_rating)),
                  style: const TextStyle(fontSize: 44)),
            ),
            Text('$_rating / 10',
                style: AppTextStyles.bodySmall.copyWith(
                    color: accent, fontWeight: FontWeight.w700)),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accent,
                thumbColor: accent,
                inactiveTrackColor: accent.withValues(alpha: 0.2),
                overlayColor: accent.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: _rating.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (v) {
                  final r = v.round();
                  if (r != _rating) {
                    HapticFeedback.selectionClick();
                    setState(() => _rating = r);
                  }
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.sessionDifficultyEasy,
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textTertiary)),
                Text(l.sessionDifficultyHard,
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l.markComplete,
              isExpanded: true,
              isLoading: widget.completing,
              onPressed: widget.completing
                  ? null
                  : () => widget.onComplete(_rating),
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

class _LastTimeBlock extends StatelessWidget {
  const _LastTimeBlock({required this.async});
  final AsyncValue<List<LoggedEntry>> async;

  /// A short "when" for the header, e.g. "Today", "Yesterday", "3d ago".
  static String? _relative(DateTime when) {
    final now = DateTime.now();
    final days =
        DateTime(now.year, now.month, now.day).difference(
            DateTime(when.year, when.month, when.day)).inDays;
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '${days}d ago';
    if (days < 30) return '${(days / 7).floor()}w ago';
    return '${(days / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final entries = async.asData?.value ?? const <LoggedEntry>[];
    final when = entries.isEmpty ? null : entries.first.loggedAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(l.lastTime.toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4)),
              const Spacer(),
              if (when != null)
                Text(_relative(when) ?? '',
                    style: AppTextStyles.label.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 0.2)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          async.when(
            loading: () => const _LastTimeSkeleton(),
            error: (_, _) => _empty(l),
            data: (entries) {
              if (entries.isEmpty) return _empty(l);
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < entries.length; i++)
                    _SetPill(index: i + 1, value: entries[i].summary),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _empty(AppLocalizations l) => Text(l.noHistoryYet,
      style: AppTextStyles.bodySmall
          .copyWith(color: AppColors.textTertiary));
}

/// One logged set from last time, shown as a pill: a muted set-number badge
/// followed by the bold actuals (e.g. `8 × 60`).
class _SetPill extends StatelessWidget {
  const _SetPill({required this.index, required this.value});
  final int index;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text('$index',
                style: AppTextStyles.label.copyWith(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    height: 1)),
          ),
          const SizedBox(width: 6),
          Text(value,
              style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

/// Layout-matching placeholder: a few pill-shaped shimmer boxes.
class _LastTimeSkeleton extends StatelessWidget {
  const _LastTimeSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: const [
          SkeletonBox(width: 68, height: 26, borderRadius: AppRadius.pill),
          SkeletonBox(width: 68, height: 26, borderRadius: AppRadius.pill),
          SkeletonBox(width: 60, height: 26, borderRadius: AppRadius.pill),
        ],
      ),
    );
  }
}

