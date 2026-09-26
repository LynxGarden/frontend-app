import 'package:flutter/material.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/collapsing_header.dart';
import 'package:lynx_app/shared/widgets/main_shell.dart';
import 'package:lynx_app/shared/widgets/skeleton_loader.dart';

/// A single shimmering placeholder row: an icon/avatar block + two text lines.
/// Matches the rhythm of the app's list rows so the swap to real data is calm.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          SkeletonBox(width: 44, height: 44, borderRadius: AppRadius.md),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 170, height: 14),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 110, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A padded column of [count] shimmering [SkeletonRow]s — a drop-in loading
/// state for list bodies (`when(loading: () => const SkeletonList())`).
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 7, this.padding});

  final int count;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Padding(
        padding: padding ??
            const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [for (var i = 0; i < count; i++) const SkeletonRow()],
        ),
      ),
    );
  }
}

/// Sliver wrapper for [SkeletonList], for `CustomScrollView`-based screens with
/// a collapsing header (`SliverSkeletonList()` in the `loading:` branch).
class SliverSkeletonList extends StatelessWidget {
  const SliverSkeletonList({super.key, this.count = 7});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: SkeletonList(count: count));
  }
}

/// Loading placeholder tailored to the **Train** tab: a program-name header bar
/// followed by [count] session-card placeholders that mirror `_SessionCard` — an
/// `AppCard`-shaped surface with a title + subtitle and a trailing chevron, and
/// (unlike the generic [SkeletonRow]/[_SkeletonCard]) **no leading icon**. Mirrors
/// the data branch's padding so nothing shifts on the swap to real data.
class SliverTrainSkeleton extends StatelessWidget {
  const SliverTrainSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Program-name subheader (matches item 0: heading3, bottom md).
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: SkeletonLoader(child: SkeletonBox(width: 160, height: 20)),
            ),
            for (var i = 0; i < count; i++) const _TrainSkeletonCard(),
          ],
        ),
      ),
    );
  }
}

/// A session-card placeholder matching `_SessionCard`: an `AppCard`-style surface
/// (real surface + border + shadow, NOT shimmered) holding a title bar + shorter
/// subtitle bar with a trailing chevron placeholder, and no leading icon.
class _TrainSkeletonCard extends StatelessWidget {
  const _TrainSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: AppShadows.card,
      ),
      child: SkeletonLoader(
        child: Row(
          children: const [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 150, height: 15),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(width: 90, height: 12),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            SkeletonBox(width: 18, height: 18, borderRadius: AppRadius.sm),
          ],
        ),
      ),
    );
  }
}

/// Sliver of card-shaped skeletons (matching `AppCard` list rows). Used by both
/// the launch [ShellSkeleton] and the Clients list's own loading state so the two
/// loading phases are visually identical — no flicker on the handover.
class SliverSkeletonCards extends StatelessWidget {
  const SliverSkeletonCards({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
        child: Column(
          children: [for (var i = 0; i < count; i++) const _SkeletonCard()],
        ),
      ),
    );
  }
}

/// A card-shaped placeholder matching a client list row: an `AppCard`-style
/// container (real surface + border, NOT shimmered) with a circular avatar and
/// two text lines that shimmer inside it.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: SkeletonLoader(
        child: Row(
          children: const [
            SkeletonBox(width: 44, height: 44, borderRadius: AppRadius.pill),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 150, height: 15),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(width: 100, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Launch placeholder shown while the app resolves the user's role. It renders
/// the real Clients-shell chrome instantly — the large title, the "New client"
/// action, and the real bottom nav bar — and skeletons **only** the client cards,
/// so the transition into the loaded shell is seamless.
class ShellSkeleton extends StatefulWidget {
  const ShellSkeleton({super.key, this.cardCount = 6});

  final int cardCount;

  @override
  State<ShellSkeleton> createState() => _ShellSkeletonState();
}

class _ShellSkeletonState extends State<ShellSkeleton> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // The real staff tabs (static chrome), so the bar matches exactly. Screens
    // are unused here (the bar is non-interactive during load).
    final tabs = <ShellTab>[
      ShellTab(
          label: l.navClients,
          sfSymbol: 'person.2',
          materialIcon: Icons.people_outline,
          screen: const SizedBox.shrink()),
      ShellTab(
          label: l.navLibrary,
          sfSymbol: 'square.stack',
          materialIcon: Icons.layers_outlined,
          screen: const SizedBox.shrink()),
      ShellTab(
          label: l.navGroups,
          sfSymbol: 'person.3',
          materialIcon: Icons.groups_outlined,
          screen: const SizedBox.shrink()),
      ShellTab(
          label: l.navReview,
          sfSymbol: 'checkmark.circle',
          materialIcon: Icons.check_circle_outline,
          screen: const SizedBox.shrink()),
      ShellTab(
          label: l.navSettings,
          sfSymbol: 'gearshape',
          materialIcon: Icons.settings_outlined,
          screen: const SizedBox.shrink()),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      // Real title + real action shown instantly; only the list is skeletoned.
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_clients',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () {},
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l.newClient),
      ),
      body: CustomScrollView(
        controller: _scroll,
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverCollapsingHeader(title: l.clientsTitle, controller: _scroll),
          SliverSkeletonCards(count: widget.cardCount),
        ],
      ),
      bottomNavigationBar: AppBottomBar(tabs: tabs, index: 0, onTap: (_) {}),
    );
  }
}
