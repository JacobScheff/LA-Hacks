---
name: Star Hop!
colors:
  # Backgrounds & Surfaces
  background: "#08041A"
  on-background: "#FFFFFF"
  surface: "#08041A"
  surface-dim: "#060211"
  surface-bright: "#1A0B40"
  surface-container-lowest: "#0E0C1C"
  surface-container-low: "#140A32"
  surface-container: "#1A0B40"
  surface-container-high: "#281050"
  surface-container-highest: "#321460"
  on-surface: "#FFFFFF"
  on-surface-variant: "#C8D2E6"
  inverse-surface: "#DAE2FD"
  inverse-on-surface: "#1A0B40"
  outline: "#FFFFFF"
  outline-variant: "#C8D2E6"
  surface-tint: "#FFE066"

  # Primary — Mastered / Golden Yellow
  primary: "#FFE066"
  on-primary: "#0E1228"
  primary-container: "#FFB300"
  on-primary-container: "#0E1228"
  inverse-primary: "#1A0B40"
  primary-fixed: "#FFFCEB"
  primary-fixed-dim: "#FFE066"
  on-primary-fixed: "#0E1228"
  on-primary-fixed-variant: "#3D2A00"

  # Secondary — Learning / Hot Pink
  secondary: "#FF8AD8"
  on-secondary: "#1A0B40"
  secondary-container: "#FF4FB6"
  on-secondary-container: "#1A0B40"
  secondary-fixed: "#FFF1FA"
  secondary-fixed-dim: "#FF8AD8"
  on-secondary-fixed: "#1A0B40"
  on-secondary-fixed-variant: "#6B0048"

  # Tertiary — Gap / Cyan
  tertiary: "#5EE7FF"
  on-tertiary: "#0E1228"
  tertiary-container: "#22B8E0"
  on-tertiary-container: "#0E1228"
  tertiary-fixed: "#E8FAFF"
  tertiary-fixed-dim: "#5EE7FF"
  on-tertiary-fixed: "#0E1228"
  on-tertiary-fixed-variant: "#004D62"

  # Error
  error: "#FFB0B0"
  on-error: "#4A0000"
  error-container: "#7A1010"
  on-error-container: "#FFD0D0"

  # Status Palettes (full tricolor per learning state)
  mastered-core: "#FFFCEB"
  mastered-mid: "#FFE066"
  mastered-halo: "#FFB300"
  mastered-glow: "#FFE066"

  learning-core: "#FFF1FA"
  learning-mid: "#FF8AD8"
  learning-halo: "#FF4FB6"
  learning-glow: "#FF8AD8"

  gap-core: "#E8FAFF"
  gap-mid: "#5EE7FF"
  gap-halo: "#22B8E0"
  gap-glow: "#5EE7FF"

  locked-core: "#C7CDD9"
  locked-mid: "#7B8294"
  locked-halo: "#4A5168"
  locked-glow: "#788296"

  # Accents
  accent-purple: "#A855F7"
  accent-violet: "#A78BFA"
  accent-orange: "#FF8A4C"
  accent-green: "#50E6A0"

typography:
  display:
    fontFamily: SF Pro Rounded
    fontSize: 28px
    fontWeight: "700"
    lineHeight: 34px
    letterSpacing: -0.3px
  headline-lg:
    fontFamily: SF Pro Rounded
    fontSize: 22px
    fontWeight: "700"
    lineHeight: 28px
    letterSpacing: -0.3px
  headline-md:
    fontFamily: SF Pro Rounded
    fontSize: 20px
    fontWeight: "600"
    lineHeight: 26px
  title-lg:
    fontFamily: SF Pro Rounded
    fontSize: 18px
    fontWeight: "600"
    lineHeight: 24px
  title-md:
    fontFamily: SF Pro Rounded
    fontSize: 16px
    fontWeight: "600"
    lineHeight: 22px
  body-lg:
    fontFamily: SF Pro Rounded
    fontSize: 15px
    fontWeight: "500"
    lineHeight: 22px
    letterSpacing: 0.2px
  body-md:
    fontFamily: SF Pro Rounded
    fontSize: 13px
    fontWeight: "500"
    lineHeight: 20px
  label-lg:
    fontFamily: SF Pro Rounded
    fontSize: 13px
    fontWeight: "600"
    lineHeight: 18px
    letterSpacing: 0.4px
  label-md:
    fontFamily: SF Pro Rounded
    fontSize: 12px
    fontWeight: "600"
    lineHeight: 16px
    letterSpacing: 0.5px
  label-sm:
    fontFamily: SF Pro Rounded
    fontSize: 11px
    fontWeight: "600"
    lineHeight: 14px
    letterSpacing: 0.5px
  kicker:
    fontFamily: SF Pro Rounded
    fontSize: 10px
    fontWeight: "600"
    lineHeight: 12px
    letterSpacing: 1.0px
  star-name:
    fontFamily: SF Mono
    fontSize: 10px
    fontWeight: "600"
    lineHeight: 12px
    letterSpacing: 0.6px

