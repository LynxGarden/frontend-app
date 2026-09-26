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
  const AvatarBuilderScreen({super.key, this.initialConfig, this.role});

  final Map<String, dynamic>? initialConfig;
  final AppRole? role;

  @override
  State<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends State<AvatarBuilderScreen> {
  late Map<String, dynamic> _config =
      Map<String, dynamic>.from(widget.initialConfig ?? AvatarConfig.random());

  void _set(String key, String? value) {
    HapticFeedback.selectionClick();
    setState(() => _config[key] = value);
  }

  void _shuffle() {
    HapticFeedback.selectionClick();
    setState(() => _config = AvatarConfig.random(Random()));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppNavBar(
            title: l.buildAvatar,
            trailing: AppNavBarAction(icon: Icons.casino_outlined, onTap: _shuffle),
          ),
          // Live preview
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: AppAvatar(
              avatarKind: 'dicebear',
              avatarValue: AvatarConfig.encode(_config),
              initials: '',
              role: widget.role,
              radius: 52,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  0, AppSpacing.sm, 0, AppSpacing.md),
              itemCount: notionistsCategories.length,
              itemBuilder: (_, i) => _CategoryRow(
                category: notionistsCategories[i],
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
              final preview = Map<String, dynamic>.from(config)
                ..[category.key] = value;
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
