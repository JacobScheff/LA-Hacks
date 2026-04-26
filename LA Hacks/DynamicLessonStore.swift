//
//  DynamicLessonStore.swift
//  LA Hacks
//
//  Created by Yirui Song on 4/26/26.
//
//  Bridges LessonGenerator.swift → LessonContent for any StarNode.
//  Grounded in uploaded curriculum via CurriculumStore → MemoryStore.
//
//  Compatible with updated GalaxyData:
//    • StarNode has initiallyLocked (not status/mastery)
//    • MasteryStage replaces StarStatus
//    • UserSettings.shared.stage() computes live mastery
//
//  Files it depends on (unchanged):
//    LessonGenerator.swift   — generateOpening / generateProblem / LessonContext
//    ModelIntegration.swift  — RAGPipeline, PipelineContext
//    CurriculumStore.swift   — MemoryStore.allRAGWindows()
//    LessonView.swift        — LessonContent, LessonProblem, lessonFor()
//

import Foundation
import Combine
import NaturalLanguage

// MARK: - Load state

enum LessonLoadState {
    case idle
    case generatingOpening
    case generatingProblems(done: Int, total: Int)
    case ready(LessonContent)
    case failed
}

// MARK: - Store

@MainActor
final class DynamicLessonStore: ObservableObject {

    static let shared = DynamicLessonStore()
    private init() {}

    private var cache: [String: LessonContent] = [:]
    private var inFlight: Set<String> = []

    // MARK: - Route decision

    /// Generated stars (gen- prefix) always use AI.
    /// Static stars with full hand-written cases in lessonFor() skip generation.
    func needsGeneration(for node: StarNode) -> Bool {
        node.id.hasPrefix("gen-") || !hardcodedIDs.contains(node.id)
    }

    /// Every star ID that has a real (non-default) case in lessonFor().
    /// Matches the exhaustive switch in LessonView.swift.
    private let hardcodedIDs: Set<String> = [
        // Numbers
        "count","place","add","sub","mul","div","odd",
        // Fractions
        "half","frac","equiv","compare","addfrac","mixed","simplify","word",
        // Geometry
        "tri","sq","circ","poly","sym","angle","area","vol",
        // Time & Money
        "clock","min","cal","elapsed","rasalas","algenubi","coins","change","dollar",
        // Reading
        "phon","sight","flu","main","detail","infer","theme",
        // Writing
        "caps","noun","sent","adj","para","story","opin","edit",
        // Life Science
        "living","plant","animal","habitat","food","cycle","eco","photo","zeta","shaula","lesath",
        // Earth & Space
        "sun","season","weather","water","rocks","planet","gravity","galaxy",
        // History
        "ancient","rastaban","maps","nu","native","explor","colony","rev","gov","civil","tail",
    ]

    // MARK: - Static lesson passthrough

    /// Calls through to LessonView.swift's top-level lessonFor() for hardcoded stars.
    static func staticLesson(for node: StarNode) -> LessonContent {
        lessonFor(node: node)
    }

    // MARK: - Load (called by LessonLoader)

    func load(
        node: StarNode,
        constellationName: String,
        course: String,
        blurb: String?,
        siblingLabels: [String],
        onState: @escaping (LessonLoadState) -> Void,
        onStream: @escaping (String) -> Void
    ) {
        // 1. Cache hit — instant
        if let cached = cache[node.id] {
            onState(.ready(cached)); return
        }

        // 2. Hardcoded static lesson — no generation needed
        if !needsGeneration(for: node) {
            onState(.ready(DynamicLessonStore.staticLesson(for: node))); return
        }

        // 3. Deduplicate in-flight requests
        guard !inFlight.contains(node.id) else {
            pollCache(starID: node.id, onState: onState); return
        }

        inFlight.insert(node.id)
        onState(.generatingOpening)

        let ctx = buildContext(
            node: node,
            constellationName: constellationName,
            course: course,
            blurb: blurb,
            siblingLabels: siblingLabels
        )

        Task {
            let content = await generateFull(
                ctx: ctx, node: node,
                onState: onState,
                onStream: onStream
            )
            cache[node.id] = content
            inFlight.remove(node.id)
            onState(.ready(content))
        }
    }

