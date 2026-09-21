import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/features/exercises/data/models/exercise.dart';
import 'package:lynx_app/features/exercises/data/models/exercise_tag.dart';
import 'package:lynx_app/features/exercises/presentation/exercise_editor_screen.dart';
import 'package:lynx_app/features/exercises/providers/exercises_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

/// Coach exercise library: searchable list, tag filter, add/edit/delete.
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _search = TextEditingController();
  String? _activeTagId; // null = All

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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

  Future<void> _watch(Exercise e) async {
    final l = AppLocalizations.of(context);
    final url = e.videoUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    final ok = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppToast.show(context, title: l.couldNotOpenVideo, blur: false);
    }
  }

  List<Exercise> _filter(List<Exercise> all) {
    final q = _search.text.trim().toLowerCase();
    return all.where((e) {
      final matchesQuery = q.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          (e.description?.toLowerCase().contains(q) ?? false);
      final matchesTag =
          _activeTagId == null || e.tags.any((t) => t.id == _activeTagId);
      return matchesQuery && matchesTag;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final exercisesAsync = ref.watch(exercisesProvider);
    final tagsAsync = ref.watch(exerciseTagsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.libraryTitle, style: AppTextStyles.heading3)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(l.newExercise),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: AppTextField(
                label: l.searchExercises,
                controller: _search,
                hintText: l.searchExercises,
              ),
            ),
            // Tag filter row
            tagsAsync.maybeWhen(
              data: (tags) => tags.isEmpty
                  ? const SizedBox.shrink()
                  : _TagFilterRow(
                      tags: tags,
                      activeTagId: _activeTagId,
                      onSelect: (id) => setState(() => _activeTagId = id),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
            Expanded(
              child: exercisesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: AppColors.forest)),
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
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
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

class _TagFilterRow extends StatelessWidget {
  const _TagFilterRow({
    required this.tags,
    required this.activeTagId,
    required this.onSelect,
  });

  final List<ExerciseTag> tags;
  final String? activeTagId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          _chip(context, label: l.filterAll, selected: activeTagId == null,
              onTap: () => onSelect(null)),
          for (final t in tags)
            _chip(context,
                label: t.label,
                selected: activeTagId == t.id,
                onTap: () => onSelect(t.id)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context,
      {required String label, required bool selected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.forest : AppColors.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
                color: selected ? AppColors.forest : AppColors.surfaceBorder),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.textPrimary,
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
                icon: const Icon(Icons.play_circle_outline,
                    color: AppColors.forest),
                onPressed: onWatch,
              ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
