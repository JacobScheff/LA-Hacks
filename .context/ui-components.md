# UI Components

## Root / Navigation

### `LearningGalaxyView` — `LearningGalaxyView.swift`
Root view. Owns tab selection, overlay triggers, upload flow state.
- `@EnvironmentObject var galaxy: GalaxyState`
- `@State var selectedTab: Int` (0=Galaxy, 1=Quests, 2=Nova, 3=Me)
- Renders tab content + overlays + fullScreenCovers

### `BottomNav` — `GalaxyComponents.swift`
Frosted 5-tab bar pinned to bottom (110px safe-area padding).
- Tabs: Galaxy (🌌), Quests (📚), Nova (🦊), Me (👤)
- Active tab: gold fill, spring-animated upward shift
- Swipe gesture: ±40px horizontal swipe switches tab

### `TopHeader` — `GalaxyComponents.swift`
56px sticky header (z:10).
- "Hi, Maya!" greeting + fox avatar
- Star count stats (mastered/gap/learning from `GalaxyState.stats`)
- XP progress circle + streak chip (🔥)
- Filter chips: All / Gap / Learning / Mastered

---

## Galaxy Screen

### `GalaxyScreen` — `LearningGalaxyView.swift`
Interactive pan/zoom container.
- `tx`, `ty`: Pan offset (clamped to canvas bounds)
- `scale`: Zoom level (0.4–3.0)
- Layers: `SkyCanvas` + `GalaxyHitLayer` + fades + `TopHeader` + `BottomNav`

### `SkyCanvas` — `LearningGalaxyView.swift`
`TimelineView`-driven `Canvas` at 30fps.
- Draws all visual elements (see architecture.md → Canvas Rendering)
- Receives time `t` from TimelineView for animations
- Star types rendered differently by status (mastered = eyes+smile, gap = extra aura, learning = center dot)

### `GalaxyHitLayer` — `LearningGalaxyView.swift`
Invisible overlay matching `SkyCanvas` layout.
- Places tappable `Circle` / `Rectangle` areas at world→screen coordinates
- Handles: star taps → `SkillSheet`, constellation nameplate taps → `ConstellationModal`, discover nebula tap → `UploadModal`

### `ZoomControls` — `LearningGalaxyView.swift`
Floating +/−/reset buttons (bottom-right, above `BottomNav`).

### `HintPill` — `LearningGalaxyView.swift`
Pulsing "Tap sleepy stars" prompt pill shown until first star tap.

---

## Modals & Sheets

### `SkillSheet` — `GalaxyComponents.swift`
Half-modal sliding up from bottom when a star is tapped.
- Drag handle at top; dismiss by tapping above or dragging down
- Height: 55%–100% of screen (gesture-resizable)
- Contents:
  - `MasteryRing` (78px circle) + node name + constellation name
  - Status badge (colored capsule)
  - Nova advice `NovaBubble`
  - Stat tiles: times played, last practiced, score %
  - Related stars (`FlowLayout` of neighbor node chips)
  - CTA button (label + XP reward depend on `StarStatus`)

### `MasteryRing` — `GalaxyComponents.swift`
78px circular progress indicator.
- `Circle` stroke arc (4pt) colored by `StarPalette`
- Center: emoji at 28px font
- White track behind colored arc

### `ConstellationModal` — `GalaxyOverlays.swift`
Half-modal (0.6–1.0 screen height, draggable) for constellation details.
- Mini sky preview (rescaled constellation canvas)
- Real constellation name, friendly name, mastery bar
- About card + Star Story card
- Breakdown grid: mastered/learning/gap/locked counts
- Scrollable star list with mastery %
- "Explore the constellation" CTA

### `TrainingOverlay` — `GalaxyOverlays.swift`
Full-screen quest launch (fullScreenCover).
- 4-step animated calibration sequence with checkmarks
- Orbiting star animation (3 dashed concentric circles)
- Center emoji pulses + glow
- Confetti from top
- "Blast Off!" button after sequence completes
- Dismissible with X

### `FlowLayout` — `GalaxyComponents.swift`
Custom Layout wrapping items into rows.
- Auto-wraps when items exceed container width
- Used by `SkillSheet` for "related stars" chips

---

## Tab Content Views

### `StudyTab` — `GalaxyTabs.swift`
Quests tab:
- Daily adventure hero card (gradient + rocket emoji)
- Streak indicator + "Next quest" summary
- Quest rows: emoji, title, duration, XP reward
- Mini-metrics: Streak / New stars / Sleepy count

### `PathsTab` — `GalaxyTabs.swift`
Trips/paths tab:
- `PathStrip`: Visual progress bar with lit/unlit star nodes
- Trip cards: title, description, path strip, XP reward

### `NovaAITab` — `GalaxyTabs.swift`
Nova AI chat tab:
- Text input field
- Download progress card (during model init)
- Response card with streaming LLM output
- Calls `runModel()` from `ModelRun.swift`

### `YouTab` — `GalaxyTabs.swift`
Profile tab:
- Hero: fox avatar, name "Maya", level, join date
- 2×2 metrics: Stars lit, Worlds, Streak, Stickers
- Sticker book grid (6 or 12 items, locked = grayscale + lock icon)
- 12×7 activity heatmap (intensity 0–3 with glow)
- Recent wins timeline

---

## Lesson Views

### `LessonView` — `LessonView.swift`
Full-screen lesson (fullScreenCover).
- Stage machine: `welcome → example → practice → celebrate`
- Progress bar with stage label
- See `lesson-system.md` for full details

### `ProblemView` — `LessonView.swift`
Renders a single `LessonProblem` based on `kind`:
- `.multipleChoice` — A/B/C/D buttons, gradient on select
- `.input` — text field + check button
- `.pizza` — interactive pizza wedge visual

### `NovaBubble` — `LessonView.swift`
White rounded card with colored border. Used for Nova's advice/hints.

### `BigButton` — `LessonView.swift`
Large full-width CTA button. Gradient fill, colored shadow.

### `PizzaSlice` — `LessonView.swift`
Custom Shape drawing a pizza wedge (used in pizza fraction problems).

---

## Upload Flow Views

### `UploadModal` — `UploadFlow.swift`
Pick-content sheet.
- Tabs: file / paste / link
- Hero: Nova + magnifier emoji
- Quick-start example chips
- "Grow stars!" CTA

### `ReadingScreen` — `UploadFlow.swift`
Analysis animation screen.
- Pulsing rings + flying documents + magnifier
- 4-stage progress labels

### `RevealScreen` — `UploadFlow.swift`
Celebration screen after generation.
- Confetti canvas
- New constellation summary
- Topic rows (new stars) + neighbor block
- "Show me the stars!" CTA
