import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/shared/avatars/avatar_config.dart';
import 'package:lynx_app/shared/models/app_user.dart';
import 'package:lynx_app/shared/providers/avatar_photo_url_provider.dart';

/// Circular avatar shown everywhere in place of initials.
///
/// - `dicebear` → DiceBear notionists PNG built from the stored config.
/// - `photo`    → uploaded photo via a signed URL (private bucket).
/// - otherwise  → initials.
///
/// The disc is a light role-tinted fill with a role-colored ring so black
/// line-art avatars and initials stay legible while still reading the person's
/// role (client / coach / physio).
class AppAvatar extends ConsumerWidget {
  const AppAvatar({
    super.key,
    required this.avatarKind,
    required this.avatarValue,
    required this.initials,
    this.role,
    this.radius = 22,
    this.dicebearScale = 92,
    this.dicebearTranslateY = 8,
  });

  final String? avatarKind;
  final String? avatarValue;
  final String initials;
  final AppRole? role;
  final double radius;

  /// Framing for the DiceBear render. Defaults give the app-wide portrait crop;
  /// the avatar builder overrides them to zoom feature thumbnails.
  final int dicebearScale;
  final int dicebearTranslateY;

  ({Color bg, Color ring}) _roleColors() {
    switch (role) {
      case AppRole.coach:
      case AppRole.owner:
        return (bg: AppColors.avatarCoachBg, ring: AppColors.avatarCoachRing);
      case AppRole.physio:
        return (bg: AppColors.avatarPhysioBg, ring: AppColors.avatarPhysioRing);
      case AppRole.client:
      case null:
        return (bg: AppColors.avatarClientBg, ring: AppColors.avatarClientRing);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = _roleColors();
    final size = radius * 2;
    final px = (size * MediaQuery.devicePixelRatioOf(context))
        .clamp(48, 512)
        .round();

    Widget content;
    if (avatarKind == 'dicebear' && avatarValue != null) {
      content = CachedNetworkImage(
        imageUrl: AvatarConfig.url(
          AvatarConfig.decode(avatarValue!),
          size: px,
          scale: dicebearScale,
          translateY: dicebearTranslateY,
        ),
        fit: BoxFit.contain,
        placeholder: (_, _) => _initials(colors.ring),
        errorWidget: (_, _, _) => _initials(colors.ring),
      );
    } else if (avatarKind == 'photo' && avatarValue != null) {
      final urlAsync = ref.watch(avatarPhotoUrlProvider(avatarValue!));
      content = urlAsync.when(
        loading: () => _initials(colors.ring),
        error: (_, _) => _initials(colors.ring),
        data: (url) => CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, _) => _initials(colors.ring),
          errorWidget: (_, _, _) => _initials(colors.ring),
        ),
      );
    } else {
      content = _initials(colors.ring);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.bg,
        shape: BoxShape.circle,
        border: Border.all(color: colors.ring, width: radius >= 28 ? 2 : 1.5),
      ),
      // Hard-clip the figure to the disc so a fill-framed avatar is cropped by
      // the ring instead of ever spilling past it.
      child: ClipOval(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(width: size, height: size, child: content),
      ),
    );
  }

  Widget _initials(Color color) => Center(
        child: Text(
          initials,
          style: AppTextStyles.button.copyWith(
            color: color,
            fontSize: radius * 0.7,
          ),
        ),
      );
}
