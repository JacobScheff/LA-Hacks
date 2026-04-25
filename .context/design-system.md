# Design System

Source of truth: [`DESIGN.md`](../DESIGN.md)

## Theme
Dark-cosmos glassmorphism. Deep purple/black backgrounds with neon status colors. Designed for elementary learners — warm, playful, space-themed.

## Color Palette

### Background
- Deep space: `#0A0014` (near-black purple)
- Nebula overlays: radial gradients of magenta, cyan, violet at 10–20% opacity

### Star Status Colors
| Status | Core | Mid | Halo | Glow |
|--------|------|-----|------|------|
| Mastered | `#FFD700` | `#FFC107` | `#FF8F00` | `#FF6F00` |
| Learning | `#FF6B9D` | `#E91E8C` | `#AD1457` | `#880E4F` |
| Gap | `#00E5FF` | `#00B8D4` | `#0097A7` | `#00838F` |
| Locked | `#9E9E9E` | `#757575` | `#616161` | `#424242` |

### UI Accents
- Gold: `#FFD700` (XP, mastered highlights)
- Cyan: `#00E5FF` (gap stars, avatar ring)
- Pink: `#FF6B9D` (learning stars, streak)

### Glass Cards
- Background: `white.opacity(0.08)` or `white.opacity(0.12)`
- Border: `white.opacity(0.15)` at 1pt
- Corner radius: 20–24pt (`.continuous` style)

## Typography

| Use | Font | Size | Weight |
|-----|------|------|--------|
| Main UI | SF Pro Rounded | 14–18pt | Regular–Semibold |
| Headers | SF Pro Rounded | 22–28pt | Bold |
| Star labels | SF Mono | 10–12pt | Medium |
| XP/numbers | SF Pro Rounded | 13–16pt | Semibold–Bold |

All body text in `.rounded` design variant where possible.

## Layout Grid
- Base unit: 8pt
- Screen padding: 16pt horizontal
- Header height: 56pt
- Bottom nav height: 110pt (includes safe area)
- Card corner radius: 16–24pt

## Star Shape
- 5-point star drawn as a `Path`
- Outer radius / inner radius ratio: ~2.5:1
- Sizes: 16–32pt depending on node importance
- `mastered`: rotates continuously, face overlay (👀😊)
- `learning`: center bright dot
- `gap`: extra pulsing aura

## Shadows / Glow
- Implemented as `.shadow(color: palette.glow, radius: r)` in SwiftUI
- Stars: 4–12pt glow radius by status
- Buttons: 8–16pt colored shadow
- Cards: subtle `white.opacity(0.05)` shadow

## Animation Specs

| Type | Response | Damping | Use |
|------|----------|---------|-----|
| Spring (snappy) | 0.3s | 0.75 | Button taps, tab switch |
| Spring (gentle) | 0.45s | 0.85 | Sheet expand, modal |
| Linear | 0.2s | — | Opacity fades |
| Continuous | 30fps | — | Canvas twinkling, orbits |

- Star pop (new): `0.6 + 0.4 × sin(t × 6)` scale
- Background stars: `sin(t + phase)` opacity oscillation
- Training overlay: orbiting dashed circles (3 concentric, rotating)
- Confetti: falling particles from top of screen

## Components Pattern
All interactive cards use:
```swift
RoundedRectangle(cornerRadius: 20, style: .continuous)
  .fill(Color.white.opacity(0.08))
  .overlay(RoundedRectangle(...).stroke(Color.white.opacity(0.15)))
```

## Mascot
**Nova** — Space fox 🦊. Speech bubbles are white `NovaBubble` cards with a colored left border matching the current status color. Used for advice, hints, and onboarding prompts.
