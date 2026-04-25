# Star Hop! — Project Overview

## What It Is
An iOS educational app for elementary-aged learners. Subjects (math, reading, science, history) are visualized as **constellations** in an interactive zoomable/pannable star map. Each skill is a "star" the student can tap to learn, practice, and master.

## App Name
**Star Hop!** (bundle/target: "LA Hacks")

## Built At
LA Hacks hackathon, April 24–25 2026.

## Key Tech
- **Swift / SwiftUI** — 100% SwiftUI, iOS target
- **ZeticMLangeiOS v1.6.0** — On-device LLM inference (Gemma 4B quantized model `changgeun/gemma-4-E2B-it`)
- **AVFoundation / AVSpeechSynthesizer** — Text-to-speech for Nova tutor
- **Canvas + TimelineView** — 30fps custom rendering for the star map
- No backend; all data is hard-coded and in-memory

## Dependency
Single SPM package: `ZeticMLangeiOS` from `https://github.com/zetic-ai/ZeticMLangeiOS`

## API Key / Token
`personalToken` in [Constants.swift](../LA\ Hacks/Constants.swift) — ZeticMLange token for model download.

## Core User Flow
1. Open app → `LearningGalaxyView` (interactive star map)
2. Tap a star → `SkillSheet` (half-modal with node details)
3. Tap "Train" → `TrainingOverlay` (quest launch sequence)
4. Tap "Blast Off!" → `LessonView` (full-screen tutoring)
5. Complete lesson → celebrate → return to galaxy
6. Optional: Upload learning materials → Nova generates new stars via `UploadFlow`

## AI Tutor
"Nova" — a space fox mascot. Provides advice in the `SkillSheet`, answers questions in `NovaAITab`, and guides the `UploadFlow`. Runs on-device via ZeticMLange.

## Navigation Tabs (bottom nav)
| Tab | View | Description |
|-----|------|-------------|
| Galaxy | `LearningGalaxyView` | Main star map |
| Quests | `StudyTab` | Daily quests + quest rows |
| Nova | `NovaAITab` | Chat with AI tutor |
| Me | `YouTab` | Profile, stickers, heatmap |
