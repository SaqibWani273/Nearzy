---
name: nearzy-design
description: The Nearzy design system — palette, type, spacing, elevation, motion language, and component recipes for the Flutter app. Use whenever building, restyling, or reviewing any screen or widget in frontend/lib/presentation, adding animations, or touching frontend/lib/theme. Enforces the "Local Premium" visual language so screens stay one coherent product rather than a pile of Material defaults.
---

# Nearzy Design System — "Local Premium"

Nearzy is a hyperlocal marketplace: real shops, a few streets away. The UI must feel
like a **premium boutique catalogue**, not a discount bazaar. Calm, spacious, tactile.
Colour is used sparingly and therefore lands hard.

## 0. The three rules that matter most

1. **Ink and paper, one accent.** Almost everything is near-black type on warm paper.
   Lime appears only where the user should act or look. If a screen has more than
   ~3 lime elements visible at once, it is wrong.
2. **Nothing appears instantly.** Every list, card, sheet and screen transition
   has an entrance. See §5 — always use the `Motion` helpers, never raw
   `AnimationController` boilerplate in screen code.
3. **Radius is large and consistent.** 20–28px on cards and sheets, pill (999) on
   chips and buttons. Small radii read as "Android default app".

## 1. Palette

Defined in `lib/theme/app_colors.dart`. Never hardcode a hex in screen code.

| Token | Hex | Use |
|---|---|---|
| `ink` | `#0F1A15` | Primary surface for dark blocks, primary buttons, headings |
| `inkSoft` | `#1B2A23` | Raised dark surface, dark card |
| `inkMuted` | `#3A4A42` | Dark-surface secondary text |
| `lime` | `#C9F24E` | THE accent. CTAs, active nav, selection, price highlight |
| `limeDeep` | `#A8D62F` | Pressed/hover state of lime, lime gradients |
| `limeSurface` | `#EEF9D2` | Tinted lime background for chips/badges |
| `sage` | `#8FA396` | Decorative strokes, map polygons, dividers on dark |
| `sageSurface` | `#E4EBE4` | Secondary tinted surface |
| `paper` | `#F7F6F1` | App scaffold background (warm off-white) |
| `card` | `#FFFFFF` | Card / sheet surface |
| `line` | `#E6E4DC` | Hairline borders on paper |
| `textPrimary` | `#0F1A15` | Body + headings on paper |
| `textSecondary` | `#5D6B63` | Supporting copy |
| `textTertiary` | `#94A19A` | Meta, timestamps, placeholders |
| `success` / `warning` / `error` | `#2E9E6B` / `#E0A03C` / `#D5533D` | Semantic only |

**Contrast law:** text on `lime` is always `ink`, never white. Text on `ink` is
always `paper` or `lime`, never pure `#FFF`. There are tokens for exactly this —
`textOnInk` and `textOnLime` — prefer them at those call sites.

Also present and fair game: `sageDeep` `#4C6357`, `paperDim` `#EFEDE5` (input
fills, dimmed backgrounds), `info` `#3C7D8C`, a `*Surface` tint beside each
semantic colour, and `shimmerBase`/`shimmerHighlight`. The `primary`/`accent`/
`surface` names at the bottom of `AppColors` are aliases onto the tokens above,
kept for Material's `ThemeData` — write screen code against the real names.

**Gradients** — only two exist, both in `AppColors`: `inkGradient` (for hero blocks)
and `limeGradient` (for the single primary CTA on a screen). Do not invent more.

## 2. Typography

`lib/theme/app_text_styles.dart`. Two families only:

- **Display / headings — `GoogleFonts.plusJakartaSans`**, weight 700/800, tight
  tracking (`letterSpacing: -0.5` at 24px+, `-0.8` at 32px+). Headings are big and
  confident: a screen title is 28–34px, not 20px.
- **Body / UI — `GoogleFonts.inter`**, weights 400/500/600.

The scale, by its real token name: `display 34 / heading1 28 / heading2 22 /
heading3 18 / heading4 16 / bodyLarge 16 / bodyMedium 14 / bodySmall 13 /
caption 12 / micro 10`, plus `labelLarge|Medium|Small`, `buttonText`,
`navLabel`, `badge`, `overline`, `sectionTitle`/`sectionSubtitle` and the
`input*` set. Prices use `priceLarge|Medium|Small` and `priceStrikethrough` —
tabular figures, weight 700. `brand` (26/w800) is the wordmark only.

Never centre body copy. Screen titles are left-aligned, hugging a 20px gutter.

## 3. Layout & spacing

- Screen gutter: **20px** (`AppSpacing.gutter`). Cards inside grids: 14px gaps.
- Vertical rhythm between sections: **28px**. Between a section header and its
  content: **12px**.
- Grids are 2-column with `mainAxisExtent` (never `childAspectRatio` — it breaks
  when text wraps).
- Content that scrolls under a bottom nav needs `AppSpacing.bottomNavInset` of
  trailing padding.
- Prefer `CustomScrollView` + slivers over nested scroll views.

## 4. Component recipes

Reusable widgets live in `lib/presentation/common/widgets/`. **Check there first —
do not build a second version of an existing component.**

- **Card surface** — there is no wrapper widget; cards are a `Container` with
  `color: AppColors.card`, `borderRadius: AppSpacing.borderRadiusXl` (28) or
  `borderRadiusLg` (20), `boxShadow: AppSpacing.shadowSoft`, and no border.
  Elevation comes from that shadow, never from Material `elevation:`. Add
  `clipBehavior: Clip.antiAlias` whenever an image reaches an edge.
