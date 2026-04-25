# AI Integration

## On-Device LLM (`ModelRun.swift`)

### Library
`ZeticMLangeiOS` v1.6.0 — on-device inference SDK.

### Model
`changgeun/gemma-4-E2B-it` (Gemma 4B quantized, instruction-tuned).
Run mode: `.RUN_SPEED` (faster, lower quality tradeoff).

### `runModel(prompt: String, onDownload: ..., onStream: ..., onComplete: ...)` (async)
- Lazily initializes `sharedModel` (cached globally to avoid 5–10s startup on repeat calls)
- `onDownload(Float)` → 0.0–1.0 progress during first-time model download
- `onStream(String)` → called per token for streaming display
- `onComplete(Error?)` → signals end of generation
- Streaming loop: `model.waitForNextToken()` until `generatedTokens == 0`

### `speak(text: String)`
AVSpeechSynthesizer TTS:
- Voice: `en-GB` (British English)
- Rate: 0.57, Pitch: 0.8, Volume: 0.8

### Auth
`personalToken = "ztp_92c5cc5cc8024dc89ce028f7bd2aa11d"` — defined in `Constants.swift`.

---

## Nova AI Chat (`NovaAITab` in `GalaxyTabs.swift`)

- Text input → calls `runModel()` with user's prompt
- Shows download progress card while model initializes
- Streams response into a "Nova answer" card
- No conversation history — stateless single-turn

---

## Upload & Star Generation (`UploadFlow.swift`)

### Purpose
Let users upload learning materials (files, pasted text, URLs). Nova "reads" them and generates new `StarNode`s for relevant constellations or creates a new one.

### `TopicRecipe` (keyword mapping)
Deterministic keyword → constellation routing:
- "math", "number", "addition", "subtraction" → add to `numbers` constellation
- "fraction", "pizza" → add to `fractions`
- "shape", "geometry" → add to `shapes`
- "time", "clock", "money" → add to `timemoney`
- "read", "story", "comprehension" → add to `reading`
- "write", "grammar" → add to `writing`
- "animal", "plant", "habitat" → add to `life`
- "earth", "weather", "planet", "space" → add to `earth`
- "history", "timeline", "explorer" → add to `history`
- *(unknown)* → creates new "Curiosity Cluster" constellation

### `GenerationResult`
```swift
struct GenerationResult {
    let isNew: Bool              // new constellation created?
    let constellationName: String
    let emoji: String
    let addedTopics: [String]    // new star labels
    let neighborTopics: [String] // bonus locked stars
    let jumpTo: (x: Double, y: Double, scale: Double) // camera target
}
```

### Flow
1. `UploadModal` — pick file/paste/link, tap "Grow stars!"
2. `ReadingScreen` — 4-stage animated analysis ("squinting → spotting → sorting → almost ready")
3. `RevealScreen` — confetti + summary of new stars, "Show me the stars!" navigates and zooms to new content
4. `GalaxyState.constellations` mutated to add new nodes; new IDs added to `pendingNewIds` for pop animation
