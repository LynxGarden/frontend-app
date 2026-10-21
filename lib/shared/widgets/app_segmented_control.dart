import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';

/// One option in an [AppSegmentedControl].
class AppSegment<T> {
  const AppSegment({required this.value, required this.label});
  final T value;
  final String label;
}

/// iOS-style segmented selector: a warm pill track with an animated
/// surface-filled thumb sliding under the selected segment. Use for small,
/// mutually-exclusive choices (e.g. gender, theme mode).
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<AppSegment<T>> segments;
  final T? selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final count = segments.length;
    final selectedIndex = segments.indexWhere((s) => s.value == selected);

    return LayoutBuilder(
      builder: (context, constraints) {
        const trackPadding = 4.0;
        final segWidth =
            (constraints.maxWidth - trackPadding * 2) / count;

        return Container(
          height: 44,
          padding: const EdgeInsets.all(trackPadding),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Stack(
            children: [
              // Sliding thumb under the selected segment.
              if (selectedIndex >= 0)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  left: segWidth * selectedIndex,
                  top: 0,
                  bottom: 0,
                  width: segWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      boxShadow: AppShadows.card,
                    ),
                  ),
                ),
              Row(
                children: [
                  for (final seg in segments)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (seg.value == selected) return;
                          HapticFeedback.selectionClick();
                          onChanged(seg.value);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                seg.label,
                                maxLines: 1,
                                softWrap: false,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.button.copyWith(
                                  fontSize: 14,
                                  color: seg.value == selected
                                      ? AppColors.onPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
