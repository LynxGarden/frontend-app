import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/exercises/data/models/exercise.dart';
import 'package:lynx_app/features/exercises/data/models/exercise_tag.dart';
import 'package:lynx_app/features/exercises/presentation/exercise_editor_screen.dart';
import 'package:lynx_app/features/exercises/presentation/exercise_video.dart';
import 'package:lynx_app/features/exercises/presentation/tag_labels.dart';
import 'package:lynx_app/features/exercises/providers/exercises_provider.dart';
import 'package:lynx_app/features/programs/presentation/program_list_screen.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/main_shell.dart';
import 'package:lynx_app/shared/widgets/skeleton_list.dart';

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
                loading: () => const SkeletonList(),
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
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm,
                        AppSpacing.lg, MediaQuery.paddingOf(context).bottom + AppSpacing.md),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ExerciseTile(
                      exercise: items[i],
                      onTap: () => _openEditor(items[i]),
                      onWatch: () => _watch(items[i]),
                    ),
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: searchOpen
                ? Row(
                    key: const ValueKey('search'),
                    children: [
                      Expanded(child: _searchField(l)),
                      const SizedBox(width: AppSpacing.sm),
                      _circleButton(Icons.close, onCloseSearch),
                    ],
                  )
                : Row(
                    key: const ValueKey('pills'),
                    children: [
                      _circleButton(Icons.search, onOpenSearch),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
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

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
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
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name, style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600)),
                  if (exercise.tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      exercise.tags.map((t) => t.label).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (exercise.hasVideo)
              IconButton(
                icon: Icon(Icons.play_circle_outline,
                    color: AppColors.primary),
                onPressed: onWatch,
              ),
            Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
