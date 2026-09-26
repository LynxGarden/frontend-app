import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/exercises/data/exercise_repository.dart';
import 'package:lynx_app/features/exercises/data/models/exercise.dart';
import 'package:lynx_app/features/exercises/data/models/exercise_tag.dart';
import 'package:lynx_app/features/exercises/presentation/tag_labels.dart';
import 'package:lynx_app/features/exercises/providers/exercises_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

/// Create / edit an exercise. Returns `true` via pop when saved so the caller
/// can refresh the library.
class ExerciseEditorScreen extends ConsumerStatefulWidget {
  const ExerciseEditorScreen({super.key, this.exercise});

  final Exercise? exercise;

  @override
  ConsumerState<ExerciseEditorScreen> createState() =>
      _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends ConsumerState<ExerciseEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _videoUrl;
  final Set<String> _selectedTagIds = {};
  bool _saving = false;
  bool _uploading = false;
  String? _videoStoragePath;

  bool get _isEdit => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _name = TextEditingController(text: e?.name ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _videoUrl = TextEditingController(text: e?.videoUrl ?? '');
    _videoStoragePath = e?.videoStoragePath;
    _selectedTagIds.addAll(e?.tags.map((t) => t.id) ?? const []);
  }

  Future<void> _pickAndUploadVideo() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final picked =
        await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final path = await ExerciseRepository.uploadVideo(
        tenantId: user.tenantId,
        file: File(picked.path),
      );
      if (mounted) setState(() => _videoStoragePath = path);
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _videoUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await ExerciseRepository.update(
          tenantId: user.tenantId,
          exerciseId: widget.exercise!.id,
          name: _name.text,
          description: _description.text,
          videoUrl: _videoUrl.text,
          videoStoragePath: _videoStoragePath,
          tagIds: _selectedTagIds.toList(),
        );
      } else {
        await ExerciseRepository.create(
          tenantId: user.tenantId,
          ownerId: user.personId,
          name: _name.text,
          description: _description.text,
          videoUrl: _videoUrl.text,
          videoStoragePath: _videoStoragePath,
          tagIds: _selectedTagIds.toList(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    } catch (_) {
      if (mounted) {
        AppToast.show(context,
            title: AppLocalizations.of(context).somethingWentWrong, blur: false);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final l = AppLocalizations.of(context);
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l.deleteExerciseTitle, style: AppTextStyles.heading3),
        content: Text(l.deleteExerciseBody, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.delete,
                style: AppTextStyles.button.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await ExerciseRepository.delete(
        tenantId: user.tenantId,
        exerciseId: widget.exercise!.id,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppToast.show(context, title: e.message, blur: false);
      }
    }
  }

  Future<void> _addTag() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final created = await showDialog<ExerciseTag>(
      context: context,
      builder: (_) => const _AddTagDialog(),
    );
    if (created == null) return;
    // Persist (find-or-create) and select it.
    try {
      final id = await ExerciseRepository.ensureTag(
        tenantId: user.tenantId,
        ownerId: user.personId,
        category: created.category,
        label: created.label,
      );
      if (!mounted) return;
      setState(() => _selectedTagIds.add(id));
      ref.invalidate(exerciseTagsProvider);
    } on AppException catch (e) {
      if (mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tagsAsync = ref.watch(exerciseTagsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppNavBar(
            title: _isEdit ? l.editExercise : l.newExercise,
            trailing: _isEdit
                ? AppNavBarAction(
                    icon: Icons.delete_outline,
                    onTap: () {
                      if (!_saving) _confirmDelete();
                    },
                    tint: AppColors.error,
                  )
                : null,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
              AppTextField(
                label: l.exerciseName,
                controller: _name,
                hintText: l.exerciseNameHint,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.nameRequired : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l.exerciseVideoUrl,
                controller: _videoUrl,
                hintText: l.exerciseVideoUrlHint,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              // Hosted video upload
              Text(l.demoVideo, style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              if (_videoStoragePath == null)
                AppButton(
                  label: l.uploadVideo,
                  variant: AppButtonVariant.secondary,
                  isExpanded: true,
                  isLoading: _uploading,
                  onPressed: _uploading ? null : _pickAndUploadVideo,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 18, color: AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(l.videoUploaded,
                            style: AppTextStyles.bodySmall),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _videoStoragePath = null),
                        child: Text(l.remove,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l.exerciseDescription,
                controller: _description,
                hintText: '',
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.tags, style: AppTextStyles.label),
                  GestureDetector(
                    onTap: _addTag,
                    child: Text(
                      '+ ${l.addTag}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              tagsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: LinearProgressIndicator(),
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (tags) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in tags)
                      _TagChip(
                        tag: t,
                        selected: _selectedTagIds.contains(t.id),
                        onTap: () => setState(() {
                          if (!_selectedTagIds.remove(t.id)) {
                            _selectedTagIds.add(t.id);
                          }
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: l.save,
                isExpanded: true,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag, required this.selected, required this.onTap});
  final ExerciseTag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.forest : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.forest : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          '${tagCategoryLabel(l, tag.category)}: ${tag.label}',
          style: AppTextStyles.bodySmall.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _AddTagDialog extends StatefulWidget {
  const _AddTagDialog();

  @override
  State<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
  final _label = TextEditingController();
  TagCategory _category = TagCategory.movementPattern;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l.addTag, style: AppTextStyles.heading3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<TagCategory>(
            value: _category,
            isExpanded: true,
            onChanged: (c) => setState(() => _category = c ?? _category),
            items: [
              for (final c in TagCategory.values)
                DropdownMenuItem(value: c, child: Text(tagCategoryLabel(l, c))),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(label: l.tags, controller: _label, hintText: ''),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () {
            final label = _label.text.trim();
            if (label.isEmpty) return;
            Navigator.of(context).pop(
              ExerciseTag(id: '', category: _category, label: label),
            );
          },
          child: Text(l.addTag),
        ),
      ],
    );
  }
}
