import 'dart:convert';
import 'dart:math';

import 'package:lynx_app/shared/avatars/notionists_options.dart';

/// Builds DiceBear `notionists` avatar URLs from a stored config and helps
/// create/serialize configs. The avatar is rendered server-side (PNG) and
/// cached client-side. Base URL is the only thing to change if we self-host.
class AvatarConfig {
  const AvatarConfig._();

  /// Swap this for a self-hosted DiceBear instance later.
  /// NB: pinned to 9.x — the 10.x notionists endpoint ignores per-feature
  /// options (hair/eyes/…), rendering every config identically.
  static const _base = 'https://api.dicebear.com/9.x/notionists/png';

  /// A DiceBear PNG URL for a notionists [config] (transparent background so the
  /// app's role-colored disc shows behind it).
  ///
  /// [scale] / [translateY] control framing. Defaults are the app-wide
  /// "portrait" crop (head near the top, shoulders filling the disc). The avatar
  /// builder overrides them to zoom the feature thumbnails onto the face (or the
  /// clothing) so each row shows the varying feature, not a tiny whole figure.
  static String url(
    Map<String, dynamic> config, {
    int size = 240,
    int scale = 92,
    int translateY = 8,
  }) {
    // NB: notionists defaults to a transparent background, so we omit
    // `backgroundColor` entirely — passing `transparent` fails v10 validation
    // (it only accepts hex), which 400s the whole request.
    final params = <String, String>{
      'size': '$size',
      'seed': (config['seed'] as String?) ?? 'lynx',
      'gestureProbability': '0', // headshots only, no hand poses
      'scale': '$scale',
      if (translateY != 0) 'translateY': '$translateY',
    };
    for (final key in ['hair', 'eyes', 'brows', 'lips', 'nose', 'body']) {
      final v = config[key] as String?;
      if (v != null) params[key] = v;
    }
    // Optional features toggle via probability.
    for (final key in ['glasses', 'beard']) {
      final v = config[key] as String?;
      if (v != null) {
        params[key] = v;
        params['${key}Probability'] = '100';
      } else {
        params['${key}Probability'] = '0';
      }
    }
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$_base?$qs';
  }

  static String encode(Map<String, dynamic> config) => jsonEncode(config);

  static Map<String, dynamic> decode(String json) {
    try {
      final m = jsonDecode(json);
      return m is Map ? Map<String, dynamic>.from(m) : _fallback();
    } catch (_) {
      return _fallback();
    }
  }

  static Map<String, dynamic> _fallback() => {'seed': 'lynx', 'hair': 'variant01'};

  /// A randomized config across all notionists categories (glasses/beard often
  /// off). Used by "shuffle" and to seed the onboarding builder.
  ///
  /// [gender] ('male' / 'female' / null) biases the result: notionists is a
  /// unisex style with no gender field, so the one reliable lever is the beard —
  /// males may get one (~45%), females never. The choice is stored on the config
  /// (`gender`) so it persists and the builder can honor it.
  static Map<String, dynamic> random([Random? rnd, String? gender]) {
    final r = rnd ?? Random();
    String pick(AvatarCategory c) => variantId(1 + r.nextInt(c.count));
    final config = <String, dynamic>{'seed': 'lynx-${r.nextInt(1 << 32)}'};
    if (gender != null) config['gender'] = gender;
    for (final c in notionistsCategories) {
      if (c.key == 'beard') {
        // Beard = the male signal; ~45% of males, never for females.
        config['beard'] =
            (gender == 'male' && r.nextInt(100) < 45) ? pick(c) : null;
      } else if (c.optional) {
        // ~35% chance the optional feature is present.
        config[c.key] = r.nextInt(100) < 35 ? pick(c) : null;
      } else {
        config[c.key] = pick(c);
      }
    }
    return config;
  }
}
