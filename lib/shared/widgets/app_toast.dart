import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';

/// A branded top-of-screen toast notification.
///
/// Call [AppToast.show] from anywhere with a [BuildContext].
class AppToast {
  AppToast._();

  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    bool blur = true,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _AppToastWidget(
        title: title,
        subtitle: subtitle,
        blur: blur,
        topPadding: topPadding,
        duration: duration,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _AppToastWidget extends StatefulWidget {
  const _AppToastWidget({
    required this.title,
    required this.topPadding,
    required this.duration,
    required this.onDismiss,
    this.subtitle,
    this.blur = true,
  });

  final String title;
  final String? subtitle;
  final bool blur;
  final double topPadding;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 250),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            if (widget.blur)
              Positioned.fill(
                child: IgnorePointer(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 6.0 * _fadeAnimation.value,
                      sigmaY: 6.0 * _fadeAnimation.value,
                    ),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.2 * _fadeAnimation.value),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: widget.topPadding + AppSpacing.sm,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: GestureDetector(
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! < 0) {
                        _dismiss();
                      }
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: AppTextStyles.body
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  if (widget.subtitle != null) ...[
                                    const SizedBox(height: 2),
                                    Text(widget.subtitle!, style: AppTextStyles.bodySmall),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            GestureDetector(
                              onTap: _dismiss,
                              behavior: HitTestBehavior.opaque,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