- **Product card** (`NearzyProductCard`) — image fills the top with radius 20, a
  floating heart button top-right, name (2 lines max), shop name + distance in
  caption, price row with strikethrough original. Tap = scale-down 0.97.
- **Shop card** (`NearzyShopCard`) — cover image, avatar overlapping the cover's
  bottom edge, name + verified tick, open/closed pill, distance chip, category chips.
- **Pill chips** — height 36, radius full, unselected = `card` + `line` border,
  selected = `ink` fill with `paper` text. Selection animates via `AnimatedContainer`.
- **Primary CTA** — full width, height 56, radius full, `ink` fill with `lime` text,
  OR `lime` fill with `ink` text for the single highest-intent action on screen.
- **Bottom sheets** — radius 28 top corners, 4×44 drag handle in `line`, 20px gutter,
  and always `isScrollControlled: true`.
- **Empty states** — an outlined 88px circle holding an icon, an h3 title, one line
  of caption, and (where useful) one text button. Never a bare "No data".
- **Skeletons** — `ShimmerLoading.*` mirroring the real layout's silhouette.
  A skeleton whose shape differs from the loaded content is a bug.

## 5. Motion language

All timing/curve tokens live in `lib/theme/app_motion.dart` as `Motion`. Use the
helpers in `lib/presentation/common/animations/` rather than hand-rolling.

**Durations:** `micro 120ms` (taps, toggles) · `quick 220ms` (chips, badges) ·
`base 340ms` (entrances, sheets) · `slow 520ms` (hero, page) · `ambient 2600ms`
(looping decorative motion). Stagger step is `stagger 45ms`, capped at
`maxStaggerIndex 10` — use `Motion.staggerDelay(index)`.

**Curves:** `Motion.easeOut` = `Curves.easeOutCubic` (default for anything
entering) · `Motion.spring` = `Curves.easeOutBack` (things that should feel
snappy/physical: badges, FABs, selection) · `Motion.emphasis` =
`Curves.easeOutQuint` (page + sheet transitions) · `Motion.gentle` =
`Curves.easeInOutSine` (looping ambient motion) · `Motion.exit` =
`Curves.easeInCubic` (anything leaving).

**Patterns — use these, they are the app's signature:**

- **Staggered reveal.** Lists and grids fade + slide up 16px, 45ms apart, capped at
  ~10 items of stagger. Use `.animateEntrance(index: i)` extension.
- **Press response.** Every tappable card/button scales to 0.97 over `micro` on
  press-down. Use `PressableScale`. Pair meaningful actions with
  `HapticFeedback.lightImpact()`.
- **Hero images.** Product/shop images use `Hero` tags `product-<id>` / `shop-<id>`
  so the grid→detail transition is continuous. The detail screen's image must have
  the same radius mid-flight (wrap the Hero child in the same `ClipRRect`).
- **Parallax detail header.** Detail screens use a `SliverAppBar` with an
  expanded image that translates at 0.4× scroll speed and cross-fades its title
  into the collapsed bar.
- **Number transitions.** Prices, counts, quantities animate with
  `AnimatedFlipCounter`-style `TweenAnimationBuilder`, never a hard swap.
- **Skeleton → content.** Always cross-fade, via `CrossFade` from
  `common/animations/cross_fade.dart` — pass the thing that distinguishes one
  phase from the next as `state`. Use it rather than a bare `AnimatedSwitcher`,
  which keys entries by the child's own key and throws "Duplicate keys found"
  when phases change faster than the fade. A hard cut from shimmer to content
  is a bug.
- **Map markers.** Drop in with `spring` + a scale from 0.4, staggered by index.
  The selected marker scales to 1.25 and raises its z-order.
- **Page routes.** Use `NearzyPageRoute` (shared-axis: incoming slides 24px + fades
  over `slow` with `emphasis`). Do not use bare `MaterialPageRoute` for
  in-app navigation.

**Restraint:** at most one *ambient* (looping) animation per screen. Everything
else must be triggered by entrance, scroll, or input. No animation may block
interaction, and none may exceed `slow` for anything the user is waiting on.

## 6. Accessibility & platform

- Minimum tap target 44×44. Icon buttons get `tooltip:`.
- Text must survive `textScaleFactor: 1.3` — never fix a text container's height.
- Every image has a `semanticLabel`; every icon-only button has a `Semantics` label.
- Respect `MediaQuery.disableAnimations` — `Motion.duration(context, Motion.base)`
  returns `Duration.zero` when the user has reduced motion on. Use it in custom
  animation code.
- Status bar style is set per-screen via `SystemUiOverlayStyle` — dark icons on
  paper screens, light icons on `ink` screens.

## 7. Checklist before calling a screen done

- [ ] No hardcoded colours, text styles, radii, or durations — all from tokens.
- [ ] Loading, empty, and error states all exist and are styled.
- [ ] Content enters with a stagger; taps respond with scale + haptics.
- [ ] Images go through `NearzyNetworkImage` — the app's only network image
      widget. It already handles the disk cache, shimmer placeholder and styled
      fallback; a raw `Image.network` or bare `CachedNetworkImage` is a bug.
- [ ] Bottom padding clears the nav bar; nothing is hidden behind it.
- [ ] Works at 320px width and at 1.3× text scale.
- [ ] Reads as the same product as the Explore screen.
