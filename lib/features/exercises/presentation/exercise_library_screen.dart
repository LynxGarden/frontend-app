import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/exercises/data/exercise_repository.dart';
import 'package:lynx_app/features/exercises/data/models/exercise.dart';
import 'package:lynx_app/features/exercises/data/models/exercise_tag.dart';
import 'package:lynx_app/features/exercises/data/models/movement.dart';
import 'package:lynx_app/features/exercises/presentation/exercise_editor_screen.dart';
import 'package:lynx_app/features/exercises/presentation/exercise_video.dart';
import 'package:lynx_app/features/exercises/presentation/movement_labels.dart';
import 'package:lynx_app/features/exercises/presentation/tag_labels.dart';
import 'package:lynx_app/features/exercises/providers/exercises_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/view_mode_provider.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/main_shell.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// Coach exercise library: searchable list/grid, tag + movement filters,
/// add/edit/delete. Shown as a tab-root (via Programs → "All exercises" it is
/// pushed — pass [pushed] true for the circular-back detail chrome).
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key, this.pushed = false});

  /// When true, render under an [AppNavBar] (pushed detail page) instead of the
  /// tab-root app bar.
  final bool pushed;

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchOpen = false;
  TagCategory? _activeCategory; // null = All categories
  String? _activeTagId; // null = all tags (within the active category)
  final Set<Movement> _activeMovements = {};

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    _search.clear();
    setState(() => _searchOpen = false);
  }

  Future<void> _openEditor([Exercise? exercise]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ExerciseEditorScreen(exercise: exercise)),
    );
    if (saved == true) {
      ref.invalidate(exercisesProvider);
      ref.invalidate(exerciseTagsProvider);
    }
  }

  Future<void> _watch(Exercise e) => playExerciseVideo(
        context,
        storagePath: e.videoStoragePath,
        url: e.videoUrl,
      );

  List<Exercise> _filter(List<Exercise> all) {
    final q = _search.text.trim().toLowerCase();
    return all.where((e) {
      final matchesQuery = q.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          (e.description?.toLowerCase().contains(q) ?? false);
      final matchesCategory = _activeCategory == null ||
          e.tags.any((t) => t.category == _activeCategory);
      final matchesTag =
          _activeTagId == null || e.tags.any((t) => t.id == _activeTagId);
      final matchesMovement = _activeMovements.isEmpty ||
          e.movements.any(_activeMovements.contains);
      return matchesQuery && matchesCategory && matchesTag && matchesMovement;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final exercisesAsync = ref.watch(exercisesProvider);
    final tagsAsync = ref.watch(exerciseTagsProvider);
    final mode = ref.watch(viewModeProvider('exercises'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.pushed
          ? null
          : AppBar(
              title: Text(l.libraryTitle, style: AppTextStyles.heading3),
              actions: [_viewToggleButton(mode)],
            ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: AppBottomBar.fabBottomInset(context)),
        child: FloatingActionButton.extended(
          heroTag: 'fab_library',
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.add),
          label: Text(l.newExercise),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (widget.pushed)
              AppNavBar(
                title: l.allExercises,
                trailing: _viewToggleAction(mode),
              ),
            const SizedBox(height: AppSpacing.sm),
            _FacetedTagFilter(
              tags:
                  tagsAsync.maybeWhen(data: (t) => t, orElse: () => const []),
              activeCategory: _activeCategory,
              activeTagId: _activeTagId,
              onSelectCategory: (c) => setState(() {
                _activeCategory = c;
                _activeTagId = null;
              }),
              onSelectTag: (id) => setState(() => _activeTagId = id),
              searchOpen: _searchOpen,
              searchController: _search,
              searchFocusNode: _searchFocus,
              searchHint: l.searchExercises,
              onOpenSearch: _openSearch,
              onCloseSearch: _closeSearch,
            ),
            if (!_searchOpen) ...[
              const SizedBox(height: AppSpacing.sm),
              _MovementFilterRow(
                active: _activeMovements,
                onToggle: (m) => setState(() {
                  if (!_activeMovements.remove(m)) _activeMovements.add(m);
                }),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: exercisesAsync.when(
                loading: () => mode == ViewMode.grid
                    ? const _ExerciseGridSkeleton()
                    : const _ExerciseListSkeleton(),
                error: (_, _) => Center(
                  child: Text(l.somethingWentWrong,
                      style: AppTextStyles.bodySmall),
                ),
                data: (all) {
                  final items = _filter(all);
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          l.exercisesEmpty,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    );
                  }
                  return mode == ViewMode.grid
                      ? _grid(items)
                      : _list(items);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<Exercise> items) {
    final bottom = MediaQuery.paddingOf(context).bottom + AppSpacing.md + 60;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cross = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
                ? 3
                : 2;
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, bottom),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.72,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _ExerciseGridCard(
            exercise: items[i],
            onTap: () => _openEditor(items[i]),
            onWatch: () => _watch(items[i]),
          ),
        );
      },
    );
  }

  Widget _list(List<Exercise> items) {
    final bottom = MediaQuery.paddingOf(context).bottom + AppSpacing.md + 60;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, bottom),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) => _ExerciseListCard(
        exercise: items[i],
        onTap: () => _openEditor(items[i]),
        onWatch: () => _watch(items[i]),
      ),
    );
  }

  void _toggleView(ViewMode mode) {
    HapticFeedback.selectionClick();
    ref.read(viewModeProvider('exercises').notifier).toggle();
  }

  Widget _viewToggleButton(ViewMode mode) {
    final l = AppLocalizations.of(context);
    final toGrid = mode == ViewMode.list;
    return IconButton(
      tooltip: toGrid ? l.viewAsGrid : l.viewAsList,
      icon: Icon(toGrid ? Icons.grid_view_rounded : Icons.view_agenda_outlined,
          color: AppColors.primary),
      onPressed: () => _toggleView(mode),
    );
  }

  Widget _viewToggleAction(ViewMode mode) {
    final l = AppLocalizations.of(context);
    final toGrid = mode == ViewMode.list;
    return AppNavBarAction(
      icon: toGrid ? Icons.grid_view_rounded : Icons.view_agenda_outlined,
      onTap: () => _toggleView(mode),
      tooltip: toGrid ? l.viewAsGrid : l.viewAsList,
    );
  }
}

