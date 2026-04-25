# Lesson System

Defined in [`LessonView.swift`](../LA\ Hacks/LessonView.swift).

## Stage Machine
`LessonView` progresses through 4 stages:
```
welcome → example → practice → celebrate
```

| Stage | What shows |
|-------|-----------|
| `welcome` | Nova greeting, lesson intro card, stats (# Qs, time, max XP), "Let's go!" button |
| `example` | Worked example with Nova explanation, reveal-able answer |
| `practice` | `ProblemView` for each problem in sequence |
| `celebrate` | 3-star rating, XP/hearts/hints/streak summary, "Back to galaxy" |

## Key State (in `LessonView`)
- `stage: Stage` — current phase
- `problemIdx: Int` — which problem in `lesson.problems`
- `streak: Int` — consecutive correct answers
- `xpGained: Int` — accumulated XP this lesson
- `hearts: Int` (starts at 3) — mistakes remaining
- `hintsUsed: Int` — hint taps

## `LessonProblem` (struct)
| Field | Type | Notes |
|-------|------|-------|
| `kind` | `ProblemKind` | `.multipleChoice`, `.input`, `.pizza` |
| `prompt` | String | Question text |
| `hint` | String | Revealed on hint tap |
| `answer` | String | Correct answer (case-insensitive match for input) |
| `choices` | [String]? | A/B/C/D options (multipleChoice only) |
| `slices` | Int? | Total pizza slices (pizza only) |
| `target` | Int? | Slices to select (pizza only) |

Static builders: `LessonProblem.mc(...)`, `.input(...)`, `.pizza(...)`

## `LessonContent` (struct)
| Field | Type |
|-------|------|
| `intro` | String |
| `exampleQuestion` | String |
| `exampleAnswer` | String |
| `exampleViz` | String (emoji) |
| `problems` | [LessonProblem] |

## `ProblemView` Behavior
- **Multiple choice**: 4 buttons (A/B/C/D). Tapping selects, second tap submits. Selected button gets gradient fill.
- **Input**: `TextField` + "Check" button. Answer matching is case-insensitive and trims whitespace.
- **Pizza**: Visual pizza circle with tappable wedge slices. Tap to select/deselect, submit when target count reached.
- **Hint**: Collapsed button → tapped reveals `NovaBubble` with hint text. Increments `hintsUsed`.
- **Feedback**: After submit shows correctness message. If wrong: reveals answer, no XP. If right: +10–25 XP.

## Lesson Bank (hard-coded in `LessonView.swift`)
Lessons keyed by `StarNode.id`:

| Node ID | Topic | Problem Types |
|---------|-------|---------------|
| `add` | Adding | MC + input |
| `mul` | Multiplication | MC + input |
| `half` | Halves (fractions) | Pizza + MC |
| `addfrac` | Adding fractions | MC + input |
| `tri` | Triangles | MC |
| `area` | Area | Input |
| `main` | Main idea (reading) | MC |
| `habitat` | Animal habitats | MC |
| *(default)* | Generic fallback | MC + input |

## Celebrate Screen Scoring
- 3 stars: all hearts remaining + no hints
- 2 stars: ≥1 heart remaining
- 1 star: completed (any hearts/hints)
- XP summary, streak bonus, and "Back to galaxy" dismiss button