rounded:
  xs: 0.25rem
  sm: 0.75rem
  DEFAULT: 0.875rem
  md: 1rem
  lg: 1.25rem
  xl: 1.75rem
  full: 9999px

spacing:
  base: 8px
  xs: 4px
  sm: 8px
  md: 14px
  lg: 18px
  xl: 22px
  xxl: 30px
  screen-h-pad: 16px
  screen-v-top: 56px
  bottom-nav-height: 110px
  safe-bottom: 28px
  card-gap: 8px
  grid-gap: 8px

components:
  glass-card:
    backgroundColor: "rgba(255, 255, 255, 0.06)"
    rounded: "{rounded.md}"
    padding: "{spacing.md}"
    borderColor: "rgba(255, 255, 255, 0.12)"
    borderWidth: 1.5px

  glass-card-elevated:
    backgroundColor: "rgba(255, 255, 255, 0.10)"
    rounded: "{rounded.lg}"
    padding: "{spacing.lg}"
    borderColor: "rgba(255, 255, 255, 0.18)"
    borderWidth: 1.5px

  button-primary:
    backgroundColor: "{colors.mastered-mid}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.DEFAULT}"
    padding: 13px 28px
    height: 48px

  button-primary-hover:
    backgroundColor: "{colors.mastered-halo}"

  button-secondary:
    backgroundColor: "rgba(255, 255, 255, 0.06)"
    textColor: "{colors.on-surface}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.DEFAULT}"
    borderColor: "rgba(255, 255, 255, 0.20)"
    borderWidth: 1.5px
    padding: 13px 22px

  button-icon:
    backgroundColor: "rgba(255, 255, 255, 0.10)"
    rounded: "{rounded.full}"
    size: 38px
    borderColor: "rgba(255, 255, 255, 0.25)"
    borderWidth: 1.5px

  input-field:
    backgroundColor: "rgba(0, 0, 0, 0.30)"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-lg}"
    rounded: "{rounded.DEFAULT}"
    padding: "{spacing.md}"
    borderColor: "rgba(255, 224, 102, 0.35)"
    borderWidth: 2px
    placeholderColor: "rgba(255, 255, 255, 0.40)"

  filter-chip:
    backgroundColor: "rgba(255, 255, 255, 0.10)"
    textColor: "{colors.on-surface}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 7px 14px
    borderColor: "rgba(255, 255, 255, 0.18)"
    borderWidth: 1.5px

  filter-chip-active:
    backgroundColor: "rgba(255, 224, 102, 0.18)"
    textColor: "{colors.mastered-mid}"
    borderColor: "{colors.mastered-mid}"
    borderWidth: 2px

  status-badge:
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: 4px 10px
    borderWidth: 1.5px

  bottom-nav:
    backgroundColor: "rgba(20, 10, 50, 0.85)"
    height: "{spacing.bottom-nav-height}"
    tabIconSize: 24px
    tabLabelTypography: "{typography.kicker}"
    activeColor: "{colors.mastered-mid}"
    inactiveColor: "rgba(255, 255, 255, 0.45)"

  progress-bar:
    height: 8px
    backgroundColor: "rgba(255, 255, 255, 0.10)"
    fillColor: "{colors.mastered-mid}"
    rounded: "{rounded.full}"

  mastery-ring:
    size: 78px
    trackColor: "rgba(255, 255, 255, 0.10)"
    trackWidth: 4px
    progressWidth: 4px
    emojiSize: 28px

  sheet-modal:
    backgroundColor: "#1A0B40"
    rounded: "{rounded.xl}"
    handleColor: "rgba(255, 255, 255, 0.30)"
    handleWidth: 44px
    handleHeight: 5px

  heatmap-cell:
    size: 9px
    rounded: "{rounded.xs}"
    intensity-0: "rgba(255, 255, 255, 0.06)"
    intensity-1: "rgba(255, 224, 102, 0.32)"
    intensity-2: "rgba(255, 138, 216, 0.55)"
    intensity-3: "rgba(255, 224, 102, 0.95)"

  nova-bubble:
    backgroundColor: "#FFFFFF"
    textColor: "#2A1A0A"
    typography: "{typography.body-md}"
    rounded: 18px
    borderWidth: 2px
    padding: "{spacing.md}"
