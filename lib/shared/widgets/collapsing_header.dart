import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lynx_app/core/theme/app_colors.dart';

/// iOS-style large-title header for a [CustomScrollView] (kaddy pattern, on the
/// Lynx cream brand). At rest: a large left-aligned [title] with an optional
/// [action]. As the list scrolls it slides/scales to small-centered over
/// [collapseDistance] px, and the bar gains a **blurred translucent** cream
/// gradient (opaque at top → clear at bottom) — the iOS Settings header.
///
/// Driven by [controller] (the same [ScrollController] as the enclosing
/// [CustomScrollView]) so the collapse rate is independent of the bar height.
class SliverCollapsingHeader extends StatelessWidget {
  const SliverCollapsingHeader({
    super.key,
    required this.title,
    required this.controller,
    this.action,
    this.collapseDistance = 90,
  });

  final String title;
  final ScrollController controller;
  final Widget? action;
  final double collapseDistance;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _CollapsingHeaderDelegate(
        title: title,
        action: action,
        controller: controller,
        collapseDistance: collapseDistance,
        topPadding: MediaQuery.of(context).padding.top,
      ),
    );
  }
}

class _CollapsingHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CollapsingHeaderDelegate({
    required this.title,
    required this.topPadding,
    required this.controller,
    required this.collapseDistance,
    this.action,
  });

  final String title;
  final double topPadding;
  final ScrollController controller;
  final double collapseDistance;
  final Widget? action;

  static const double _headerHeight = 56;

  @override
  double get minExtent => topPadding + _headerHeight;

  @override
  double get maxExtent => topPadding + _headerHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final offset = controller.hasClients && controller.positions.isNotEmpty
            ? controller.positions.first.pixels
            : 0.0;
        final t = (offset / collapseDistance).clamp(0.0, 1.0);
        return _content(t);
      },
    );
  }

  Widget _content(double t) {
    return SizedBox.expand(
      child: Stack(
        children: [
          if (t > 0.01)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: t,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.background.withValues(alpha: 0.92),
                              AppColors.background.withValues(alpha: 0.0),
                            ],
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.surfaceBorder
                                  .withValues(alpha: t * 0.9),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: topPadding,
            left: 20,
            right: lerpDouble(56, 20, t)!,
            height: _headerHeight,
            child: Align(
              alignment:
                  Alignment.lerp(Alignment.centerLeft, Alignment.center, t)!,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: lerpDouble(30, 18, t)!,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  height: 1.0,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (action != null)
            Positioned(
              top: topPadding,
              right: 16,
              height: _headerHeight,
              child: Center(child: action!),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CollapsingHeaderDelegate oldDelegate) =>
      oldDelegate.title != title ||
      oldDelegate.topPadding != topPadding ||
      oldDelegate.controller != controller ||
      oldDelegate.collapseDistance != collapseDistance ||
      oldDelegate.action != action;
}
