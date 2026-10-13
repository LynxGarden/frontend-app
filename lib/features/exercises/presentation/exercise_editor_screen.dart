import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/exercises/data/exercise_repository.dart';
import 'package:lynx_app/features/exercises/data/models/exercise.dart';
import 'package:lynx_app/features/exercises/data/models/exercise_tag.dart';
import 'package:lynx_app/features/exercises/data/models/metric_field.dart';
import 'package:lynx_app/features/exercises/data/models/movement.dart';
import 'package:lynx_app/features/exercises/presentation/movement_labels.dart';
import 'package:lynx_app/features/exercises/presentation/tag_labels.dart';
import 'package:lynx_app/features/exercises/presentation/widgets/metric_schema_editor.dart';
import 'package:lynx_app/features/exercises/providers/exercises_provider.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_chip.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';
import 'package:lynx_app/shared/widgets/frosted_nav_scaffold.dart';

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
  final Set<Movement> _movements = {};
  List<MetricField> _metricSchema = [];
  bool _movementTouched = false;
  bool _saving = false;
  bool _uploading = false;
  bool _uploadingThumb = false;
  String? _videoStoragePath;
  String? _thumbnailStoragePath;
  File? _thumbnailPreview; // local file shown until/after upload
  bool _thumbTouched = false; // show the "required" error only after interaction

  bool get _isEdit => widget.exercise != null;

  /// Name + thumbnail are required — Save stays disabled until both are set.
  bool get _canSave =>
      _name.text.trim().isNotEmpty && _thumbnailStoragePath != null;

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _name = TextEditingController(text: e?.name ?? '')
      ..addListener(() => setState(() {})); // toggles the Save button

    _description = TextEditingController(text: e?.description ?? '');
    _videoUrl = TextEditingController(text: e?.videoUrl ?? '');
    _videoStoragePath = e?.videoStoragePath;
    _thumbnailStoragePath = e?.thumbnailStoragePath;
    _selectedTagIds.addAll(e?.tags.map((t) => t.id) ?? const []);
    _movements.addAll(e?.movements ?? const []);
    _metricSchema = List.of(e?.metricSchema ?? const []);
  }

  Future<void> _pickAndUploadThumbnail() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _thumbnailPreview = File(picked.path);
      _thumbTouched = true;
      _uploadingThumb = true;
    });
    try {
      final path = await ExerciseRepository.uploadThumbnail(
        tenantId: user.tenantId,
        file: File(picked.path),
      );
      if (mounted) setState(() => _thumbnailStoragePath = path);
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _thumbnailPreview = null);
        AppToast.show(context, title: e.message, blur: false);
      }
    } finally {
      if (mounted) setState(() => _uploadingThumb = false);
    }
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
    if (_thumbnailStoragePath == null) {
      setState(() => _thumbTouched = true);
      AppToast.show(context,
          title: AppLocalizations.of(context).thumbnailRequired, blur: false);
      return;
    }
    if (_movements.isEmpty) {
      setState(() => _movementTouched = true);
      AppToast.show(context,
          title: AppLocalizations.of(context).movementRequired, blur: false);
      return;
    }
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
          thumbnailStoragePath: _thumbnailStoragePath,
          tagIds: _selectedTagIds.toList(),
          movements: _movements.toList(),
          metricSchema: _metricSchema,
        );
      } else {
        await ExerciseRepository.create(
          tenantId: user.tenantId,
          ownerId: user.personId,
          name: _name.text,
          description: _description.text,
          videoUrl: _videoUrl.text,
          videoStoragePath: _videoStoragePath,
          thumbnailStoragePath: _thumbnailStoragePath,
          tagIds: _selectedTagIds.toList(),
          movements: _movements.toList(),
          metricSchema: _metricSchema,
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

    return FrostedNavScaffold(
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
      footer: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
        ),
        child: SafeArea(
          top: false,
          child: AppButton(
            label: l.save,
            isExpanded: true,
            isLoading: _saving,
            onPressed: (_saving || !_canSave) ? null : _save,
          ),
        ),
      ),
      builder: (context, topInset) => SafeArea(
        top: false,
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, topInset + AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
            children: [
              _ThumbnailPicker(
                previewFile: _thumbnailPreview,
                storagePath: _thumbnailStoragePath,
                uploading: _uploadingThumb,
                showError: _thumbTouched && _thumbnailStoragePath == null,
                onTap: _uploadingThumb ? null : _pickAndUploadThumbnail,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: l.exerciseName,
                controller: _name,
                hintText: l.exerciseNameHint,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.nameRequired : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Movement classification — required, multi-select (coach-only).
              Text(l.movement, style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in Movement.values)
                    AppChip(
                      label: movementLabel(l, m),
                      selected: _movements.contains(m),
                      onTap: () => setState(() {
                        if (!_movements.remove(m)) _movements.add(m);
                        _movementTouched = true;
                      }),
                    ),
                ],
              ),
              if (_movementTouched && _movements.isEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(l.movementRequired,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error)),
              ],
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
                      Icon(Icons.check_circle,
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

              // Config-driven logging fields for this exercise.
              Text(l.loggingFields, style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.xs),
              Text(l.loggingFieldsHint,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textTertiary)),
              const SizedBox(height: AppSpacing.sm),
              MetricSchemaEditor(
                initial: _metricSchema,
                onChanged: (v) => _metricSchema = v,
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Required cover-image picker: a 16:9 tappable tile that shows the chosen image
/// (local preview or the uploaded public URL), an upload spinner, or an empty
/// prompt. Turns to the error color when the field is required but empty.
class _ThumbnailPicker extends StatelessWidget {
  const _ThumbnailPicker({
    required this.previewFile,
    required this.storagePath,
    required this.uploading,
    required this.showError,
    required this.onTap,
  });

  final File? previewFile;
  final String? storagePath;
  final bool uploading;
  final bool showError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasImage = previewFile != null || storagePath != null;
    final borderColor = showError ? AppColors.error : AppColors.surfaceBorder;

    Widget image;
    if (previewFile != null) {
      image = Image.file(previewFile!, fit: BoxFit.cover);
    } else if (storagePath != null) {
      image = Image.network(
        ExerciseRepository.thumbnailPublicUrl(storagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _empty(l, error: true),
      );
    } else {
      image = _empty(l);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap?.call();
          },
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderColor),
              ),
              child: ClipRRect(
                // Inset by the 1px border so the clip sits inside it, not on it.
                borderRadius: BorderRadius.circular(AppRadius.lg - 1),
                child: Stack(
                fit: StackFit.expand,
                children: [
                  image,
                  if (uploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                  // "Change photo" affordance over an existing image.
                  if (hasImage && !uploading)
                    Positioned(
                      right: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_camera_outlined,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(l.changeThumbnail,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                ],
                ),
              ),
            ),
          ),
        ),
        if (showError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(l.thumbnailRequired,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
        ],
      ],
    );
  }

  Widget _empty(AppLocalizations l, {bool error = false}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 32, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.sm),
          Text(l.addThumbnail,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(l.thumbnailHint,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiary)),
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
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceBorder,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(l.addTag, style: AppTextStyles.heading3),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.category.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final c in TagCategory.values)
                AppChip(
                  label: tagCategoryLabel(l, c),
                  selected: _category == c,
                  onTap: () => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: l.tagName, controller: _label, hintText: ''),
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
