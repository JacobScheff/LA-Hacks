//
//  MemoryStore.swift
//  LA Hacks
//
//  Persistent, plain-markdown memory of the student. The file (`memory.md`)
//  lives in the app's Documents directory because the app bundle is read-only
//  on iOS — at runtime, this is the closest we can get to "near the root of
//  the code."
//
//  Purpose:
//   • After every lesson, append a structured note (date, topic, outcome,
//     mistakes) to the "Recent Lessons" section.
//   • Inject the whole file as background context into every Gemma prompt so
//     Nova "remembers" the kid across sessions — preferences, recurring
//     mistakes, prior wins.
//   • Every LessonConfig.compressEveryN lessons, ask Gemma to rewrite the
//     file: roll older recent-lesson entries up into Profile / Recurring
//     mistakes, and drop stale items.
//

import Foundation
import Combine

// MARK: - Tunables (extends LessonConfig)

extension LessonConfig {
    /// How many lessons go by between memory-compression passes.
    static var compressEveryN: Int = 3

    /// Hard cap on memory file size sent to the LLM as context — older content
    /// is truncated past this byte count to keep prompts manageable.
    static var memoryContextByteCap: Int = 4000
}

// MARK: - Store

@MainActor
final class MemoryStore: ObservableObject {

    static let shared = MemoryStore()

    /// Whole file contents — Markdown. Published so views could observe it.
    @Published private(set) var contents: String = ""

    /// Number of lessons completed since the last compression pass.
    private var lessonsSinceCompress: Int {
        get { UserDefaults.standard.integer(forKey: "memory.lessonsSinceCompress") }
        set { UserDefaults.standard.set(newValue, forKey: "memory.lessonsSinceCompress") }
    }

    private var compressionInFlight = false

    private init() {
        load()
    }

    // MARK: File path

