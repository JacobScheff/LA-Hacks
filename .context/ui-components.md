# UI Components

## Root / Navigation

### `LearningGalaxyView` — `Pages/LearningGalaxyView.swift`
Root view. Owns tab selection, overlay triggers, upload flow state.
- `@EnvironmentObject var galaxy: GalaxyState`
- `@State var selectedTab: Int` (0=Galaxy, 1=Quests, 2=Nova, 3=Me)
- Renders tab content + overlays + fullScreenCovers

### `BottomNav` — `Components/BottomNav.swift`
Frosted 5-tab bar pinned to bottom (110px safe-area padding).
- Tabs: Galaxy (🌌), Quests (📚), Nova (🦊), Me (👤)
- Active tab: gold fill, spring-animated upward shift
- Swipe gesture: ±40px horizontal swipe switches tab

### `TopHeader` — `Components/TopHeader.swift`
56px sticky header (z:10).
- "Hi, Maya!" greeting + fox avatar
- Star count stats (mastered/gap/learning from `GalaxyState.stats`)
- XP progress circle + streak chip (🔥)
- Filter chips: All / Gap / Learning / Mastered

---

## Galaxy Screen

### `GalaxyScreen` — `Pages/GalaxyScreen.swift`
Interactive pan/zoom container.
- `tx`, `ty`: Pan offset (clamped to canvas bounds)
- `scale`: Zoom level (0.4–3.0)
- Layers: `SkyCanvas` + `GalaxyHitLayer` + fades + `TopHeader` + `BottomNav`

### `SkyCanvas` — `Components/SkyCanvas.swift`
`TimelineView`-driven `Canvas` at 30fps.
- Draws all visual elements (see architecture.md → Canvas Rendering)
- Receives time `t` from TimelineView for animations
- Star types rendered differently by status (mastered = eyes+smile, gap = extra aura, learning = center dot)

### `GalaxyHitLayer` — `Components/GalaxyHitLayer.swift`
Invisible overlay matching `SkyCanvas` layout.
- Places tappable `Circle` / `Rectangle` areas at world→screen coordinates
- Handles: star taps → `SkillSheet`, constellation nameplate taps → `ConstellationModal`, discover nebula tap → `UploadModal`

### `HintPill` — `Components/HintPill.swift`
Pulsing "Tap sleepy stars" prompt pill shown until first star tap.

---

## Modals & Sheets

### `SkillSheet` — `Components/SkillSheet.swift`
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

### `MasteryRing` — `Components/MasteryRing.swift`
78px circular progress indicator.
- `Circle` stroke arc (4pt) colored by `StarPalette`
- Center: emoji at 28px font
- White track behind colored arc

### `ConstellationModal` — `Components/ConstellationModal.swift`
Half-modal (0.6–1.0 screen height, draggable) for constellation details.
- Mini sky preview (rescaled constellation canvas)
- Real constellation name, friendly name, mastery bar
- About card + Star Story card
- Breakdown grid: mastered/learning/gap/locked counts
- Scrollable star list with mastery %
- "Explore the constellation" CTA

### `TrainingOverlay` — `Components/TrainingOverlay.swift`
Full-screen quest launch (fullScreenCover).
- 4-step animated calibration sequence with checkmarks
- Orbiting star animation (3 dashed concentric circles)
- Center emoji pulses + glow
- Confetti from top
- "Blast Off!" button after sequence completes
- Dismissible with X

### `FlowLayout` — `Components/FlowLayout.swift`
Custom Layout wrapping items into rows.
- Auto-wraps when items exceed container width
- Used by `SkillSheet` for "related stars" chips

---

## Tab Content Views

### `StudyTab` — `Pages/StudyTab.swift`
Quests tab:
- Daily adventure hero card (gradient + rocket emoji)
- Streak indicator + "Next quest" summary
- Quest rows: emoji, title, duration, XP reward
- Mini-metrics: Streak / New stars / Sleepy count

### `PathsTab` — `Pages/PathsTab.swift`
Trips/paths tab:
- `PathStrip`: Visual progress bar with lit/unlit star nodes
- Trip cards: title, description, path strip, XP reward

### `NovaAITab` — `Pages/NovaAITab.swift`
Nova AI chat tab:
- Text input field
- Download progress card (during model init)
- Response card with streaming LLM output
- Calls `runModel()` from `ModelRun.swift`

### `YouTab` — `Pages/YouTab.swift`
Profile tab:
- Hero: fox avatar, name "Maya", level, join date
- 2×2 metrics: Stars lit, Worlds, Streak, Stickers
- Sticker book grid (6 or 12 items, locked = grayscale + lock icon)
- 12×7 activity heatmap (intensity 0–3 with glow)
- Recent wins timeline

---

## Lesson Views

### `LessonView` — `Pages/LessonView.swift`
Full-screen lesson (fullScreenCover).
- Stage machine: `welcome → example → practice → celebrate`
- Progress bar with stage label
- See `lesson-system.md` for full details

