import 'dart:io' show Platform;

import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';

/// One tab in the app shell. Carries a native SF Symbol name (iOS) and a
/// Material icon (Android), plus the screen it shows.
class ShellTab {
  const ShellTab({
    required this.label,
    required this.sfSymbol,
    required this.materialIcon,
    required this.screen,
    this.refreshProviders = const [],
    this.showBadge = false,
  });

  final String label;
  final String sfSymbol;
  final IconData materialIcon;
  final Widget screen;

  /// When true, a small red notification dot is overlaid on this tab (e.g. an
  /// unread chat message).
  final bool showBadge;

  /// Data providers to invalidate when this tab **gains focus** and on
  /// **app-resume** — so a `FutureProvider`-backed screen that's kept alive by
  /// the [IndexedStack] shows fresh data instead of a stale cache. Screens
  /// already backed by a realtime `StreamProvider` (e.g. Train) leave this empty.
  final List<ProviderOrFamily> refreshProviders;
}

/// Platform-adaptive bottom shell: a native Cupertino [CNTabBar] on iOS, a
/// custom Material pill bar on Android. Body is an [IndexedStack] so tab state
/// is preserved. Pattern mirrors the reference app (kaddy).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.tabs});

  final List<ShellTab> tabs;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  int _index = 0;

  /// Bottom-bar scale: shrinks to 0.9 while scrolling down, restores to 1.0 on
  /// scroll-up and on tab change.
  double _barScale = 1.0;

  bool _onUserScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final target = switch (n.direction) {
      ScrollDirection.reverse => 0.9, // scrolling down (content moves up)
      ScrollDirection.forward => 1.0, // scrolling up
      ScrollDirection.idle => _barScale,
    };
    if (target != _barScale) setState(() => _barScale = target);
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the background: refresh every tab's data so nothing is
    // stale (the IndexedStack keeps each screen — and its providers — alive).
    if (state == AppLifecycleState.resumed) {
      for (final tab in widget.tabs) {
        for (final p in tab.refreshProviders) {
          ref.invalidate(p);
        }
      }
    }
  }

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _index = i;
      _barScale = 1.0; // restore the bar when switching tabs
    });
    // Refresh the newly-focused tab's data (skipLoadingOnRefresh keeps the
    // previous content visible while it refetches — no skeleton flash).
    for (final p in widget.tabs[i].refreshProviders) {
      ref.invalidate(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabs;
    return Scaffold(
      backgroundColor: AppColors.background,
      // Let the body extend behind the bottom bar so content reaches the screen
      // edge and scrolls under the native translucent bar (the iOS look) — no
      // reserved "container" band at the bottom. Each tab's scrollable adds the
      // bar height to its bottom padding (via MediaQuery.padding.bottom, which
      // Scaffold sets to the bar height when extendBody is true) so the last row
      // isn't hidden behind the bar.
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onUserScroll,
        child: IndexedStack(
          index: _index,
          // Disable ticking (and signal "not visible") for hidden tabs, so a
          // kept-alive screen — e.g. the client's Chat tab — knows when it's
          // actually on screen (via TickerMode.of) instead of always-active.
          children: [
            for (var i = 0; i < tabs.length; i++)
              TickerMode(enabled: i == _index, child: tabs[i].screen),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedScale(
        scale: _barScale,
        alignment: Alignment.bottomCenter,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AppBottomBar(tabs: tabs, index: _index, onTap: _select),
      ),
    );
  }
}

/// The platform-adaptive bottom bar (native Cupertino on iOS, Material pill on
/// Android). Extracted from [MainShell] so non-shell screens — e.g. the launch
/// [ShellSkeleton] — can render an identical bar for a seamless transition.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.tabs,
    required this.index,
    required this.onTap,
  });

  final List<ShellTab> tabs;
  final int index;
  final ValueChanged<int> onTap;

  /// Extra bottom offset a tab screen's [FloatingActionButton] needs so it
  /// floats *above* the shell's bottom bar. Each tab is its own Scaffold with no
  /// bottom bar, so with the shell's `extendBody:true` the FAB would anchor to
  /// the screen bottom (behind the bar). The shell surfaces the bar height via
  /// `MediaQuery.padding.bottom`; `endFloat` already lifts the FAB by the device
  /// safe area (`viewPadding.bottom`), so we add only the remainder.
  static double fabBottomInset(BuildContext context) {
    final mq = MediaQuery.of(context);
    final lift = mq.padding.bottom - mq.viewPadding.bottom;
    return lift > 0 ? lift : 0;
  }

  @override
  Widget build(BuildContext context) {
    final bar = Platform.isIOS
        ? _CupertinoBar(tabs: tabs, index: index, onTap: onTap)
        : _MaterialPillBar(tabs: tabs, index: index, onTap: onTap);
    if (!tabs.any((t) => t.showBadge)) return bar;
    // Overlay red dots on badged tabs (CNTabBar has no native badge support).
    return Stack(
      children: [
        bar,
        Positioned.fill(
          child: IgnorePointer(
            child: Padding(
              // Match each bar's geometry so the dot lands on the tab's icon.
              padding: Platform.isIOS
                  ? const EdgeInsets.only(top: 12)
                  : const EdgeInsets.fromLTRB(22, 6, 22, 18),
              child: Row(
                children: [
                  for (final t in tabs)
                    Expanded(
                      child: Align(
                        alignment: Platform.isIOS
                            ? const Alignment(0.5, -1)
                            : const Alignment(0.55, -0.9),
                        child: t.showBadge
                            ? const _BadgeDot()
                            : const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A small red notification dot with a background-colored ring so it reads on
/// the bar.
class _BadgeDot extends StatelessWidget {
  const _BadgeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
    );
  }
}

class _CupertinoBar extends StatelessWidget {
  const _CupertinoBar({
    required this.tabs,
    required this.index,
    required this.onTap,
  });

  final List<ShellTab> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      // No backgroundColor → the native UITabBar uses its default translucent
      // blur material and adapts to light/dark. With the shell's extendBody:true,
      // content scrolls *under* it so it reads as a frosted floating bar (the
      // iOS look), not a solid "container" band.
      child: CNTabBar(
        items: [
          for (final t in tabs)
            CNTabBarItem(label: t.label, icon: CNSymbol(t.sfSymbol)),
        ],
        currentIndex: index,
        onTap: onTap,
        tint: AppColors.primary,
        height: 84,
      ),
    );
  }
}

class _MaterialPillBar extends StatelessWidget {
  const _MaterialPillBar({
    required this.tabs,
    required this.index,
    required this.onTap,
  });

  final List<ShellTab> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.surfaceBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22004225),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _PillItem(
                    tab: tabs[i],
                    selected: i == index,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  const _PillItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final ShellTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onPrimary : AppColors.primary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.materialIcon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