    /// Documents/memory.md — accessible via Xcode's container browser or the
    /// simulator's Files app. Logged on first read so the dev knows where it is.
    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("memory.md")
    }

    // MARK: Read / write

    func load() {
        let url = fileURL
        if FileManager.default.fileExists(atPath: url.path) {
            contents = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        } else {
            contents = Self.starterTemplate()
            persist(contents)
            print("MemoryStore: initialized memory.md at \(url.path)")
        }
    }

    private func persist(_ text: String) {
        let url = fileURL
        try? text.write(to: url, atomically: true, encoding: .utf8)
        contents = text
    }

    /// Returns a trimmed copy suitable for embedding in an LLM prompt.
    /// Keeps the most recent content if the file exceeds the byte cap.
    func contextForPrompt() -> String {
        let raw = contents
        if raw.utf8.count <= LessonConfig.memoryContextByteCap { return raw }
        // Drop oldest content (top portion is profile/style which is hot, but
        // recent-lessons section grows; keep tail).
        let tailCount = LessonConfig.memoryContextByteCap
        let utf8 = Array(raw.utf8)
        let slice = utf8.suffix(tailCount)
        return String(decoding: slice, as: UTF8.self)
    }

    // MARK: Append after a lesson

    /// Appends a note about the just-completed lesson.
    /// Triggers a compression pass every `LessonConfig.compressEveryN` calls.
    func recordLesson(
        node: StarNode,
        constellationName: String?,
        outcomes: [PastProblemOutcome],
        xpGained: Int,
        heartsLeft: Int,
        hintsUsed: Int
    ) async {
        let date = ISO8601DateFormatter.dateOnly.string(from: Date())

        var lines: [String] = []
        lines.append("### \(date) · \(node.emoji) \(node.label)" + (constellationName.map { " (\($0))" } ?? ""))
        let correctCount = outcomes.filter { $0.correct }.count
        lines.append("- Score: \(correctCount)/\(outcomes.count) correct · +\(xpGained) XP · ❤️ \(heartsLeft)/3 · 💡 \(hintsUsed) hint(s)")
        for o in outcomes {
            let mark = o.correct ? "✓" : "✗"
            let detail = o.correct
                ? (o.attempts > 1 ? " (took \(o.attempts) tries)" : "")
                : " — answered \"\(o.studentAnswer)\""
            lines.append("- \(mark) \(o.prompt) → \(o.correctAnswer)\(detail)")
        }
        let note = lines.joined(separator: "\n") + "\n\n"

        // Insert under the "## Recent Lessons" section, newest at top.
        var updated = contents
        if let range = updated.range(of: "## Recent Lessons") {
            let insertIdx = updated.index(range.upperBound, offsetBy: 1, limitedBy: updated.endIndex) ?? updated.endIndex
            updated.insert(contentsOf: "\n" + note, at: insertIdx)
        } else {
            updated += "\n## Recent Lessons\n\n" + note
        }
        persist(updated)

        lessonsSinceCompress += 1
        if lessonsSinceCompress >= LessonConfig.compressEveryN && !compressionInFlight {
            await compress()
        }
    }

    /// Records a single mid-lesson observation worth keeping (e.g., kid said
    /// they prefer dogs, or got frustrated). Currently unused but available.
    func recordObservation(_ line: String) {
        var updated = contents
        let entry = "- \(line)"
        if let r = updated.range(of: "## Profile") {
            let insertIdx = updated.index(r.upperBound, offsetBy: 1, limitedBy: updated.endIndex) ?? updated.endIndex
            updated.insert(contentsOf: "\n" + entry, at: insertIdx)
        } else {
            updated += "\n## Profile\n\n" + entry + "\n"
        }
        persist(updated)
    }

    // MARK: Compression via Gemma

    private func compress() async {
        compressionInFlight = true
        defer { compressionInFlight = false }

        let before = contents
        let prompt = Self.compressionPrompt(currentMemory: before)

        // Run on the same serialization queue as lessons so we don't fight
        // the model.
        let result: String? = await LessonGeneratorQueue.shared.run {
            await Self.streamAllForCompression(prompt: prompt)
        }

        guard let raw = result else {
            print("MemoryStore: compression failed; keeping original.")
            return
        }
        let cleaned = Self.extractMarkdown(raw)
        guard !cleaned.isEmpty, cleaned.count > 80 else {
            print("MemoryStore: compression returned tiny output, ignoring.")
            return
        }
        persist(cleaned)
        lessonsSinceCompress = 0
        print("MemoryStore: compressed memory.md (\(before.count) → \(cleaned.count) chars)")
    }

    private static func streamAllForCompression(prompt: String) async -> String? {
        do {
            return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<String, Error>) in
                var latest = ""
                runModel(
                    prompt: prompt,
                    onDownload: { _ in },
                    onStream: { text in latest = text },
                    onComplete: { error in
                        if let error = error { cont.resume(throwing: error) }
                        else { cont.resume(returning: latest) }
                    }
                )
            }
        } catch {
            print("MemoryStore: model error during compression: \(error)")
            return nil
        }
    }

    private static func compressionPrompt(currentMemory: String) -> String {
        return """
        System Prompt:
        Do not use thinking tokens.
        You are a memory compactor. You rewrite a markdown notes file about a
        student so it stays compact, current, and useful as context for a tutor.

        User Prompt:
        Below is the CURRENT memory file. Rewrite it so it is shorter and more
        useful. Rules:
        - Keep these top-level sections: "# Star Hop Memory", "## Profile",
          "## Recurring Mistakes", "## Strengths", "## Recent Lessons".
        - Summarize the older lessons in "## Recent Lessons" into trends in
          "## Profile" / "## Recurring Mistakes" / "## Strengths".
        - Keep AT MOST the 3 newest entries under "## Recent Lessons" verbatim.
        - Drop stale items (e.g. one-off mistakes the kid hasn't repeated).
        - Use clean concise bullet points. No commentary, no code fences.
        - Keep total length under ~1500 characters.
        - Output ONLY the new markdown file content, starting with "# Star Hop Memory".

        CURRENT MEMORY:
        ---
        \(currentMemory)
        ---

        New compressed memory:
        """
    }

    /// Pulls out the markdown body, dropping any `<|channel>thought` blocks
    /// or wrapping fences the model might add.
    private static func extractMarkdown(_ raw: String) -> String {
        var t = raw
        // Strip thought blocks (same trick as elsewhere).
        while let start = t.range(of: "<|channel>thought") {
            if let end = t.range(of: "<channel|>", range: start.upperBound..<t.endIndex) {
                t.removeSubrange(start.lowerBound..<end.upperBound)
            } else {
                t.removeSubrange(start.lowerBound..<t.endIndex)
                break
            }
        }
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        // Strip wrapping ``` fences if present.
        if t.hasPrefix("```") {
            if let nl = t.firstIndex(of: "\n") {
                t = String(t[t.index(after: nl)...])
            }
        }
        if t.hasSuffix("```") {
            t.removeLast(3)
        }
        // Trim to the first "# Star Hop Memory" header so any preface is dropped.
        if let r = t.range(of: "# Star Hop Memory") {
            t = String(t[r.lowerBound...])
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Starter template

    private static func starterTemplate() -> String {
        return """
        # Star Hop Memory

        _The tutor's running notes about this student. Updated after every lesson; compressed every \(LessonConfig.compressEveryN) lessons._

        ## Profile
        - (no notes yet — Nova will fill these in over time)

        ## Strengths
        -

        ## Recurring Mistakes
        -

        ## Recent Lessons

        """
    }
}

// MARK: - Date helper

private extension ISO8601DateFormatter {
    static let dateOnly: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()
}
