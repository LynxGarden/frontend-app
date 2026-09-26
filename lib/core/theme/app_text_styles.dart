import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Lynx typography — Bricolage Grotesque for headings, Inter for body.
///
/// These are **getters** (not `static final`) so their colors re-resolve against
/// the current theme (`AppColors.dark`) every time they're read — otherwise the
/// text color would bake in at class-load time and never flip for dark mode.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get heading1 => GoogleFonts.bricolageGrotesque(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.05,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading2 => GoogleFonts.bricolageGrotesque(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.1,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading3 => GoogleFonts.bricolageGrotesque(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
        height: 1.45,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );
}
