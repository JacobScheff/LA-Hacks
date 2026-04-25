# Data Models

All defined in [`GalaxyData.swift`](../LA\ Hacks/GalaxyData.swift).

## `StarStatus` (enum)
```swift
enum StarStatus { case mastered, learning, gap, locked }
```
| Status | Color (hex) | Meaning |
|--------|-------------|---------|
| mastered | #FFD700 gold | Fully learned |
| learning | #FF6B9D pink | In progress |
| gap | #00E5FF cyan | Known weakness |
| locked | #9E9E9E gray | Prerequisite not met |

## `StarPalette` (struct)
Per-status color tokens used throughout UI:
- `core: Color` — star fill
- `mid: Color` — mid gradient
- `halo: Color` — glow ring
- `glow: Color` — shadow/aura
- `label: String` — display name ("Mastered", "Learning", etc.)

Static factory: `StarPalette.for(_ status: StarStatus) -> StarPalette`

## `StarNode` (struct)
Individual skill/topic node.

| Property | Type | Notes |
|----------|------|-------|
| `id` | String | Unique key (e.g. `"add"`, `"half"`, `"tri"`) |
| `label` | String | Display name (e.g. "Adding") |
| `emoji` | String | 1–2 char emoji |
| `status` | StarStatus | Current learning status |
| `mastery` | Double | 0.0–1.0 mastery percentage |
| `x`, `y` | Double | Canvas world coordinates |

## `Edge` (struct)
Directed prerequisite link between two nodes.
```swift
struct Edge { let from: String; let to: String }
```

## `Constellation` (struct)
Subject area grouping nodes into a thematic cluster.

| Property | Type | Notes |
|----------|------|-------|
| `id` | String | Unique key (e.g. `"numbers"`) |
| `name` | String | Friendly name ("Number Land") |
| `realName` | String | Real constellation name ("Ursa Major") |
| `emoji` | String | Constellation icon |
| `description` | String | ~2 sentence about |
| `lore` | String | "Star story" narrative |
| `nodes` | [StarNode] | All stars in this constellation |
| `edges` | [Edge] | Prerequisite edges within constellation |
| `masteryAvg` | Double | Computed weighted average mastery |

## `GalaxyData` (enum — namespace)
Static factory providing all app content.

### `GalaxyData.constellations: [Constellation]`
9 pre-built constellations:

| ID | Name | Real Star | Subject | # Nodes |
|----|------|-----------|---------|---------|
| `numbers` | Number Land | Ursa Major | Math basics | 7 |
| `fractions` | Pizza Planet | Orion | Fractions | 4 |
| `shapes` | Shape City | Cassiopeia | Geometry | 8 |
| `timemoney` | Clock Cove | Leo | Time & Money | 4 |
| `reading` | Story Shore | Lyra | Reading | 7 |
| `writing` | Inkwell Isle | Cygnus | Writing | 7 |
| `life` | Critter Cove | Scorpius | Life Science | 7 |
| `earth` | Sky & Space | Ursa Minor | Earth Science | 7 |
| `history` | Time Travel Trail | Draco | History | 7 |

### `GalaxyData.backdropStars: [(x,y,r,opacity,phase)]`
320 background decoration stars generated with a deterministic LCG (seed 42). Rebuilt identically across app launches.

### `GalaxyData.bridges: [Edge]`
~12 cross-constellation edges (e.g., `mul → area`, `adding → addfrac`).

### `GalaxyData.nodesById: [String: (node: StarNode, constellation: Constellation)]`
Flattened index for O(1) node lookup by ID.

## `GenerationResult` (struct, `UploadFlow.swift`)
Output of the upload-and-generate flow:
```swift
struct GenerationResult {
    let isNew: Bool
    let constellationName: String
    let emoji: String
    let addedTopics: [String]
    let neighborTopics: [String]
    let jumpTo: (x: Double, y: Double, scale: Double)
}
```
