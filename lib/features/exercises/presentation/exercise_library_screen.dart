import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/exercises/data/exercise_repository.dart';
import 'package:lynx_app/features/exercises/data/models/exercise.dart';
import 'package:lynx_app/features/exercises/data/models/exercise_tag.dart';
import 'package:lynx_app/features/exercises/presentation/exercise_editor_screen.dart';
import 'package:lynx_app/features/exercises/presentation/exercise_video.dart';
import 'package:lynx_app/features/exercises/presentation/tag_labels.dart';
import 'package:lynx_app/features/exercises/providers/exercises_provider.dart';
import 'package:lynx_app/features/programs/presentation/program_list_screen.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/main_shell.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// Coach exercise library: searchable list, tag filter, add/edit/delete.
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

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
      return matchesQuery && matchesCategory && matchesTag;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final exercisesAsync = ref.watch(exercisesProvider);
    final tagsAsync = ref.watch(exerciseTagsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.libraryTitle, style: AppTextStyles.heading3),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProgramListScreen()),
            ),
            icon: Icon(Icons.dashboard_customize_outlined,
                size: 18, color: AppColors.primary),
            label: Text(l.programsTitle,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
          ),
        ],
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
      // bottom:false — the shell's extendBody makes MediaQuery.padding.bottom the
      // bar height, so a bottom SafeArea would reserve an empty band here; the
      // ListView's own bottom padding clears the floating bar instead.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            // Search icon + category facets share one row; the search expands
            // across the row when tapped and collapses the pills.
            _FacetedTagFilter(
              tags: tagsAsync.maybeWhen(
                  data: (t) => t, orElse: () => const []),
              activeCategory: _activeCategory,
              activeTagId: _activeTagId,
              onSelectCategory: (c) => setState(() {
                _activeCategory = c;
                _activeTagId = null; // reset tag when the facet changes
              }),
              onSelectTag: (id) => setState(() => _activeTagId = id),
              searchOpen: _searchOpen,
              searchController: _search,
              searchFocusNode: _searchFocus,
              searchHint: l.searchExercises,
              onOpenSearch: _openSearch,
              onCloseSearch: _closeSearch,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: exercisesAsync.when(
                loading: () => const _ExerciseGridSkeleton(),
                error: (_, _) => Center(
                  child: Text(l.somethingWentWrong, style: AppTextStyles.bodySmall),
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
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm,
                        AppSpacing.lg,
                        MediaQuery.paddingOf(context).bottom + AppSpacing.md + 60),
                    gridDelegate: _gridDelegate,
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ExerciseGridCard(
                      exercise: items[i],
                      onTap: () => _openEditor(items[i]),
                      onWatch: () => _watch(items[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// One control row shared by the search and the category facets (the remi
/// pattern): a search icon sits at the start of the pills row and expands across
/// the whole row when tapped, collapsing the pills; a ✕ closes it. Below sits the
/// second-level tag row for the chosen category.
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

    // Categories present in the library, in enum order.
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
          // Left inset only — the pills scroll to the right edge (their trailing
          // inset lives inside the scroll view, below) so the last chip isn't
          // clipped against a dead gap.
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
        // Tag row for the selected category (hidden while searching).
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

/// 2-column grid geometry: square-ish cards with room for a title + tags line.
const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  crossAxisSpacing: AppSpacing.md,
  mainAxisSpacing: AppSpacing.md,
  childAspectRatio: 0.72,
);

/// A library card: cover thumbnail on top, title + tags below. A small play
/// badge overlays the image when the exercise has a video.
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
                // Inset by the 1px border so the clip sits inside it, not on it.
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
                    exercise.tags.isEmpty
                        ? '—'
                        : exercise.tags.map((t) => t.label).join(' · '),
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

/// The cover image for a card: the public thumbnail, or a neutral placeholder
/// for legacy exercises saved before thumbnails were required.
class _ExerciseThumbnail extends StatelessWidget {
  const _ExerciseThumbnail({required this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.trim().isEmpty) return const _ThumbnailPlaceholder();
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
      child: Icon(Icons.fitness_center,
          size: 28, color: AppColors.textTertiary),
    );
  }
}

/// Loading state matching the 2-column card grid.
class _ExerciseGridSkeleton extends StatelessWidget {
  const _ExerciseGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg,
          MediaQuery.paddingOf(context).bottom + AppSpacing.md + 60),
      gridDelegate: _gridDelegate,
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
