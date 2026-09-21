import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Lynx typography — Bricolage Grotesque for headings, Geist for body
/// (both from the Lynx website). Loaded via google_fonts.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle heading1 = GoogleFonts.bricolageGrotesque(
    fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5, height: 1.05,
    color: AppColors.textPrimary,
  );

  static TextStyle heading2 = GoogleFonts.bricolageGrotesque(
    fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.1,
    color: AppColors.textPrimary,
  );

  static TextStyle heading3 = GoogleFonts.bricolageGrotesque(
    fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: 0.1, height: 1.45,
    color: AppColors.textSecondary,
  );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );

  static TextStyle button = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2,
  );
}
