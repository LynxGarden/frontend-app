import 'package:flutter/material.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';

/// A detail-page nav bar: back button + centered title + optional
/// trailing action. Handles its own top [SafeArea] so it can sit directly
/// at the top of a `Column`/`Stack` without an `AppBar`.
class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: preferredSize.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            ),
            Text(title, style: AppTextStyles.heading3),
            if (trailing != null)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: trailing,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
