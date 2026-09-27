import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/shared/widgets/app_nav_bar.dart';

/// A Scaffold whose [AppNavBar] is a **floating, scroll-aware overlay**: the
/// scrollable body extends behind it. At the top the bar is fully transparent
/// (no container box) at full size; as the body scrolls it frosts (blur +
/// translucent fade) and shrinks to 0.9 — restoring on scroll-up / new screen.
///
/// The [builder] receives `topInset` (header height) which you MUST add to the
/// top padding of the screen's scrollable so nothing starts hidden. An optional
/// [footer] is pinned at the bottom (e.g. a Save button), outside the overlay.
class FrostedNavScaffold extends StatefulWidget {
  const FrostedNavScaffold({
    super.key,
    required this.title,
    required this.builder,
    this.trailing,
    this.showBack = true,
    this.onBack,
    this.footer,
  });

  final String title;
  final Widget? trailing;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget Function(BuildContext context, double topInset) builder;
  final Widget? footer;

  @override
  State<FrostedNavScaffold> createState() => _FrostedNavScaffoldState();
}

class _FrostedNavScaffoldState extends State<FrostedNavScaffold> {
  double _collapse = 0;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    // Collapse over the first 60px of scroll.
    final t = (n.metrics.pixels / 60).clamp(0.0, 1.0);
    if ((t - _collapse).abs() > 0.01) setState(() => _collapse = t);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: Column(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (c) => widget.builder(
                          c, AppNavBar.estimatedHeight(c)),
                    ),
                  ),
                  ?widget.footer,
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppNavBar(
              title: widget.title,
              trailing: widget.trailing,
              showBack: widget.showBack,
              onBack: widget.onBack,
              blurred: true,
              frost: _collapse,
              scale: lerpDouble(1.0, 0.9, _collapse)!,
            ),
          ),
        ],
      ),
    );
  }
}
