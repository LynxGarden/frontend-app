import 'dart:convert';
import 'dart:math';

import 'package:lynx_app/shared/avatars/notionists_options.dart';

/// Builds DiceBear `notionists` avatar URLs from a stored config and helps
/// create/serialize configs. The avatar is rendered server-side (PNG) and
/// cached client-side. Base URL is the only thing to change if we self-host.
class AvatarConfig {
  const AvatarConfig._();

  /// Swap this for a self-hosted DiceBear instance later.
  static const _base = 'https://api.dicebear.com/10.x/notionists/png';

  /// A DiceBear PNG URL for a notionists [config] (transparent background so the
  /// app's role-colored disc shows behind it).
  static String url(Map<String, dynamic> config, {int size = 240}) {
    final params = <String, String>{
      'size': '$size',
      'seed': (config['seed'] as String?) ?? 'lynx',
      'backgroundColor': 'transparent',
      'gestureProbability': '0', // headshots only, no hand poses
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
  static Map<String, dynamic> random([Random? rnd]) {
    final r = rnd ?? Random();
    String pick(AvatarCategory c) => variantId(1 + r.nextInt(c.count));
    final config = <String, dynamic>{'seed': 'lynx-${r.nextInt(1 << 32)}'};
    for (final c in notionistsCategories) {
      if (c.optional) {
        // ~35% chance the optional feature is present.
        config[c.key] = r.nextInt(100) < 35 ? pick(c) : null;
      } else {
        config[c.key] = pick(c);
      }
    }
    return config;
  }
}
