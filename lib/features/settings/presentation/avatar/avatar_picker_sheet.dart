import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/settings/data/profile_repository.dart';
import 'package:lynx_app/features/settings/presentation/avatar/avatar_builder_screen.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/avatars/avatar_config.dart';
import 'package:lynx_app/shared/models/app_user.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

/// Bottom sheet to set the avatar: build (DiceBear), upload a photo, or remove.
/// Persists the choice to `users_data` and invalidates [currentUserProvider].
/// Returns true if the avatar changed.
Future<bool> showAvatarPicker(
  BuildContext context,
  WidgetRef ref, {
  required String personId,
  required String tenantId,
  AppRole? role,
  String? currentKind,
  String? currentValue,
}) async {
  final changed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) => _AvatarPickerBody(
      ref: ref,
      personId: personId,
      tenantId: tenantId,
      role: role,
      currentKind: currentKind,
      currentValue: currentValue,
    ),
  );
  return changed ?? false;
}

class _AvatarPickerBody extends StatelessWidget {
  const _AvatarPickerBody({
    required this.ref,
    required this.personId,
    required this.tenantId,
    required this.role,
    required this.currentKind,
    required this.currentValue,
  });

  final WidgetRef ref;
  final String personId;
  final String tenantId;
  final AppRole? role;
  final String? currentKind;
  final String? currentValue;

  Future<void> _build(BuildContext context) async {
    final initial = currentKind == 'dicebear' && currentValue != null
        ? AvatarConfig.decode(currentValue!)
        : null;
    final config = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => AvatarBuilderScreen(initialConfig: initial, role: role),
      ),
    );
    if (config == null) return;
    try {
      await ProfileRepository.setAvatar(
        personId: personId,
        kind: 'dicebear',
        value: AvatarConfig.encode(config),
      );
      ref.invalidate(currentUserProvider);
      if (context.mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _upload(BuildContext context) async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (picked == null || !context.mounted) return;
    try {
      final path = await ProfileRepository.uploadAvatarPhoto(
        tenantId: tenantId,
        personId: personId,
        file: File(picked.path),
      );
      await ProfileRepository.setAvatar(
          personId: personId, kind: 'photo', value: path);
      ref.invalidate(currentUserProvider);
      if (context.mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  Future<void> _remove(BuildContext context) async {
    try {
      await ProfileRepository.setAvatar(
          personId: personId, kind: null, value: null);
      ref.invalidate(currentUserProvider);
      if (context.mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (context.mounted) AppToast.show(context, title: e.message, blur: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tile(context, Icons.face_retouching_natural, l.buildAvatar,
                () => _build(context)),
            _tile(context, Icons.photo_library_outlined, l.uploadPhoto,
                () => _upload(context)),
            if (currentKind != null)
              _tile(context, Icons.delete_outline, l.removePhoto,
                  () => _remove(context), danger: true),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label,
      VoidCallback onTap, {bool danger = false}) {
    final color = danger ? AppColors.error : AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: danger ? AppColors.error : AppColors.primary),
      title: Text(label, style: AppTextStyles.body.copyWith(color: color)),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}