---

## Brand & Style

Star Hop! is a space-themed educational platform for young learners. The visual identity transforms a child's curriculum into a living star atlas: every skill is a glowing star, every subject a constellation, and progress means lighting up the sky. The AI tutor Nova — rendered as a friendly fox emoji — guides learners through quests in a universe that feels genuinely magical.

The aesthetic is **dark-cosmos glassmorphism** tuned for elementary-aged users. Deep-space purples and near-blacks set the canvas; neon status colors (gold, pink, cyan) glow against the darkness to make learning progress viscerally satisfying. Glass-morphism frosting lifts cards and sheets off the void. Every element is oversized, emoji-forward, and animated — the interface should feel like a toy that also teaches.

The app enforces dark mode only. Light-mode is never shown; the entire experience lives in space.

## Colors

The palette has a strict hierarchy built around **learning state**, not brand role. There is no single brand color — instead, four status palettes each carry a complete tricolor (core → mid → halo) plus a glow value used for box-shadow and particle effects:

| State | Core | Mid | Halo | Meaning |
|---|---|---|---|---|
| **Mastered** | `#FFFCEB` | `#FFE066` | `#FFB300` | Shining — topic fully learned |
| **Learning** | `#FFF1FA` | `#FF8AD8` | `#FF4FB6` | Glowing — actively in progress |
| **Gap** | `#E8FAFF` | `#5EE7FF` | `#22B8E0` | Sleepy — detected knowledge gap |
| **Locked** | `#C7CDD9` | `#7B8294` | `#4A5168` | Locked — not yet reached |

Golden yellow (`#FFE066`) doubles as the primary UI accent — it colors the active tab, XP progress bar fills, primary CTA buttons, and the highlight border on text inputs. This cements the association between "mastered" and "chosen," making the UI itself feel like a reward.

The **deep-space background** is `#08041A` (near-black with a purple-indigo undertone). Surface containers step upward through `#0E0C1C` → `#140A32` → `#1A0B40` → `#281050`, creating visible depth layers without ever going light. Each of the nine constellations also has a radial nebula gradient positioned at its centroid — a blurred, low-opacity wash of its thematic color (e.g., teal for Numbers, purple for Shapes, rose for Reading) that gives each subject its own corner of the sky.

White is used exclusively for text and borders, never as a fill — it appears at opacities between `0.06` (ghost fills) and `1.0` (primary labels).

## Typography

All type uses **SF Pro Rounded** — Apple's system font design with rounded terminals. The rounded variant is essential: it reads as warm and friendly to children rather than austere or corporate. Monospaced type (`SF Mono`) is reserved solely for star-node labels on the galaxy map, where it reads as coordinates or scientific data, reinforcing the star-atlas metaphor.

**Sizes run from 10px (kicker ALL-CAPS labels) to 28px (hero display).** Because rounded terminals increase apparent weight, sizes are set conservatively — a 13px label here reads with the same authority as a 14–15px label in a neutral-cut face.

Letter spacing is used deliberately:
- **Kickers and ALL-CAPS tags** get loose tracking (`0.5–1.0pt`) to aid legibility at small sizes.
- **Headlines** use slightly negative tracking (`-0.3pt`) to keep display text cohesive.
- **Star names** use `0.6pt` tracking in monospaced to suggest instrument-panel readouts.

Line spacing in lesson-body text is generous (`lineSpacing: 2–3pt`) to accommodate emerging readers.

## Layout & Spacing

The layout is **vertical-first and safe-area-aware**. All screens are full-height scroll containers. The top 56px is reserved for the persistent header (XP bar, streak, avatar). The bottom 110px accommodates the floating bottom navigation bar, which overlaps content. Every scrollable list must add `110px` of bottom padding so its last item remains visible above the nav.

Horizontal screen padding is `14–16px`. Cards within lists are separated by `8px` gaps. Section-level vertical spacing steps up to `18–22px`.

**An implicit 8px base grid** governs all spacing decisions. Deviations are rare and intentional (e.g., the 5px drag handle on sheets, the 4px heatmap cell corner radius).

## Elevation & Depth

Depth is achieved through three overlapping techniques — never through lightening a surface color:

1. **Tonal layering** — surfaces step from `#08041A` (floor) up through five stops of dark purple, communicating elevation purely through hue and saturation.
2. **Glass morphism** — cards and sheets use `Color.white.opacity(0.06)` fills and `ultraThinMaterial` backdrop blur, simulating frosted glass floating above the star field.
3. **Colored glow shadows** — the most distinctive effect. Interactive elements cast a soft, wide shadow in their status color (`radius: 14–30px`, `opacity: 0.4–0.9`). A mastered star glows amber-gold; a learning star radiates hot pink. The glow both separates elements from the background and communicates state wordlessly.