    // MARK: - Pre-generation (fire-and-forget after UploadModal)

    /// Call right after buildGenerationResult() so lessons are cached before
    /// the student taps a generated star.
    ///
    ///   // In your onGenerate closure:
    ///   let allNewNodes = outcome.addedNodes + (outcome.newConstellation?.nodes ?? [])
    ///   DynamicLessonStore.shared.pregenerate(
    ///       nodes: allNewNodes,
    ///       constellationName: outcome.newConstellation?.name ?? "New Stars",
    ///       course: outcome.newConstellation?.course ?? "",
    ///       blurb: outcome.newConstellation?.blurb,
    ///       siblingLabels: allNewNodes.map(\.label)
    ///   )
    func pregenerate(
        nodes: [StarNode],
        constellationName: String,
        course: String,
        blurb: String? = nil,
        siblingLabels: [String] = []
    ) {
        for node in nodes {
            guard cache[node.id] == nil, !inFlight.contains(node.id) else { continue }
            inFlight.insert(node.id)

            let ctx = buildContext(
                node: node,
                constellationName: constellationName,
                course: course,
                blurb: blurb,
                siblingLabels: siblingLabels
            )

            Task {
                let content = await generateFull(
                    ctx: ctx, node: node,
                    onState: { _ in },
                    onStream: { _ in }
                )
                await MainActor.run {
                    self.cache[node.id] = content
                    self.inFlight.remove(node.id)
                    print("[DynamicLessonStore] ✦ pre-generated '\(node.label)'")
                }
            }
        }
    }

    // MARK: - Context builder

    private func buildContext(
        node: StarNode,
        constellationName: String,
        course: String,
        blurb: String?,
        siblingLabels: [String]
    ) -> LessonContext {
        let ragMemory = topCurriculumWindows(for: node, constellationName: constellationName)

        // BKT snapshot — mastery, forgetting, prereqs, misconceptions for this star.
        // The LLM uses this to calibrate the example, problem difficulty, and
        // misconception watchlist.
        let bktBlock = BKTPipeline.hints(for: node.id).promptSection()

        let studentMemory = MemoryStore.shared.contextForPrompt()

        var parts: [String] = []
        parts.append(bktBlock)
        if !ragMemory.isEmpty {
            parts.append("## 📚 Relevant Uploaded Curriculum\n\(ragMemory)")
        }
        if !studentMemory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("## 🧠 Student History\n\(studentMemory)")
        }

