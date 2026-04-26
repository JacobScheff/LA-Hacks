//
//  LessonGenerator.swift
//  LA Hacks
//
//  Drives the adaptive, per-step lesson via on-device Gemma-4. Instead of
//  generating a whole lesson upfront, callers request one piece at a time:
//    • generateOpening — intro + example
//    • generateProblem — next problem, conditioned on prior performance
//    • coach           — short kind nudge after a wrong answer
//    • walkThrough     — final explanation after max attempts
//
//  All public calls are serialized via a single actor; the shared LLM model
//  can only handle one prompt at a time and concurrent calls would corrupt
//  output.
//

import Foundation

// MARK: - Tunables

enum LessonConfig {
    /// Total problems in a lesson. Trivially adjustable.
    static var problemCount: Int = 3

    /// How many times the kid can try a single problem before Nova walks them
    /// through the answer and moves on.
    static var maxAttemptsPerProblem: Int = 2

    /// Soft cap on tokens we wait for from a coaching message — very short.
    static var coachingMaxAttempts: Int = 1
}

// MARK: - Public types

/// All the curricular context the model needs about the topic being taught.
struct LessonContext {
    let node: StarNode
    let constellationName: String?
    let course: String?
    let blurb: String?
    let siblingLabels: [String]
    /// Optional memory file (markdown) loaded from MemoryStore. Empty for
    /// brand-new students.
    var memory: String = ""
}

struct LessonOpening {
    let intro: String
    let exampleQuestion: String
    let exampleAnswer: String
    let exampleViz: String
}

/// Snapshot of the kid's outcome on one problem, fed back into the next prompt.
struct PastProblemOutcome {
    let prompt: String
    let correctAnswer: String
    let studentAnswer: String
    let correct: Bool
    let attempts: Int
    let hintUsed: Bool
}

// MARK: - Serialization

actor LessonGeneratorQueue {
    static let shared = LessonGeneratorQueue()
    private var inFlight = false

    func run<T: Sendable>(_ work: @Sendable @escaping () async -> T) async -> T {
        while inFlight { try? await Task.sleep(nanoseconds: 100_000_000) }
        inFlight = true
        defer { inFlight = false }
        return await work()
    }
}

// MARK: - Constellation intro (used after upload)

/// Customized constellation metadata derived from a freshly-uploaded doc.
struct ConstellationIntro {
    let name: String        // ≤ 4 words, kid-friendly
    let blurb: String       // 1 sentence describing what's inside
    let skyStory: String    // 1-2 sentence whimsical "why this constellation appeared"
    let course: String      // short label like "Math · Adding & Subtracting"
}

// MARK: - Generator

enum LessonGenerator {

    // MARK: - Language directive (used by every prompt builder)

    /// One-line directive injected into the System Prompt of every model call so
    /// Nova replies (and the JSON payloads it returns) stay in the user's chosen
    /// language. JSON keys remain English; only the *values* get translated.
    private static func languageDirective() -> String {
        let code = UserSettings.shared.language
        let name = Translations.displayName(forLanguage: code)
        NSLog("[i18n] LessonGenerator.languageDirective code=\(code) name=\(name)")
        return "Always write to the student in \(name) (\(code)). Keep JSON keys in English, but every JSON string VALUE — `intro`, `prompt`, `hint`, `question`, `viz` words, etc. — and every free-text reply must be in \(name)."
    }

    // MARK: Constellation intro (used after upload)

    /// Generates a custom name + blurb + skyStory + course label for a brand-new
    /// constellation grown from an upload. The result replaces the subject-default
    /// metadata so each upload feels uniquely tied to the doc the student picked.
    /// Returns nil on model failure or unparseable JSON; caller falls back to defaults.
    static func generateConstellationIntro(
        uploadedText: String,
        suggestedName: String,
        suggestedEmoji: String,
        topicLabels: [String]
    ) async -> ConstellationIntro? {
        await LessonGeneratorQueue.shared.run {
            await runConstellationIntro(
                uploadedText: uploadedText,
                suggestedName: suggestedName,
                suggestedEmoji: suggestedEmoji,
                topicLabels: topicLabels
            )
        }
    }

