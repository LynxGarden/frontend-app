import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/avatars/avatar_config.dart';
import 'package:lynx_app/shared/avatars/notionists_options.dart';
import 'package:lynx_app/shared/models/app_user.dart';
import 'package:lynx_app/shared/widgets/app_avatar.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';

/// Feature-by-feature builder for a DiceBear notionists avatar. Returns the
/// chosen config map via [Navigator.pop] on save (null if cancelled).
class AvatarBuilderScreen extends StatefulWidget {
  const AvatarBuilderScreen(
      {super.key, this.initialConfig, this.role, this.gender});

  final Map<String, dynamic>? initialConfig;
  final AppRole? role;

  /// The person's profile gender ('male' / 'female' / null) — biases the
  /// available features (females never get a beard) and the shuffle. Set on the
  /// onboarding name step / profile settings, not here.
  final String? gender;

  @override
  State<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends State<AvatarBuilderScreen> {
  late Map<String, dynamic> _config = Map<String, dynamic>.from(
      widget.initialConfig ?? AvatarConfig.random(null, widget.gender));

  /// Feature rows to show — beard is hidden for females.
  List<AvatarCategory> get _categories => widget.gender == 'female'
      ? [for (final c in notionistsCategories) if (c.key != 'beard') c]
      : notionistsCategories;

  void _set(String key, String? value) {
    HapticFeedback.selectionClick();
    setState(() => _config[key] = value);
  }

  void _shuffle() {
    HapticFeedback.selectionClick();
    setState(() => _config = AvatarConfig.random(Random(), widget.gender));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Nav bar + live preview, separated from the feature list below by a
          // hairline whose bottom corners are rounded (no background change).
          CustomPaint(
            foregroundPainter:
                _BottomRoundedBorder(color: AppColors.surfaceBorder),
            child: Column(
              children: [
                AppNavBar(
                  title: l.buildAvatar,
                  trailing: AppNavBarAction(
                      icon: Icons.casino_outlined, onTap: _shuffle),
                ),
                // Live preview
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppAvatar(
                    avatarKind: 'dicebear',
                    avatarValue: AvatarConfig.encode(_config),
                    initials: '',
                    role: widget.role,
                    radius: 52,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  0, AppSpacing.sm, 0, AppSpacing.md),
              itemCount: _categories.length,
              itemBuilder: (_, i) => _CategoryRow(
                category: _categories[i],
                config: _config,
                role: widget.role,
                onSelect: _set,
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              child: AppButton(
                label: l.saveAvatar,
                isExpanded: true,
                onPressed: () => Navigator.of(context).pop(_config),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.config,
    required this.role,
    required this.onSelect,
  });

  final AvatarCategory category;
  final Map<String, dynamic> config;
  final AppRole? role;
  final void Function(String key, String? value) onSelect;

  /// Zoom the thumbnail onto the feature this row edits: clothing shows the
  /// chest/shoulders, everything else (hair/eyes/brows/lips/nose/glasses/beard)
  /// is on the face, so we zoom onto the head.
  // Values validated against the rendered PNGs (alpha bbox) so the head stays
  // inside the circular clip across all hairstyles — the face is centered with
  // ~10% margin and shoulders cropped; the clothing crop pans onto the torso.
  ({int scale, int translateY}) get _crop => category.key == 'body'
      ? (scale: 115, translateY: -24) // pan down to the clothing
      : (scale: 140, translateY: 14); // head centered, fills with margin

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = config[category.key] as String?;
    // Optional features get a leading "none" choice.
    final values = <String?>[
      if (category.optional) null,
      ...category.variants,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
          child: Text(_label(l, category.labelKey),
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textSecondary)),
        ),
        SizedBox(
          height: 76,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: values.length,
            itemBuilder: (_, i) {
              final value = values[i];
              final selected = current == value;
              // Thumbnail = the ACTUAL avatar being built (so gender/hair/etc
              // stay consistent — a male avatar shows a male in every row) with
              // just this one feature swapped. Face rows drop clothing so
              // changing an outfit doesn't reload the face thumbnails.
              final preview = Map<String, dynamic>.from(config);
              if (category.key != 'body') preview.remove('body');
              if (value == null) {
                preview.remove(category.key);
              } else {
                preview[category.key] = value;
              }
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => onSelect(category.key, value),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: value == null
                        ? _noneChip(l)
                        : AppAvatar(
                            avatarKind: 'dicebear',
                            avatarValue: AvatarConfig.encode(preview),
                            initials: '',
                            role: role,
                            radius: 30,
                            dicebearScale: _crop.scale,
                            dicebearTranslateY: _crop.translateY,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _noneChip(AppLocalizations l) => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceLight,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Icon(Icons.block, color: AppColors.textTertiary, size: 22),
      );

  String _label(AppLocalizations l, String key) {
    switch (key) {
      case 'avHair':
        return l.avHair;
      case 'avEyes':
        return l.avEyes;
      case 'avEyebrows':
        return l.avEyebrows;
      case 'avMouth':
        return l.avMouth;
      case 'avNose':
        return l.avNose;
      case 'avGlasses':
        return l.avGlasses;
      case 'avBeard':
        return l.avBeard;
      case 'avClothing':
        return l.avClothing;
      default:
        return key;
    }
  }
}

/// Draws only the bottom edge of the header as a hairline with rounded bottom
/// corners (a single-side [Border] can't take a radius in a [BoxDecoration]).
class _BottomRoundedBorder extends CustomPainter {
  _BottomRoundedBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const r = AppRadius.lg;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..moveTo(0, size.height - r)
      ..quadraticBezierTo(0, size.height, r, size.height)
      ..lineTo(size.width - r, size.height)
      ..quadraticBezierTo(
          size.width, size.height, size.width, size.height - r);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BottomRoundedBorder oldDelegate) =>
      oldDelegate.color != color;
}
