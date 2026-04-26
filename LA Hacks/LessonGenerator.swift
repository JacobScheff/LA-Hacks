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

// MARK: - Generator

enum LessonGenerator {

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

        // Adaptive guidance the model can act on.
        let adaptHint: String = {
            if history.isEmpty {
                return """
                This is a DIAGNOSTIC PROBE — the very first problem of the lesson. Pick \
                a clear, central question for the topic at the EASIER end of the grade \
                band. The student's answer here calibrates the rest of the lesson. \
                Avoid edge cases or trick framings.
                """
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
                }
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