    private static func runConstellationIntro(
        uploadedText: String,
        suggestedName: String,
        suggestedEmoji: String,
        topicLabels: [String]
    ) async -> ConstellationIntro? {
        let prompt = buildConstellationIntroPrompt(
            uploadedText: uploadedText,
            suggestedName: suggestedName,
            suggestedEmoji: suggestedEmoji,
            topicLabels: topicLabels
        )
        guard let raw = try? await streamAll(prompt: prompt, onStream: { _ in }) else {
            return nil
        }
        let cleaned = stripThoughts(raw)
        guard let json = extractJSONObject(from: cleaned),
              let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = (obj["name"] as? String).flatMap({ $0.isEmpty ? nil : $0 }),
              let blurb = (obj["blurb"] as? String).flatMap({ $0.isEmpty ? nil : $0 }),
              let sky = (obj["skyStory"] as? String).flatMap({ $0.isEmpty ? nil : $0 })
        else {
            print("LessonGenerator: constellation intro JSON missing fields:\n\(cleaned)")
            return nil
        }
        let course = (obj["course"] as? String) ?? "Just for you · made by Nova"
        return ConstellationIntro(
            name: trimToWords(name, maxWords: 4),
            blurb: blurb,
            skyStory: sky,
            course: course
        )
    }

    private static func buildConstellationIntroPrompt(
        uploadedText: String,
        suggestedName: String,
        suggestedEmoji: String,
        topicLabels: [String]
    ) -> String {
        // Cap source text so the prompt stays small even for big PDFs.
        let snippet = String(uploadedText.prefix(2000))
        let topicList = topicLabels.prefix(8).joined(separator: ", ")
        return """
        System Prompt:
        Do not use thinking tokens.
        You are Nova, a warm, playful tutor for elementary kids who names new
        constellations in a galaxy-themed learning app.
        \(languageDirective())

        User Prompt:
        A student just uploaded a doc, and Nova grew a brand-new constellation
        for it. Read the snippet below and craft custom metadata for that
        constellation.

        Suggested fallback name: \(suggestedName) \(suggestedEmoji)
        Topics inside it: \(topicList.isEmpty ? "(none yet)" : topicList)

        Doc snippet (may be noisy OCR):
        ---
        \(snippet)
        ---

        Output ONLY a JSON object inside ```json fences:
        {
          "name": "kid-friendly constellation name, 2-4 words, Title Case",
          "blurb": "1 short sentence (under 18 words) describing what these stars are about, child-friendly",
          "skyStory": "1-2 magical sentences about why this constellation appeared in the sky (under 30 words)",
          "course": "short subject + grade label like 'Math · Grades 3-4' or 'Reading · Grades 4-5'"
        }

        Rules:
        - Name must NOT contain emoji (emoji shown separately).
        - Blurb avoids jargon; speaks TO a kid.
        - skyStory uses imagery (stars waking up, twinkling, whispering, etc.).
        - No markdown outside the json fence. No commentary.

        ```json
        """
    }

    /// Soft-trims a phrase to the first N space-separated words, preserving casing.
    private static func trimToWords(_ s: String, maxWords: Int) -> String {
        let words = s.split(separator: " ").map(String.init)
        if words.count <= maxWords { return s.trimmingCharacters(in: .whitespacesAndNewlines) }
        return words.prefix(maxWords).joined(separator: " ")
    }

    // MARK: Opening (intro + example)

    static func generateOpening(
        _ ctx: LessonContext,
        onStream: @escaping (String) -> Void = { _ in }
    ) async -> LessonOpening? {
        await LessonGeneratorQueue.shared.run {
            await runOpening(ctx, onStream: onStream)
        }
    }