### `MCChoicesView` — `Components/Lesson/MCChoicesView.swift`
Renders a multiple-choice answer panel for `LessonProblem`s with `.multipleChoice` kind: A/B/C/D buttons, gradient on select.

### `TextInputView` — `Components/Lesson/TextInputView.swift`
Renders a text input answer panel for `LessonProblem`s with `.input` (or pizza-converted) kind: text field + check button.

### `MsgBubble` — `Components/Lesson/MsgBubble.swift`
Chat bubble for the lesson view. Renders Nova messages, student replies, and stats summaries (post-lesson). Owns the `ChatMsg` data model.

### `NovaAvatarView` — `Components/Lesson/NovaAvatarView.swift`
Small Nova avatar (gradient circle with `✦` glyph) used in the lesson chat.

### `LessonInputArea` — `Components/Lesson/LessonInputArea.swift`
Bottom input area host for the lesson view. Switches between an action button, MC choices, and text input.

### `HintButton` — `Components/Lesson/HintButton.swift`
Hint reveal button shown beneath MC and text-input panels.

### `TypingBubble` — `Components/Lesson/TypingBubble.swift`
Bouncing-dots "Nova is typing…" indicator bubble.

### `LessonThinkingBubble` — `Components/Lesson/LessonThinkingBubble.swift`
Bubble shown while the on-device model generates a hint. Combines a caption with the gravity n-body `StarOrbitLoadingView`.

### `CelebrationBurst` — `Components/Lesson/CelebrationBurst.swift`
Brief star shimmer overlay shown when the student answers correctly (~600ms, non-blocking).

---

## Sticker Book

### `StickerBookView` — `Pages/StickerBookView.swift`
Full sticker book accessible from the Me tab. Hosts the page view plus shared data types (`StickerCat`, `StickerRarity`, `StarStickerItem`, `StarStickerData`).

### `StickerCell` — `Components/StickerCell.swift`
Single sticker tile in the sticker book grid. Renders rarity styling and locked/unlocked state.

### `StickerDetailSheet` — `Components/StickerDetailSheet.swift`
Detail sheet shown when tapping a sticker. Shows artwork, rarity, and unlock criteria.

---

## Upload Flow Views

### `UploadModal` — `Pages/UploadModal.swift`
Pick-content sheet.
- Tabs: file / paste / link
- Hero: Nova + magnifier emoji
- Quick-start example chips
- "Grow stars!" CTA

### `ReadingScreen` — `Pages/ReadingScreen.swift`
Analysis animation screen.
- Pulsing rings + flying documents + magnifier
- 4-stage progress labels

### `RevealScreen` — `Pages/RevealScreen.swift`
Celebration screen after generation.
- Confetti canvas
- New constellation summary

---

## Onboarding

### `Onboard` — `Pages/Onboard.swift`
First-launch onboarding flow (greeting, age picker, grade chips, name entry).

### `MinigameView` — `Components/MinigameView.swift`
Mini interactive sample shown during onboarding to demo the lesson loop.

---

## Settings

### `SettingsTab` — `Pages/SettingsTab.swift`
Settings page (sound, music, notifications, age, parent PIN, grade chips).

### `SettingsComponents` — `Components/SettingsComponents.swift`
Shared building blocks for the Settings tab: `SettingsSection`, `SettingsLabel`, `SettingsDivider`, `ToggleRow`.

### `FlexWrap` — `Components/FlexWrap.swift`
Simple horizontal-wrapping `Layout` used for grade chips.

---

## Shared Tab UI

### `TabHeader` — `Components/TabHeader.swift`
Shared header used by Quests / Trips / Nova AI / Settings tabs (kicker + emoji + title + subtitle). Also hosts the `sCard` View extension used to style cards across tab content.

### `MiniMetric` — `Components/MiniMetric.swift`
Small labeled stat tile used in StudyTab.

### `PathStrip` — `Components/PathStrip.swift`
Connected-stars progress strip used in PathsTab.

### `StarOrbitLoadingView` — `Components/StarOrbitLoadingView.swift`
Gravity n-body simulation loading view (3 stars orbiting with trails). Hosts `NBodyEngine` (the simulation `ObservableObject`). Used inside `LessonThinkingBubble` and the Nova AI tab.

---

## Galaxy Navigation

### `CustomBottomNav` — `Components/CustomBottomNav.swift`
Bottom navigation bar used by `LearningGalaxyView` (Galaxy / Quests / Nova / Me).

### `NavTabButton` — `Components/NavTabButton.swift`
Single tab button inside `CustomBottomNav`.

### `TelescopeOverlayView` — `Components/TelescopeOverlayView.swift`
Telescope eyepiece overlay used as a warp-in page transition into the galaxy view.
- Topic rows (new stars) + neighbor block
- "Show me the stars!" CTA
