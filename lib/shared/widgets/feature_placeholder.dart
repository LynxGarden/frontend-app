import 'package:flutter/material.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/l10n/app_localizations.dart';

/// A minimal tab screen for CP0 — titled header + "coming soon". Real feature
/// screens replace these at their checkpoints.
class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title, style: AppTextStyles.heading3)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.primaryDim),
            const SizedBox(height: AppSpacing.md),
            Text(l.comingSoon, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
