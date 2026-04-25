# .context — Agent Memory Index

Quick-reference context files for the **Star Hop!** iOS project (LA Hacks 2026).

| File | Contents |
|------|----------|
| [overview.md](overview.md) | App purpose, tech stack, core user flow, navigation tabs |
| [architecture.md](architecture.md) | File map, state management, data flow diagram, gesture system |
| [data-models.md](data-models.md) | All Swift types: StarNode, Constellation, GalaxyData, etc. |
| [ui-components.md](ui-components.md) | Every view/component with file locations and key props |
| [design-system.md](design-system.md) | Colors, typography, animation specs, glassmorphism patterns |
| [lesson-system.md](lesson-system.md) | Lesson stage machine, ProblemView types, lesson bank |
| [ai-integration.md](ai-integration.md) | ZeticMLange LLM, Nova chat, UploadFlow generation |

## Quick Facts
- **Language**: Swift / SwiftUI only
- **No backend** — all data in-memory, hard-coded
- **AI**: On-device Gemma 4B via ZeticMLangeiOS v1.6.0
- **Mascot**: Nova the space fox 🦊
- **Target users**: Elementary-aged learners
- **Constellations**: 9 subjects, each ~4–8 star nodes
- **Main state class**: `GalaxyState` (ObservableObject, EnvironmentObject)
- **Entry point**: `LA_HacksApp.swift` → `ContentView` → `LearningGalaxyView`
