import 'package:flutter/material.dart';

/// Lynx brand palette — forest green on cream. Ported from the Lynx website
/// (assets/css/styles.css :root). The brand reads as a LIGHT theme.
///
/// Raw brand tokens are exposed directly (forest, cream, ink…) and also mapped
/// onto the semantic names the shared widgets/theme expect (primary, surface…).
class AppColors {
  AppColors._();

  // ── Raw brand tokens ─────────────────────────────────────────
  static const cream       = Color(0xFFF5F1E8); // background / light-on-dark
  static const ink         = Color(0xFF14281F); // primary text
  static const forest      = Color(0xFF004225); // primary brand
  static const forestHover = Color(0xFF0A6039); // pressed / hover
  static const dark        = Color(0xFF0B2019); // dark immersive surfaces
  static const line        = Color(0x1A004225); // hairline border (forest 10%)
  static const muted       = Color(0xB814281F); // secondary text (ink ~72%)

  // ── Semantic (map onto the brand) ────────────────────────────
  static const primary       = forest;
  static const primaryLight  = forestHover;
  static const primaryDark   = dark;
  static const primaryDim    = Color(0x22004225); // forest ~13%

  static const background    = cream;
  static const surface       = Color(0xFFFFFFFF); // cards
  static const surfaceLifted = Color(0xFFFBF9F3); // card lifted just off cream
  static const surfaceLight  = Color(0xFFEFEADD); // input fill / muted chip (warm tint)
  static const surfaceBorder = Color(0xFFE4DED0); // warm hairline (not gray/green)

  // Frosted-glass surfaces (bright translucent white on the light brand).
  static const glassFill     = Color(0x99FFFFFF); // white ~60% for BackdropFilter
  static const glassBorder   = Color(0x1F004225); // forest ~12% edge on glass

  static const textPrimary   = ink;
  static const textSecondary = muted;
  static const textTertiary  = Color(0x8014281F); // ink ~50%

  // ── Semantic status ──────────────────────────────────────────
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFB26A00);
  static const error   = Color(0xFFB3261E);
  static const info    = forest;

  // Text/icon colour to use on top of the primary (forest) surface.
  static const onPrimary = cream;
}
