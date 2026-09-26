/// DiceBear `notionists` (hand-drawn, CC0) option catalogue — the values the
/// avatar builder cycles through. Variants are sequential zero-padded
/// `variantNN`; counts come from the published notionists schema (v9.4.2).
/// `gesture` (hand poses/props) is intentionally omitted — headshots only.
library;

/// A customizable feature category in the notionists builder.
class AvatarCategory {
  const AvatarCategory(
    this.key,
    this.labelKey,
    this.count, {
    this.optional = false,
  });

  /// DiceBear option key (e.g. `hair`, `brows`).
  final String key;

  /// l10n key for the section label (e.g. `avHair`).
  final String labelKey;

  /// Number of `variantNN` values (1-based).
  final int count;

  /// If true, the feature can be turned off ("none") via `<key>Probability=0`.
  final bool optional;

  /// All variant ids for this category, e.g. `['variant01', … 'variant63']`.
  List<String> get variants =>
      [for (var i = 1; i <= count; i++) variantId(i)];
}

/// `variant07`-style id from a 1-based index.
String variantId(int i) => 'variant${i.toString().padLeft(2, '0')}';

/// Builder sections, in display order. `body` = clothing.
const notionistsCategories = <AvatarCategory>[
  AvatarCategory('hair', 'avHair', 63),
  AvatarCategory('eyes', 'avEyes', 5),
  AvatarCategory('brows', 'avEyebrows', 13),
  AvatarCategory('lips', 'avMouth', 30),
  AvatarCategory('nose', 'avNose', 20),
  AvatarCategory('glasses', 'avGlasses', 11, optional: true),
  AvatarCategory('beard', 'avBeard', 12, optional: true),
  AvatarCategory('body', 'avClothing', 25),
];
