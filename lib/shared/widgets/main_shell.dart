import 'dart:io' show Platform;

import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
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
  });

  final String label;
  final String sfSymbol;
  final IconData materialIcon;
  final Widget screen;

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
    setState(() => _index = i);
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
      // Reserve the bottom bar's space so each tab's Scaffold lays its body and
      // FAB *above* the bar (extendBody:true let the FAB fall behind it, making
      // it untappable).
      extendBody: false,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _index,
        children: [for (final t in tabs) t.screen],
      ),
      bottomNavigationBar:
          AppBottomBar(tabs: tabs, index: _index, onTap: _select),
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

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? _CupertinoBar(tabs: tabs, index: index, onTap: onTap)
        : _MaterialPillBar(tabs: tabs, index: index, onTap: onTap);
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
      child: CNTabBar(
        items: [
          for (final t in tabs)
            CNTabBarItem(label: t.label, icon: CNSymbol(t.sfSymbol)),
        ],
        currentIndex: index,
        onTap: onTap,
        tint: AppColors.primary,
        backgroundColor: AppColors.surface,
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