    private static func runOpening(
        _ ctx: LessonContext,
        onStream: @escaping (String) -> Void
    ) async -> LessonOpening? {
        let prompt = buildOpeningPrompt(ctx)
        guard let raw = try? await streamAll(prompt: prompt, onStream: onStream) else {
            return nil
        }
        let cleaned = stripThoughts(raw)
        guard let json = extractJSONObject(from: cleaned) else {
            print("LessonGenerator: opening JSON not found:\n\(cleaned)")
            return nil
        }
        guard
            let data = json.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let intro = obj["intro"] as? String,
            let example = obj["example"] as? [String: Any],
            let q = example["question"] as? String,
            let a = example["answer"] as? String
        else { return nil }
        let viz = (example["viz"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? ctx.node.emoji
        return LessonOpening(
            intro: intro,
            exampleQuestion: q,
            exampleAnswer: a,
            exampleViz: viz
        )
    }

    // MARK: Per-problem (adaptive)

    static func generateProblem(
        _ ctx: LessonContext,
        history: [PastProblemOutcome],
        index: Int,
        total: Int,
        onStream: @escaping (String) -> Void = { _ in }
    ) async -> LessonProblem? {
        await LessonGeneratorQueue.shared.run {
            await runProblem(ctx, history: history, index: index, total: total, onStream: onStream)
        }
    }

    private static func runProblem(
        _ ctx: LessonContext,
        history: [PastProblemOutcome],
        index: Int,
        total: Int,
        onStream: @escaping (String) -> Void
    ) async -> LessonProblem? {
        let prompt = buildProblemPrompt(ctx, history: history, index: index, total: total)
        guard let raw = try? await streamAll(prompt: prompt, onStream: onStream) else {
            return nil
        }
        let cleaned = stripThoughts(raw)
        guard let json = extractJSONObject(from: cleaned) else {
            print("LessonGenerator: problem JSON not found:\n\(cleaned)")
            return nil
        }
        guard
            let data = json.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let pPrompt = obj["prompt"] as? String,
            let pAnswer = obj["answer"] as? String,
            let pHint = obj["hint"] as? String,
            !pAnswer.trimmingCharacters(in: .whitespaces).isEmpty
        else { return nil }
        return .input(pPrompt, answer: pAnswer, hint: pHint)
    }

    // MARK: Answer judgment (semantic correctness, not exact match)

    /// Asks Gemma whether the student's freeform answer is correct, given
    /// the question and the canonical answer. Used as a fallback when the
    /// fast normalized-string match fails — handles "eight" vs "8",
    /// "the desert" vs "desert", "1/2" vs "one half", etc.
    /// Returns nil if the model can't be reached or replies ambiguously,
    /// in which case the caller should treat the answer as incorrect.
    static func judgeAnswer(
        _ ctx: LessonContext,
        problem: LessonProblem,
        studentAnswer: String,
        onStream: @escaping (String) -> Void = { _ in }
    ) async -> Bool? {
        let prompt = buildJudgePrompt(ctx, problem: problem, studentAnswer: studentAnswer)
        return await LessonGeneratorQueue.shared.run {
            await runJudgment(prompt: prompt, onStream: onStream)
        }
    }

    private static func runJudgment(
        prompt: String,
        onStream: @escaping (String) -> Void
    ) async -> Bool? {
        guard let raw = try? await streamAll(prompt: prompt, onStream: onStream) else {
            return nil
        }
        let cleaned = stripThoughts(raw)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // Prefer a JSON verdict if the model produced one.
        if let data = extractJSONObject(from: cleaned)?.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let v = obj["correct"] as? Bool {
            return v
        }
        // Otherwise scan for the keyword. Order matters — check "no" / "incorrect"
        // first since "yes" is a substring of "yes, but no" type drift.
        if cleaned.hasPrefix("no") || cleaned.contains("incorrect") || cleaned.contains("not correct") || cleaned.contains("wrong") {
            return false
        }
        if cleaned.hasPrefix("yes") || cleaned.contains("correct") || cleaned.contains("equivalent") || cleaned.contains("matches") {
            return true
        }
        return nil
    }

    private static func buildJudgePrompt(
        _ ctx: LessonContext,
        problem: LessonProblem,
        studentAnswer: String
    ) -> String {
        return """
        System Prompt:
        Do not use thinking tokens.
        You are a strict but fair grader for an elementary school tutor.
        Note: the student may answer in any language — accept linguistically-equivalent answers across languages (e.g. "8" / "eight" / "ocho" / "huit"). Output only the JSON verdict — no prose.

        User Prompt:
        Question: "\(problem.prompt)"
        Expected answer: "\(problem.answer)"
        Student's answer: "\(studentAnswer)"

        Decide if the student's answer is CORRECT for this question. Be flexible
        about phrasing, capitalization, equivalent forms (e.g. "eight" = "8",
        "1/2" = "one half" = "half", "the desert" = "desert"), small typos, and
        extra explanation around the right answer. Be strict about meaning —
        a wrong number or wrong concept is not correct.

        Output ONLY a JSON object inside ```json fences:
        {"correct": true}    // or false

        ```json
        """
    }

    // MARK: Coaching (free-text, no JSON)

    /// Short, kind nudge after a wrong answer. Diagnoses the likely
    /// misconception from the kid's actual answer and gives ONE small step
    /// — does not give the answer outright.
    static func coach(
        _ ctx: LessonContext,
        problem: LessonProblem,
        studentAnswer: String,
        attempt: Int,
        onStream: @escaping (String) -> Void = { _ in }
    ) async -> String? {
        // Build the prompt on the caller's actor so we don't have to send
        // the full LessonContext / StarNode across the queue actor boundary.
        let prompt = buildCoachingPrompt(
            ctx, problem: problem, studentAnswer: studentAnswer, attempt: attempt
        )
        return await LessonGeneratorQueue.shared.run {
            await runFreeText(prompt: prompt, onStream: onStream)
        }
    }

    // MARK: Deeper hint (tiered hints, second tap)

    /// Tier-2 hint: stronger nudge than the static hint, but never reveals
    /// the answer. Used when the kid taps "deeper hint."
    static func deeperHint(
        _ ctx: LessonContext,
        problem: LessonProblem,
        onStream: @escaping (String) -> Void = { _ in }
    ) async -> String? {
        let prompt = buildDeeperHintPrompt(ctx, problem: problem)
        return await LessonGeneratorQueue.shared.run {
            await runFreeText(prompt: prompt, onStream: onStream)
        }
    }

    // MARK: Walk-through (after max attempts)

    static func walkThrough(
        _ ctx: LessonContext,
        problem: LessonProblem,
        studentAnswer: String,
        onStream: @escaping (String) -> Void = { _ in }
    ) async -> String? {
        let prompt = buildWalkThroughPrompt(
            ctx, problem: problem, studentAnswer: studentAnswer
        )
        return await LessonGeneratorQueue.shared.run {
            await runFreeText(prompt: prompt, onStream: onStream)
        }
    }

    private static func runFreeText(
        prompt: String,
        onStream: @escaping (String) -> Void
    ) async -> String? {
        guard let raw = try? await streamAll(prompt: prompt, onStream: onStream) else {
            return nil
        }
        return cleanFreeText(stripThoughts(raw))
    }

    // MARK: - Prompt building

    private static func contextBlock(_ ctx: LessonContext) -> String {
        var lines: [String] = []
        if let c = ctx.course { lines.append("Course: \(c)") }
        if let n = ctx.constellationName { lines.append("Constellation: \(n)") }
        if let b = ctx.blurb { lines.append("Theme: \(b)") }
        if !ctx.siblingLabels.isEmpty {
            lines.append("Nearby skills: \(ctx.siblingLabels.joined(separator: ", "))")
        }
        var block = lines.isEmpty ? "" : lines.joined(separator: "\n") + "\n"
        let mem = ctx.memory.trimmingCharacters(in: .whitespacesAndNewlines)
        if !mem.isEmpty {
            block += """

            What you remember about this student (use to personalize, do not quote verbatim):
            ---
            \(mem)
            ---

            """
        }
        return block
    }

    private static func buildOpeningPrompt(_ ctx: LessonContext) -> String {
        return """
        System Prompt:
        Do not use thinking tokens.
        You are Nova, a warm tutor for elementary kids. Use simple words and short sentences.
        \(languageDirective())

        User Prompt:
        Write the OPENING of a tiny lesson on "\(ctx.node.label)" \(ctx.node.emoji).
        \(contextBlock(ctx))
        Output ONLY a JSON object inside ```json fences:
        {
          "intro": "1-2 friendly sentences explaining the big idea about \(ctx.node.label).",
          "example": {
            "question": "A worked-example question kids see Nova solve first.",
            "answer": "the short answer to that example",
            "viz": "tiny emoji or text visualization, max 24 chars"
          }
        }

        Rules:
        - Intro must be specifically about \(ctx.node.label), not generic.
        - Example answer: a single number or single word (max 2 words), lowercase preferred.
        - No markdown outside the json fence. No commentary.

        ```json
        """
    }

    private static func buildProblemPrompt(
        _ ctx: LessonContext,
        history: [PastProblemOutcome],
        index: Int,
        total: Int
    ) -> String {
        let position = "Problem \(index + 1) of \(total)"

        // History block — empty for the first problem.
        var historyLines = ""
        if !history.isEmpty {
            var lines: [String] = []
            for (i, h) in history.enumerated() {
                let outcome = h.correct
                    ? "got it right after \(h.attempts) attempt\(h.attempts == 1 ? "" : "s")\(h.hintUsed ? " (used hint)" : "")"
                    : "did NOT get it; their final answer was \"\(h.studentAnswer)\""
                lines.append("- Q\(i + 1): \"\(h.prompt)\" → answer was \"\(h.correctAnswer)\". Student \(outcome).")
            }
            historyLines = """
            How the student is doing so far:
            \(lines.joined(separator: "\n"))

            """
        }

        // Adaptive guidance the model can act on. For problem #1 we read the BKT
        // model's predicted mastery — this is the cross-session signal that lets
        // a returning student skip warm-up basics they already know.
        let adaptHint: String = {
            if history.isEmpty {
                let priorMastery = BKTPipeline.estimatedMastery(for: ctx.node.id)
                let pct = Int(priorMastery * 100)
                let isFirst = BKTMastery.shared.mastery(for: ctx.node.id) == nil
                let forgot = BKTMastery.shared.forgetProbability(for: ctx.node.id) ?? 0
                if !isFirst && forgot >= 0.25 {
                    return "BKT says the student knew this before but probably forgot (forgetting ~\(Int(forgot*100))%). Pick a gentle refresher problem covering the core idea — same difficulty as their first successful past attempt, not harder."
                }
                if priorMastery >= 0.7 {
                    return "BKT says the student already shows STRONG mastery of this topic (\(pct)% prior). Skip easy basics — pick a harder application problem or a small twist to confirm depth."
                }
                if priorMastery <= 0.3 {
                    return "BKT prior is LOW (\(pct)%). Pick a very gentle, concrete problem at the easier end of the grade band. Build confidence first."
                }
                return "BKT prior is mid-range (\(pct)%). Pick a clear, central diagnostic question at the easier end of the grade band so we can calibrate the rest of the lesson."
            }
            let recentWrongs = history.suffix(2).filter { !$0.correct }.count
            let recentRights = history.suffix(2).filter { $0.correct }.count
            if history.count == 1 {
                // Right after the diagnostic probe — react to it firmly.
                if let probe = history.first {
                    if probe.correct && probe.attempts == 1 {
                        return "The diagnostic showed they GET this — push noticeably harder, into application or a small twist."
                    } else if !probe.correct {
                        return "The diagnostic showed they're shaky — reinforce the same core idea with a more concrete, easier framing."
                    }
                }
            }
            if recentWrongs >= 2 { return "They've struggled — reinforce the SAME core idea with a slightly easier framing." }
            if recentRights >= 2 { return "They're cruising — push the difficulty up a notch." }
            return "Calibrate the difficulty based on how they did above."
        }()

        return """
        System Prompt:
        Do not use thinking tokens.
        You are Nova, a warm adaptive tutor for elementary kids. You generate ONE next
        problem at a time, tailored to how the student has done so far.
        \(languageDirective())

        User Prompt:
        You are running a lesson on "\(ctx.node.label)" \(ctx.node.emoji).
        \(contextBlock(ctx))
        \(position).

        \(historyLines)Guidance for this problem: \(adaptHint)

        Output ONLY a JSON object inside ```json fences:
        {
          "prompt": "Q\(index + 1) prompt — under 18 words. Stays strictly on \(ctx.node.label).",
          "answer": "single number OR single word (max 2 words), lowercase preferred",
          "hint": "a short helpful hint, under 14 words"
        }

        Rules:
        - Question must be about \(ctx.node.label) specifically — do not drift.
        - Do NOT repeat any past prompt.
        - Answer must be unambiguous: one number or one common word.
        - No markdown outside the json fence. No commentary.

        ```json
        """
    }

    private static func buildCoachingPrompt(
        _ ctx: LessonContext,
        problem: LessonProblem,
        studentAnswer: String,
        attempt: Int
    ) -> String {
        let cross: String = {
            // Sibling-skill bridge: occasionally relate the wrong answer to a
            // mastered nearby skill the kid has succeeded on.
            guard !ctx.siblingLabels.isEmpty else { return "" }
            let siblings = ctx.siblingLabels.prefix(4).joined(separator: ", ")
            return "If natural, relate this to a nearby skill they've already met (\(siblings))."
        }()

        let memoryHint: String = {
            let m = ctx.memory.trimmingCharacters(in: .whitespacesAndNewlines)
            return m.isEmpty ? "" : """


            What you remember about this student (use to personalize):
            ---
            \(m)
            ---
            """
        }()

        return """
        System Prompt:
        Do not use thinking tokens.
        You are Nova, a kind, encouraging tutor for elementary kids.
        \(languageDirective())

        User Prompt:
        The student is learning "\(ctx.node.label)" \(ctx.node.emoji).
        Question: "\(problem.prompt)"
        Correct answer: "\(problem.answer)"
        Student answered: "\(studentAnswer)"
        This was attempt #\(attempt).\(memoryHint)

        Reply with 1-2 short kid-friendly sentences that:
        1. Diagnose the likely misconception from their actual answer.
        2. Give ONE specific small step or rephrased clue — DO NOT reveal the answer.
        3. End with a warm encouragement to try again.
        \(cross)

        Reply with ONLY the message text. No JSON, no quotes, no markdown.
        """
    }

    private static func buildDeeperHintPrompt(
        _ ctx: LessonContext,
        problem: LessonProblem
    ) -> String {
        return """
        System Prompt:
        Do not use thinking tokens.
        You are Nova, a kind tutor for elementary kids.
        \(languageDirective())

        User Prompt:
        The student is stuck on this problem about "\(ctx.node.label)" \(ctx.node.emoji).
        Question: "\(problem.prompt)"
        Correct answer: "\(problem.answer)"

        They already saw this short hint: "\(problem.hint)"
        That wasn't enough. Give them a STRONGER hint without revealing the answer.

        Write 1-2 short kid-friendly sentences that:
        1. Walk them ONE step closer to the answer (e.g. narrow the range, show
           a tiny example, point at which operation to try first).
        2. Explicitly do NOT say or spell out the answer "\(problem.answer)".
        3. End by inviting them to try again.

        Reply with ONLY the message text. No JSON, no quotes, no markdown.
        """
    }

    private static func buildWalkThroughPrompt(
        _ ctx: LessonContext,
        problem: LessonProblem,
        studentAnswer: String
    ) -> String {
        return """
        System Prompt:
        Do not use thinking tokens.
        You are Nova, a kind, patient tutor for elementary kids.
        \(languageDirective())

        User Prompt:
        The student tried this problem about "\(ctx.node.label)" \(ctx.node.emoji) but
        couldn't get it after a few tries.
        Question: "\(problem.prompt)"
        Correct answer: "\(problem.answer)"
        Their last answer: "\(studentAnswer)"

        Write 2-3 short sentences for an elementary kid that:
        1. Give the answer plainly (\(problem.answer)).
        2. Briefly explain WHY in simple words.
        3. End with "Let's try the next one!" so we can move on.

        Reply with ONLY the message text. No JSON, no quotes, no markdown.
        """
    }

    // MARK: - Streaming bridge

    private static func streamAll(
        prompt: String,
        onStream: @escaping (String) -> Void
    ) async throws -> String {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
            var latest = ""
            // Lesson generation produces structured JSON or backstage prose
            // — never speak it. Chat surfaces (NovaAITab / lesson-chat) talk
            // through RAGPipeline instead, which keeps TTS on.
            runModel(
                prompt: prompt,
                onDownload: { _ in },
                onStream: { text in
                    latest = text
                    DispatchQueue.main.async { onStream(text) }
                },
                onComplete: { error in
                    if let error = error { cont.resume(throwing: error) }
                    else { cont.resume(returning: latest) }
                },
                speak: false
            )
        }
    }

    // MARK: - Output cleanup

    /// Removes `<|channel>thought ... <channel|>` blocks (matching NovaAITab).
    private static func stripThoughts(_ input: String) -> String {
        var text = input
        while let start = text.range(of: "<|channel>thought") {
            if let end = text.range(of: "<channel|>", range: start.upperBound..<text.endIndex) {
                text.removeSubrange(start.lowerBound..<end.upperBound)
            } else {
                text.removeSubrange(start.lowerBound..<text.endIndex)
                break
            }
        }
        return text
    }

    /// Strips wrapping fences/quotes the model sometimes adds to free-text.
    private static func cleanFreeText(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("```") {
            // remove any opening ```lang line
            if let nl = t.firstIndex(of: "\n") {
                t = String(t[t.index(after: nl)...])
            }
        }
        if t.hasSuffix("```") {
            t.removeLast(3)
            t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if t.hasPrefix("\"") && t.hasSuffix("\"") && t.count >= 2 {
            t.removeFirst(); t.removeLast()
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Finds the first `{` and the matching closing `}` (depth-tracked, ignoring
    /// braces inside double-quoted strings).
    private static func extractJSONObject(from text: String) -> String? {
        guard let startIdx = text.firstIndex(of: "{") else { return nil }
        var depth = 0
        var inString = false
        var escape = false
        var i = startIdx
        while i < text.endIndex {
            let c = text[i]
            if escape { escape = false }
            else if c == "\\" && inString { escape = true }
            else if c == "\"" { inString.toggle() }
            else if !inString {
                if c == "{" { depth += 1 }
                else if c == "}" {
                    depth -= 1
                    if depth == 0 {
                        let endIdx = text.index(after: i)
                        return String(text[startIdx..<endIdx])
                    }
                }
            }
            i = text.index(after: i)
        }
        return nil
    }
}
