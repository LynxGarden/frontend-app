import 'package:flutter/material.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
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

/// A padded column of [count] card-shaped placeholders matching the Programs
/// list's `_ProgramCard`: an `AppCard`-style surface (real surface + border +
/// shadow, NOT shimmered) holding a ListTile-shaped title + subtitle and a
/// trailing chevron placeholder, and **no leading icon**. Mirrors the loaded
/// list's padding so nothing shifts on the swap to real data.
class ProgramSkeletonList extends StatelessWidget {
  const ProgramSkeletonList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Match ReorderableListView.builder's padding on the loaded list.
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < count; i++) const _ProgramSkeletonCard()],
      ),
    );
  }
}

/// A card-shaped placeholder matching `_ProgramCard` (an `AppCard` wrapping a
/// ListTile): title + subtitle bars with a trailing chevron, no leading icon.
class _ProgramSkeletonCard extends StatelessWidget {
  const _ProgramSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      // The loaded card has AppCard's 8px bottom margin plus an 8px wrapper
      // Padding (16px total between cards) — mirror that with one md margin.
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      // ListTile's default content padding (16h) + a comfortable vertical inset.
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
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

/// Loading placeholder for the **program editor**: two input-field placeholders
/// (name + description), a "Sessions" label, then a few session-card skeletons —
/// mirroring the real screen's layout so the swap to data is calm. Pass the
/// floating nav bar's [topInset] so nothing starts hidden behind it.
class ProgramEditorSkeleton extends StatelessWidget {
  const ProgramEditorSkeleton(
      {super.key, required this.topInset, this.cardCount = 3});

  final double topInset;
  final int cardCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, topInset + AppSpacing.md, AppSpacing.lg, 0),
            child: const SkeletonLoader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldSkeleton(fieldHeight: 52),
                  SizedBox(height: AppSpacing.sm),
                  _FieldSkeleton(fieldHeight: 72),
                  SizedBox(height: AppSpacing.md),
                  SkeletonBox(width: 80, height: 12),
                  SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                for (var i = 0; i < cardCount; i++) const _ProgramSkeletonCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single form-field placeholder: a short label bar + a full-width field box.
class _FieldSkeleton extends StatelessWidget {
  const _FieldSkeleton({required this.fieldHeight});

  final double fieldHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(width: 90, height: 10),
        const SizedBox(height: 8),
        SkeletonBox(height: fieldHeight, borderRadius: AppRadius.md),
      ],
    );
  }
}

/// Loading placeholder for the **session editor**: a column of exercise-card
/// skeletons matching `_ExerciseCard` (a rounded bordered surface — no shadow —
/// with a title + prescription line and two trailing action-icon placeholders).
class SessionEditorSkeleton extends StatelessWidget {
  const SessionEditorSkeleton(
      {super.key, required this.topInset, this.cardCount = 5});

  final double topInset;
  final int cardCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, topInset + AppSpacing.sm, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cardCount; i++) const _ExerciseSkeletonCard(),
        ],
      ),
    );
  }
}

/// An exercise-card placeholder matching `_ExerciseCard`: rounded bordered
/// surface (NOT shimmered), a title + summary line, and two trailing icons.
class _ExerciseSkeletonCard extends StatelessWidget {
  const _ExerciseSkeletonCard();

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 15),
                  SizedBox(height: 6),
                  SkeletonBox(width: 90, height: 12),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            SkeletonBox(width: 20, height: 20, borderRadius: AppRadius.sm),
            SizedBox(width: AppSpacing.md),
            SkeletonBox(width: 20, height: 20, borderRadius: AppRadius.sm),
          ],
        ),
      ),
    );
  }
}

/// Loading placeholder for the **session actuals** review screen: a column of
/// card skeletons matching the actuals card (a shadowed rounded surface with an
/// exercise-name line and a shorter logged-summary line, no trailing icon).
class SessionActualsSkeleton extends StatelessWidget {
  const SessionActualsSkeleton(
      {super.key, required this.topInset, this.cardCount = 5});

  final double topInset;
  final int cardCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, topInset + AppSpacing.md, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cardCount; i++) const _ActualsSkeletonCard(),
        ],
      ),
    );
  }
}

/// A card placeholder matching the actuals card: shadowed rounded surface (NOT
/// shimmered) with a title bar + a shorter summary bar.
class _ActualsSkeletonCard extends StatelessWidget {
  const _ActualsSkeletonCard();

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 140, height: 15),
            SizedBox(height: 8),
            SkeletonBox(width: 100, height: 12),
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
      // Match the loaded list's card spacing: there each card carries AppCard's
      // own 8px bottom margin AND an 8px wrapper Padding (16px total between
      // cards), so mirror that with a single AppSpacing.md bottom margin here.
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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

/// Launch placeholder shown while the app resolves the user's role. It is
/// deliberately **role-neutral** — no "New client" action, no staff tab labels,
/// no "Clients" title — because at this point we don't yet know whether the user
/// is staff or a client, and the wrong-role chrome must never flash (a client
/// glimpsing the staff shell). Just a title bar, skeleton cards, and a neutral
/// bottom bar placeholder; the real shell replaces it once the role loads.
class ShellSkeleton extends StatelessWidget {
  const ShellSkeleton({super.key, this.cardCount = 6});

  final int cardCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
                    AppSpacing.lg, AppSpacing.sm),
                child: SkeletonLoader(
                  child: SkeletonBox(
                      width: 150, height: 26, borderRadius: AppRadius.sm),
                ),
              ),
            ),
          ),
          SliverSkeletonCards(count: cardCount),
        ],
      ),
      bottomNavigationBar: const _NeutralBarSkeleton(),
    );
  }
}

/// A role-agnostic placeholder for the floating bottom nav bar — a pill with a
/// few generic tab shapes, revealing nothing about the (still-loading) role.
class _NeutralBarSkeleton extends StatelessWidget {
  const _NeutralBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.surfaceBorder),
            boxShadow: AppShadows.floating,
          ),
          child: SkeletonLoader(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 4; i++)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SkeletonBox(width: 24, height: 24, borderRadius: 8),
                      SizedBox(height: 6),
                      SkeletonBox(width: 26, height: 8),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