Borders appear on every card and modal: `Color.white.opacity(0.12)` at 1.5pt for standard glass cards, stepping up to `0.18–0.25` for elevated or focused elements. A colored border (status mid-color, `opacity: 0.55`) marks the currently active sheet.

## Shapes

The shape language is **smooth and continuous**. SwiftUI's `.continuous` curve interpolation is used everywhere — it produces a squircle-like corner that feels more organic than a simple circular arc.

- **Pill / full-round** (`Capsule()`): filter chips, status badges, progress bars, tab active indicators.
- **Large round** (28px, `rounded.xl`): bottom sheet top corners. This large radius creates an unmistakable "drawer" gesture affordance.
- **Standard card** (14–16px, `rounded.DEFAULT` / `rounded.md`): glass cards, buttons, input fields.
- **Micro** (4px, `rounded.xs`): heatmap calendar cells, the only place sharp edges appear — they read as grid data, not interactive UI.

Buttons are never pill-shaped unless they are one-word labels. Multi-word CTAs use `rounded.DEFAULT` (14px) to feel "chunky" and tap-friendly.

## Components

### Stars & Constellation Map

The star node is the core design primitive. Each star is a custom SwiftUI `Path`-drawn 5-point shape with three visual layers: an outer glow ring (status glow color, high opacity), a filled body (status mid), and a stroke halo (status halo). Mastered stars receive a subtle oscillating rotation and a small emoji face (eyes + smile) drawn at center — the only place a face appears inside a geometric shape.

Constellation edges are drawn as quadratic Bézier curves connecting stars; cross-constellation "bridge" edges render dashed when the learner hasn't unlocked both endpoints.

### Glass Cards

All surface containers follow the same recipe: `rgba(255, 255, 255, 0.06)` fill, `1.5pt` white outline at `0.12` opacity, `rounded.md` continuous corners. Elevated cards (modals, detail sheets) step up to `0.10` fill and `0.18` outline opacity.

### Buttons

Primary CTAs use a linear gradient from the status palette's mid to halo color as the fill, with the dark label base (`#0E1228`) as text. A glowing shadow in the same palette color at `0.4–0.6` opacity makes the button feel luminous. Secondary buttons are near-transparent with a dashed or solid white outline.

### Nova Bubbles

The AI tutor's speech bubbles invert the color scheme completely: white fill, dark text (`#2A1A0A`), and a 2pt colored border in the current status halo color. This reversal makes Nova's messages immediately distinct from all other UI elements and gives her a "paper in space" character — warm, solid, and human amid the glowing digital environment.

### Bottom Navigation

Five tabs (Galaxy, Quests, Trips, Nova, Profile) sit in a frosted bar at screen bottom. The active tab renders its icon in `#FFE066` and shifts 3px upward with a spring animation. Inactive tabs are white at `0.45` opacity. Labels use the `kicker` type style (10px, semibold, `1.0pt` tracking).

### Progress & Mastery

XP bars use an `#FFE066 → #FFB300` gradient fill over a `rgba(255,255,255,0.10)` track, capsule-clipped, with a subtle glow shadow. Mastery rings are 78px circles with a 4pt progress arc drawn in the status mid-color over a faint white track; the center holds a subject emoji at 28px.

### Heatmap

The activity heatmap (streak calendar) uses a 4-level intensity scale across 9×9px cells. At intensity 0 the cell is nearly invisible; at intensity 3 it blazes gold with a strong ambient glow — a direct miniature of the star glow metaphor applied to calendar data.

## Motion

Animation is integral to the design — the app should feel alive, not static.

- **Spring transitions** (`response: 0.3–0.45s`, `dampingFraction: 0.78–0.85`): all sheet presentations, tab switches, and filter selections.
- **Ease-out** (`0.25–0.3s`): content reveals and state color changes.
- **Continuous sine oscillation**: background star twinkling, mastered-star rotation, pulse rings, and streak-chip glow all run on a shared time base, creating a subtle breathing rhythm across the whole screen.
- **Pop animation**: newly discovered stars scale with `0.6 + 0.4 × (sin(t×6) + 1) / 2` over ~0.8s — a quick bounce that reads as celebration.
- **Confetti**: celebration moments drop multi-colored particles with randomized rotation and fall speed.

No animation should block input or exceed 600ms for user-initiated actions. Background animations should pause when the app enters the background.