        return LessonContext(
            node: node,
            constellationName: constellationName,
            course: course,
            blurb: blurb,
            siblingLabels: siblingLabels,
            memory: parts.joined(separator: "\n\n")
        )
    }

    /// Scores all curriculum windows against the star label + constellation name
    /// and returns the top 3 joined as a single string for LessonContext.memory.
    private func topCurriculumWindows(for node: StarNode, constellationName: String) -> String {
        let windows = MemoryStore.shared.allRAGWindows()
        guard !windows.isEmpty else { return "" }

        let query = "\(node.label) \(constellationName) \(node.emoji)"
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = query.lowercased()
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: query.startIndex..<query.endIndex) { r, _ in
            tokens.append(query[r].lowercased()); return true
        }

        let stopwords: Set<String> = [
            "a","an","the","is","are","do","how","what","i","me","of","to","and","or","in","it"
        ]
        let filtered = tokens.filter { !stopwords.contains($0) && $0.count > 1 }
        guard !filtered.isEmpty else { return "" }

        return windows
            .map { w -> (String, Int) in
                let lower = w.lowercased()
                return (w, filtered.filter { lower.contains($0) }.count)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map(\.0)
            .joined(separator: "\n\n---\n\n")
    }

    // MARK: - Full generation sequence

    private func generateFull(
        ctx: LessonContext,
        node: StarNode,
        onState: @escaping (LessonLoadState) -> Void,
        onStream: @escaping (String) -> Void
    ) async -> LessonContent {
        let total = LessonConfig.problemCount

        // Step 1: Opening (intro + example)
        guard let opening = await LessonGenerator.generateOpening(ctx, onStream: onStream) else {
            print("[DynamicLessonStore] ⚠️ opening failed for '\(node.label)'")
            return Self.fallback(for: node)
        }

        // Step 2: Problems (adaptive per LessonGenerator)
        var problems: [LessonProblem] = []
        var history: [PastProblemOutcome] = []

        for i in 0..<total {
            await MainActor.run {
                onState(.generatingProblems(done: i, total: total))
            }

            guard let problem = await LessonGenerator.generateProblem(
                ctx,
                history: history,
                index: i,
                total: total,
                onStream: onStream
            ) else {
                print("[DynamicLessonStore] ⚠️ problem \(i+1) failed for '\(node.label)'")
                let padding = Self.fallback(for: node).problems.dropFirst(problems.count)
                problems.append(contentsOf: padding)
                break
            }
            problems.append(problem)
        }

        return LessonContent(
            intro: opening.intro,
            exampleQuestion: opening.exampleQuestion,
            exampleAnswer: opening.exampleAnswer,
            exampleViz: opening.exampleViz,
            problems: problems.isEmpty ? Self.fallback(for: node).problems : problems
        )
    }

    // MARK: - Fallback

    static func fallback(for node: StarNode) -> LessonContent {
        let label = node.label
        let first = label.components(separatedBy: " ").first ?? label
        let letterCount = String(first.filter(\.isLetter).count)
        return LessonContent(
            intro: "Let's explore \(label) \(node.emoji) together! I'll walk you through it step by step. 🚀",
            exampleQuestion: "Can you think of one example of \(label) from real life?",
            exampleAnswer: "Great thinking! Any answer relating to \(label) works.",
            exampleViz: node.emoji,
            problems: [
                .mc("Which word best describes \(label)?",
                    choices: ["Learning","Growing","Exploring","Building"],
                    answer: "Learning", hint: "We're all here to learn!"),
                .mc("Where would you look to learn more about \(label)?",
                    choices: ["A book","Ask a friend","Try it out","All of these!"],
                    answer: "All of these!", hint: "Great learners use every tool!"),
                .input("Write one word you think of for '\(label)':",
                       answer: first.lowercased(), hint: "First word that comes to mind."),
                .input("How many letters in '\(first)'?",
                       answer: letterCount, hint: "Count each letter one by one."),
            ]
        )
    }

    // MARK: - Cache management

    func clearCache(for starID: String) { cache.removeValue(forKey: starID) }
    func clearAllGenerated() { cache.keys.filter { $0.hasPrefix("gen-") }.forEach { cache.removeValue(forKey: $0) } }

    // MARK: - Poll helper

    private func pollCache(starID: String, onState: @escaping (LessonLoadState) -> Void) {
        Task {
            for _ in 0..<60 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                if let cached = cache[starID] { onState(.ready(cached)); return }
            }
            onState(.failed)
        }
    }
}

// MARK: - LessonLoader (ObservableObject used by LessonView via @StateObject)

@MainActor
final class LessonLoader: ObservableObject {

    @Published var state: LessonLoadState = .idle
    @Published var streamPreview: String = ""

    func load(
        node: StarNode,
        constellationName: String,
        course: String,
        blurb: String? = nil,
        siblingLabels: [String] = []
    ) {
        guard case .idle = state else { return }

        // Static stars with full hand-written lessons skip async entirely
        if !DynamicLessonStore.shared.needsGeneration(for: node) {
            state = .ready(DynamicLessonStore.staticLesson(for: node))
            return
        }

        state = .generatingOpening

        DynamicLessonStore.shared.load(
            node: node,
            constellationName: constellationName,
            course: course,
            blurb: blurb,
            siblingLabels: siblingLabels,
            onState: { [weak self] newState in
                self?.state = newState
            },
            onStream: { [weak self] text in
                self?.streamPreview = String(text.suffix(120))
                if case .ready = self?.state { self?.streamPreview = "" }
            }
        )
    }

    var lessonContent: LessonContent? {
        if case .ready(let c) = state { return c }
        return nil
    }

    var progressLabel: String {
        switch state {
        case .idle:                              return ""
        case .generatingOpening:                 return "Nova is preparing your lesson… ✨"
        case .generatingProblems(let d, let t):  return "Building questions… \(d)/\(t)"
        case .ready:                             return ""
        case .failed:                            return "Generation failed"
        }
    }
}
