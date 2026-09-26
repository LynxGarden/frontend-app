import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';

/// Landing screen — a hero image with the brand mark stacked on top, and the two
/// entry points (create account / log in) below.
///
/// The hero photo is `assets/images/welcome_hero.jpg` (a placeholder to be
/// replaced with the final brand image). If it's missing it falls back to a
/// forest gradient so the screen never looks broken.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      // One continuous full-screen Stack: photo + effects as the background, with
      // the brand and the actions overlaid on top. Because there's no second
      // widget beneath the photo, there is no seam anywhere — the buttons simply
      // sit on the part of the photo that has faded to cream.
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Sharp photo, anchored to the top ~78% of the screen so `cover` crops
          // it less (less zoom); its bottom edge is hidden under the cream fade.
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                heightFactor: 0.78,
                widthFactor: 1,
                child: Image.asset(
                  'assets/images/welcome_hero.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, _, _) => const _HeroFallback(),
                ),
              ),
            ),
          ),
          // Feathered circular blur: a blurred COPY of the photo, radially masked
          // so it's fully blurred behind the mark and fades to zero at the edges
          // (ImageFiltered can be masked; BackdropFilter cannot).
          Positioned.fill(
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                heightFactor: 0.78,
                widthFactor: 1,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const RadialGradient(
                    center: Alignment(0, -0.05),
                    radius: 0.6,
                    colors: [Colors.white, Colors.transparent],
                    stops: [0.4, 0.9],
                  ).createShader(rect),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Image.asset(
                      'assets/images/welcome_hero.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, _, _) => const _HeroFallback(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Soft radial darkening behind the mark (feathered).
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 0.45,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.85],
                ),
              ),
            ),
          ),
          // Top darkening + bottom fade to cream (the buttons sit on this cream).
          const Positioned.fill(child: _HeroScrim()),
          // Content overlaid on the same stack.
          SafeArea(
            child: Column(
              children: [
                // Brand, centred in the space above the actions.
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/logo.png',
                          width: 96,
                          height: 96,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l.appName,
                          style: AppTextStyles.heading1.copyWith(
                            color: Colors.white,
                            fontSize: 48,
                            letterSpacing: -1.5,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 12),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l.welcomeTagline,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions pinned to the bottom, over the cream.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppButton(
                        label: l.getStarted,
                        isExpanded: true,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.push('/signup');
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: l.login,
                        variant: AppButtonVariant.secondary,
                        isExpanded: true,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.push('/login');
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l.welcomeTerms,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textTertiary,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient scrim over the hero: darker at the top (mark legibility) and fading
/// into the cream background at the bottom so the image melts into the actions.
class _HeroScrim extends StatelessWidget {
  const _HeroScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            // Gentle top darkening for status-bar legibility.
            Colors.black.withValues(alpha: 0.28),
            Colors.black.withValues(alpha: 0.10),
            Colors.transparent,
            // Continuous ease-out into cream — many stops, no flat plateau and no
            // steep final step, reaching solid cream exactly at the bottom so it
            // merges with the actions area with no perceptible line.
            AppColors.background.withValues(alpha: 0.0),
            AppColors.background.withValues(alpha: 0.30),
            AppColors.background.withValues(alpha: 0.65),
            AppColors.background.withValues(alpha: 0.90),
            AppColors.background,
            AppColors.background,
          ],
          stops: const [
            0.0, 0.10, 0.30, 0.50, 0.62, 0.70, 0.75, 0.78, 1.0,
          ],
        ),
      ),
    );
  }
}

/// Shown if the hero image asset is missing or fails to decode.
class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink, AppColors.forest],
        ),
      ),
    );
  }
}
