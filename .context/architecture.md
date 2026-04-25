# Architecture

## File Map

| File | Role |
|------|------|
| `LA_HacksApp.swift` | `@main` entry point → `ContentView` |
| `ContentView.swift` | Thin wrapper → `LearningGalaxyView` |
| `Constants.swift` | `personalToken` (ZeticMLange API key) |
| `GalaxyData.swift` | All data models + static content (9 constellations, 320 backdrop stars) |
| `GalaxyComponents.swift` | Reusable UI: `TopHeader`, `BottomNav`, `MasteryRing`, `SkillSheet`, `FlowLayout` |
| `GalaxyOverlays.swift` | Full-screen overlays: `TrainingOverlay`, `ConstellationModal` |
| `GalaxyTabs.swift` | Tab content: `StudyTab`, `PathsTab`, `NovaAITab`, `YouTab` |
| `LearningGalaxyView.swift` | Root galaxy screen: `GalaxyState`, `LearningGalaxyView`, `GalaxyScreen`, `SkyCanvas`, `GalaxyHitLayer` |
| `LessonView.swift` | Lesson flow: `LessonView`, `ProblemView`, `NovaBubble`, `BigButton`, `PizzaSlice` |
| `ModelRun.swift` | LLM wrapper: `runModel()`, `speak()` |
| `UploadFlow.swift` | Upload & generate new stars: `UploadModal`, `ReadingScreen`, `RevealScreen`, `GenerationResult` |

## State Management

### `GalaxyState` (ObservableObject, @MainActor)
- Defined in `LearningGalaxyView.swift`
- Shared as `@EnvironmentObject` down the entire view tree
- Holds `constellations: [Constellation]` (the live mutable data)
- `pendingNewIds: Set<String>` — IDs of newly-added stars (drives pop animation)
- `stats` computed property: `(mastered: Int, gap: Int, learning: Int)`
- `nodesById()` → `[String: (node: StarNode, constellation: Constellation)]`

### View-Level `@State`
Each view owns ephemeral state:
- `LearningGalaxyView`: `selectedTab`, `trainingNode`, `lessonNode`, `showUpload`, etc.
- `GalaxyScreen`: `tx`, `ty`, `scale`, `dragDelta`, `pinchScale`, `selected`, `showSheet`
- `LessonView`: `stage`, `problemIdx`, `streak`, `xpGained`, `hearts`, `hintsUsed`

## Data Flow (Happy Path)

```
LA_HacksApp
  └── ContentView
        └── LearningGalaxyView (GalaxyState EnvironmentObject)
              ├── [selectedTab == 0] GalaxyScreen
              │     ├── SkyCanvas (Canvas, TimelineView — 30fps)
              │     ├── GalaxyHitLayer (invisible tappable overlay)
              │     ├── TopHeader
              │     ├── BottomNav
              │     └── SkillSheet (half-modal on star tap)
              ├── [selectedTab == 1] StudyTab
              ├── [selectedTab == 2] NovaAITab  ← calls runModel()
              ├── [selectedTab == 3] YouTab
              ├── TrainingOverlay (fullScreenCover)  ← when trainingNode != nil
              └── LessonView (fullScreenCover)       ← when lessonNode != nil
```

## Overlay / Modal Stack (z-order)

1. `SkyCanvas` + `GalaxyHitLayer` (base)
2. Top fade + bottom fade gradients
3. `TopHeader` (sticky, z:10)
4. `BottomNav` (sticky, z:10)
5. `SkillSheet` (half-modal, `zIndex(5)`)
6. `ConstellationModal` (half-modal, triggered from constellation nameplate tap)
7. `TrainingOverlay` (fullScreenCover)
8. `LessonView` (fullScreenCover, on top of Training)
9. `UploadFlow` screens (sheet or fullScreenCover)

## Canvas Rendering (`SkyCanvas`)

- Driven by `TimelineView(.animation(minimumInterval: 1/30))` for smooth 30fps
- Receives `GalaxyState` via EnvironmentObject
- Draw order per frame:
  1. Nebulae (radial gradients)
  2. Backdrop stars (320, procedural twinkling via `sin(t + phase)`)
  3. Cross-constellation bridges (dashed lines, 0.4 opacity)
  4. Constellation edges (lines between nodes in same constellation)
  5. Stars (halo → shape → overlays → labels)
  6. Constellation nameplates (pill labels)
  7. "Discover nebula" pulsing prompt (if no custom constellation)

## Gesture System (`GalaxyScreen`)

- `DragGesture(minimumDistance: 0)` → pan (`tx`, `ty`)
- `MagnifyGesture` → pinch zoom (`scale` 0.4–3.0), focal point corrected
- Bounds clamping: prevents panning past canvas edges
- Hit-test: `GalaxyHitLayer` converts world→screen coordinates and places tap targets
