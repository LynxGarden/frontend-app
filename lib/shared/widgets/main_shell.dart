import 'dart:io' show Platform;

import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  });

  final String label;
  final String sfSymbol;
  final IconData materialIcon;
  final Widget screen;
}

/// Platform-adaptive bottom shell: a native Cupertino [CNTabBar] on iOS, a
/// custom Material pill bar on Android. Body is an [IndexedStack] so tab state
/// is preserved. Pattern mirrors the reference app (kaddy).
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.tabs});

  final List<ShellTab> tabs;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabs;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _index,
        children: [for (final t in tabs) t.screen],
      ),
      bottomNavigationBar: Platform.isIOS
          ? _CupertinoBar(tabs: tabs, index: _index, onTap: _select)
          : _MaterialPillBar(tabs: tabs, index: _index, onTap: _select),
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
      child: CNTabBar(
        items: [
          for (final t in tabs)
            CNTabBarItem(label: t.label, icon: CNSymbol(t.sfSymbol)),
        ],
        currentIndex: index,
        onTap: onTap,
        tint: AppColors.forest,
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
            border: Border.all(color: AppColors.line),
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
    final color = selected ? AppColors.onPrimary : AppColors.forest;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.forest : Colors.transparent,
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