/// A horizontally-scrolling multi-select row of movement filters.
class _MovementFilterRow extends StatelessWidget {
  const _MovementFilterRow({required this.active, required this.onToggle});

  final Set<Movement> active;
  final ValueChanged<Movement> onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          for (final m in Movement.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _pill(
                movementLabel(l, m),
                selected: active.contains(m),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggle(m);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(String label,
      {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// One control row shared by the search and the category facets: a search icon
/// that expands across the row when tapped, with a second-level tag row.
class _FacetedTagFilter extends StatelessWidget {
  const _FacetedTagFilter({
    required this.tags,
    required this.activeCategory,
    required this.activeTagId,
    required this.onSelectCategory,
    required this.onSelectTag,
    required this.searchOpen,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchHint,
    required this.onOpenSearch,
    required this.onCloseSearch,
  });

  final List<ExerciseTag> tags;
  final TagCategory? activeCategory;
  final String? activeTagId;
  final ValueChanged<TagCategory?> onSelectCategory;
  final ValueChanged<String?> onSelectTag;

  final bool searchOpen;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchHint;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;

  static const double _h = 40;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final present = [
      for (final c in TagCategory.values)
        if (tags.any((t) => t.category == c)) c,
    ];
    final tagsInCategory = activeCategory == null
        ? const <ExerciseTag>[]
        : tags.where((t) => t.category == activeCategory).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.lg),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: searchOpen
                ? Padding(
                    key: const ValueKey('search'),
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(child: _searchField(l)),
                        const SizedBox(width: AppSpacing.sm),
                        _circleButton(Icons.close, onCloseSearch),
                      ],
                    ),
                  )
                : Row(
                    key: const ValueKey('pills'),
                    children: [
                      _circleButton(Icons.search, onOpenSearch),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: AppSpacing.lg),
                          child: Row(children: [
                            _filterChip(l.filterAll,
                                selected: activeCategory == null,
                                onTap: () => onSelectCategory(null)),
                            for (final c in present)
                              _filterChip(tagCategoryLabel(l, c),
                                  selected: activeCategory == c,
                                  onTap: () => onSelectCategory(c)),
                          ]),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (!searchOpen && tagsInCategory.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(children: [
              _filterChip(l.filterAll,
                  selected: activeTagId == null,
                  onTap: () => onSelectTag(null)),
              for (final t in tagsInCategory)
                _filterChip(t.label,
                    selected: activeTagId == t.id,
                    onTap: () => onSelectTag(t.id)),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _searchField(AppLocalizations l) {
    return Container(
      height: _h,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.primary,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: searchHint,
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.textTertiary),
              ),
            ),
          ),
          if (searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () => searchController.clear(),
              child: Icon(Icons.cancel,
                  size: 18, color: AppColors.textTertiary),
            ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: _h,
        height: _h,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }

  Widget _filterChip(String label,
      {required bool selected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: _h,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.surfaceBorder),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

String _cardSubtitle(AppLocalizations l, Exercise e) {
  if (e.movements.isNotEmpty) {
    return e.movements.map((m) => movementLabel(l, m)).join(' · ');
  }
  if (e.tags.isNotEmpty) return e.tags.map((t) => t.label).join(' · ');
  return '—';
}

/// A grid card: cover thumbnail on top, title + subtitle below, play badge.
class _ExerciseGridCard extends StatelessWidget {
  const _ExerciseGridCard({
    required this.exercise,
    required this.onTap,
    required this.onWatch,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg - 1)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ExerciseThumbnail(path: exercise.thumbnailStoragePath),
                    if (exercise.hasVideo)
                      Positioned(
                        right: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        child: GestureDetector(
                          onTap: onWatch,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _cardSubtitle(l, exercise),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary),
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

/// A list row: small thumbnail at left, title + subtitle, play badge at right.
class _ExerciseListCard extends StatelessWidget {
  const _ExerciseListCard({
    required this.exercise,
    required this.onTap,
    required this.onWatch,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                width: 60,
                height: 60,
                child: _ExerciseThumbnail(path: exercise.thumbnailStoragePath),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _cardSubtitle(l, exercise),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            if (exercise.hasVideo)
              GestureDetector(
                onTap: onWatch,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow_rounded,
                      size: 22, color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The cover image for a card: the public thumbnail, or a neutral placeholder.
class _ExerciseThumbnail extends StatelessWidget {
  const _ExerciseThumbnail({required this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.trim().isEmpty) {
      return const _ThumbnailPlaceholder();
    }
    return Image.network(
      ExerciseRepository.thumbnailPublicUrl(path!),
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const _ThumbnailPlaceholder(),
      errorBuilder: (_, _, _) => const _ThumbnailPlaceholder(),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: Icon(Icons.fitness_center, size: 28, color: AppColors.textTertiary),
    );
  }
}

/// Loading state matching the card grid.
class _ExerciseGridSkeleton extends StatelessWidget {
  const _ExerciseGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg,
          MediaQuery.paddingOf(context).bottom + AppSpacing.md + 60),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg - 1)),
                child: Container(color: AppColors.surfaceLight),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: SkeletonLoader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 110, height: 14),
                    SizedBox(height: 6),
                    SkeletonBox(width: 70, height: 11),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading state matching the list layout.
class _ExerciseListSkeleton extends StatelessWidget {
  const _ExerciseListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg,
          MediaQuery.paddingOf(context).bottom + AppSpacing.md + 60),
      itemCount: 7,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                  width: 60, height: 60, color: AppColors.surfaceLight),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SkeletonLoader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 140, height: 14),
                    SizedBox(height: 6),
                    SkeletonBox(width: 90, height: 11),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
