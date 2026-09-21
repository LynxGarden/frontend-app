# 02 · Navigation & UI

## Design goals

- **Responsive & clean.** Phone-first, but layouts must not break on tablet or large phones. Use flexible widths, `LayoutBuilder`/`MediaQuery` breakpoints, and constrained content columns for the coach builder screens (which are denser).
- **Platform-adaptive.** Native-feeling iOS via a Cupertino tab bar; a matching Material pill bar on Android.
- **On brand.** Forest-green-on-cream palette from the Lynx website.

## Branding tokens

Source of truth for the palette is the website: `/Users/matevzmiskec/PersonalProjects/Lynx-website/assets/css/styles.css` (`:root`, lines 5–16). Port these into `lib/core/theme/app_colors.dart` as `static const Color` tokens.

### Colours

| Token | Hex / rgba | Role in app |
|-------|-----------|-------------|
| `cream` | `#F5F1E8` | app background; light text on dark surfaces |
| `ink` | `#14281F` | primary body text |
| `forest` | `#004225` | **primary brand** — buttons, links, active nav, accents |
| `forestHover` | `#0A6039` | pressed / hover state |
| `dark` | `#0B2019` | dark section background (hero, immersive screens) |
| `line` | `rgba(0,66,37,0.10)` | hairline borders (forest @ 10%) |
| `muted` | `rgba(20,40,31,0.72)` | secondary/muted text (ink @ 72%) |
| `surface` | `#FFFFFF` | card surfaces |

The palette is essentially **monochromatic forest-green on cream**. There is no separate accent colour; depth comes from green tints/opacities of `rgba(0,66,37, …)` (0.04–0.20) for surfaces, borders, and hovers. Define semantic aliases (`primary = forest`, `onPrimary = cream`, `background = cream`, `error = <standard red>`) plus the raw tokens.

### Typography

| Role | Family | Weights | Notes |
|------|--------|---------|-------|
| Headings | **Bricolage Grotesque** (fallback Geist) | 400/500/600/700 | `font-weight 600`, `letter-spacing -0.03em`, `line-height ~1.04` |
| Body | **Geist** (fallback system-ui) | 300/400/500/600 | base 16px, `line-height 1.5` |

Load via `google_fonts` (both families are on Google Fonts). Build `AppTextStyles` mapping display/headline/title/body/label roles to these.

### Shape & spacing

- **Radius scale** (`AppRadius`): pills/buttons `999px`; cards `20px`; large cards `22–26px`; small marks `6–10px`. Match the website's generous rounding.
- **Buttons:** primary padding `14px 26px`, fully rounded (`999px`).
- **Shadows:** soft — cards `0 1px 2px rgba(0,66,37,0.05)`; featured `0 20px 50px -30px rgba(0,66,37,0.7)`.
- **Content max-width:** cap dense/coach screens (~`1240px` on web/tablet equivalent) so lines don't run edge-to-edge.

### Theme mode

The brand reads as a **light** theme (cream background). Ship **light as the default/primary theme**. (The starter is dark-only — replace its `AppTheme.dark` with a Lynx `AppTheme.light`; add dark later if wanted, it is not a v1 requirement.)

## Navigation: platform-adaptive tab bar

We replicate the pattern from **kaddy-frontend** (`lib/shared/widgets/main_shell.dart`): a single `MainShell` that renders a **native iOS `CNTabBar`** on iOS and a **custom Material pill bar** on Android, with body content in an `IndexedStack`.

### The pattern (copy & adapt)

```dart
// lib/shared/widgets/main_shell.dart
import 'dart:io' show Platform;
// cupertino_native for native SF Symbols on iOS

class MainShell extends ConsumerStatefulWidget {
  final Widget child;              // from ShellRoute
  const MainShell({required this.child, super.key});
  ...
}

// in build():
if (Platform.isIOS) {
  CNTabBar(
    items: [
      CNTabBarItem(label: 'Train',   icon: CNSymbol('figure.run')),
      CNTabBarItem(label: 'Progress', icon: CNSymbol('chart.line.uptrend.xyaxis')),
      CNTabBarItem(label: 'Profile', icon: CNSymbol('person')),
    ],
    currentIndex: _currentIndex,
    tint: AppColors.forest,
    onTap: _goToPage,
  );
} else {
  // custom Material pill bar with Lucide/Material icons, forest active state
  _BottomNavBar(currentIndex: _currentIndex, onTap: _goToPage);
}
```

Key details carried over from kaddy:

- **`dart:io Platform.isIOS`** is the single branch point (not `defaultTargetPlatform`).
- Icons: SF Symbol name strings on iOS (`CNSymbol('...')`); a mapped Material/Lucide icon on Android — SF Symbols don't render on Android.
- **`extendBody: true`**, `resizeToAvoidBottomInset: false` on the `Scaffold`.
- **Do not** wrap the native `CNTabBar` in a `GestureDetector`/`KeyboardDismisser` — the platform view loses taps to the Flutter gesture arena.
- Optional: lazy first-mount of tabs (`SizedBox.shrink()` until first visited) and a ~250ms deferred mount of heavy first screens so the native transition never stutters.

### Router integration

Use go_router with a shell. Two options — pick per behaviour we want:

- **`StatefulShellRoute.indexedStack`** (recommended for Lynx) — gives each tab its own preserved navigation stack, more idiomatic than kaddy's approach. `MainShell` reads the active branch index from the shell's `navigationShell`.
- kaddy uses a plain `ShellRoute` and re-derives the index from the location; workable but loses per-tab stacks. We prefer the stateful variant unless it fights the native bar.

Deep detail screens (e.g. edit-exercise, session-logging) push **full-screen above the shell** on the root navigator so the tab bar is hidden during focused tasks.

### Two shells, by role

Because coach and client see different apps, we register **two shells** gated by role in the router `redirect`:

**Client shell (tabs):**

| Tab | Icon (iOS SF / Android) | Screen |
|-----|-------------------------|--------|
| Train | `figure.run` / `dumbbell` | program → session menu → daily loop |
| Progress | `chart.line.uptrend.xyaxis` / `trending-up` | "last time" history, per-exercise trends |
| Profile | `person` / `user` | own profile, settings, language |

**Staff shell (coach/physio/admin) (tabs):**

| Tab | Icon | Screen |
|-----|------|--------|
| Clients | `person.2` / `users` | client list + record (profile + safety flags) |
| Library | `square.stack` / `layers` | exercise library + program templates |
| Review | `checkmark.circle` / `check-circle` | completed sessions & logged actuals |
| Profile | `person` / `user` | own profile, settings |

(Exact tab set is a UI decision to validate at CP0/CP4 — this is the starting proposal.)

## Reusable widgets to carry over

From the starter + kaddy `shared/widgets/` — reuse, don't rebuild:

- `app_button.dart` — `AppButton` with variants (primary/secondary/outline/ghost/destructive) & sizes. Restyle to brand (forest primary, pill radius).
- `app_text_field.dart`, `app_toast.dart`, `skeleton_loader.dart`, `keyboard_dismisser.dart`.
- `app_nav_bar.dart` — custom top bar for detail pages (centered title, circular back button, haptic). Use for edit/logging screens.

## Responsiveness checklist

- Content columns constrained on wide screens; forms and builder lists don't stretch full-bleed.
- Tap targets ≥ 44pt; log-entry inputs (weight/reps) use numeric keyboards and large steppers for gym use (sweaty hands, quick taps).
- Video player scales to width, respects safe areas.
- Test on: small phone (iPhone SE), large phone (Pro Max / Pixel), and a tablet.
