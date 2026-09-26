import 'package:flutter/material.dart';

/// Lynx brand palette — forest green on cream (light) with a drafted dark theme
/// that flips the brand: deep forest **background**, cream text, and cream
/// primary actions.
///
/// The app reads `AppColors.*` directly (not `Theme.of`), so dark mode is driven
/// by the [dark] flag: raw brand tokens stay constant, and the **semantic**
/// colors are getters that resolve against [dark]. `MyApp` sets [dark] from the
/// active theme mode before building, so flipping it rebuilds the whole tree.
class AppColors {
  AppColors._();

  /// Set by `MyApp` from the resolved brightness. Toggling it re-resolves every
  /// semantic getter below on the next build.
  static bool dark = false;

  // ── Raw brand tokens (constant) ──────────────────────────────
  static const cream       = Color(0xFFF5F1E8); // background / light-on-dark
  static const ink         = Color(0xFF14281F); // primary text (light)
  static const forest      = Color(0xFF004225); // primary brand
  static const forestHover = Color(0xFF0A6039); // pressed / hover
  static const dark_       = Color(0xFF0B2019); // dark immersive surfaces
  static const line        = Color(0x1A004225); // hairline border (forest 10%)
  static const muted       = Color(0xB814281F); // secondary text (ink ~72%)

  // Dark-theme raw tokens — near-black with a subtle forest tint.
  static const _darkBg            = Color(0xFF04130C); // very dark forest-black bg
  static const _darkSurface       = Color(0xFF0C231A); // cards (elevated off bg)
  static const _darkSurfaceLifted = Color(0xFF102C20);
  static const _darkSurfaceLight  = Color(0xFF0F2519); // input fill / chip
  static const _darkBorder        = Color(0xFF1E3B2D); // hairline
  static const _darkTextSecondary = Color(0xFFB7C7BD);
  static const _darkTextTertiary  = Color(0xFF8A9E92);

  // ── Semantic colors (resolve against [dark]) ─────────────────
  /// Accent / primary action. Forest on light; cream on the dark forest bg.
  static Color get primary => dark ? cream : forest;

  /// Text / icon color on top of a [primary] surface.
  static Color get onPrimary => dark ? forest : cream;

  static Color get primaryLight => dark ? forestHover : forestHover;
  static Color get primaryDark => dark ? _darkSurface : dark_;
  static Color get primaryDim => const Color(0x22004225);

  static Color get background => dark ? _darkBg : cream;
  static Color get surface => dark ? _darkSurface : const Color(0xFFFFFFFF);
  static Color get surfaceLifted =>
      dark ? _darkSurfaceLifted : const Color(0xFFFBF9F3);
  static Color get surfaceLight =>
      dark ? _darkSurfaceLight : const Color(0xFFEFEADD);
  static Color get surfaceBorder =>
      dark ? _darkBorder : const Color(0xFFE4DED0);

  // Frosted-glass surfaces.
  static Color get glassFill =>
      dark ? const Color(0x33FFFFFF) : const Color(0x99FFFFFF);
  static Color get glassBorder => const Color(0x1F004225);

  // Skeleton loaders — the placeholder base and its shimmer highlight, each with
  // enough contrast against [surface] to read as loading content in both themes.
  static Color get skeletonBase =>
      dark ? const Color(0xFF1C3A2B) : const Color(0xFFE7E1D3);
  static Color get skeletonHighlight =>
      dark ? const Color(0xFF2C4E3B) : const Color(0xFFF4F0E7);

  static Color get textPrimary => dark ? cream : ink;
  static Color get textSecondary => dark ? _darkTextSecondary : muted;
  static Color get textTertiary =>
      dark ? _darkTextTertiary : const Color(0x8014281F);

  // ── Semantic status ──────────────────────────────────────────
  static Color get success => dark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32);
  static Color get warning => dark ? const Color(0xFFE0A64D) : const Color(0xFFB26A00);
  static Color get error => dark ? const Color(0xFFE5645B) : const Color(0xFFB3261E);
  static Color get info => primary;
}
