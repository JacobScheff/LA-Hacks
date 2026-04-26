//
//  DynamicLessonStore.swift
//  LA Hacks
//
//  Created by Yirui Song on 4/26/26.
//
//  Bridges LessonGenerator.swift → LessonContent so LessonView can load
//  AI-generated lessons for any StarNode, grounded in uploaded curriculum.
//
//  How it connects the existing pieces:
//
//    CurriculumStore  →  MemoryStore.allRAGWindows()
//         ↓ top-3 windows most relevant to the star
//    LessonContext.memory  (fed into every LessonGenerator prompt)
//         ↓
//    LessonGenerator.generateOpening()   →  LessonOpening
//    LessonGenerator.generateProblem() × N  →  [LessonProblem]
//         ↓
//    LessonContent  (same type LessonView already uses)
//         ↓
//    DynamicLessonStore.cache[starID]  (so repeat taps are instant)
//
//  LessonView changes needed (see bottom of this file):
//    1. Add `constellationName` + `course` lets
//    2. Replace `private var lesson` computed property with @StateObject LessonLoader
//    3. Wrap body in a load-state switch
//

import Foundation
import Combine
import NaturalLanguage

// MARK: - Load state (drives LessonView UI)

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

    /// Stars with hand-written cases in lessonFor() skip generation entirely.
    func needsGeneration(for node: StarNode) -> Bool {
        node.id.hasPrefix("gen-") || !hardcodedIDs.contains(node.id)
    }

    private let hardcodedIDs: Set<String> = [
        "add","sub","mul","div","count","place","odd",
        "half","frac","equiv","compare","addfrac","mixed","simplify","word",
        "tri","sq","circ","poly","sym","angle","area","vol",
        "clock","min","cal","elapsed","rasalas","algenubi","coins","change","dollar",
        "phon","sight","flu","main","detail","infer","theme",
        "caps","noun","sent","adj","para","story","opin","edit",
        "living","plant","animal","habitat","food","cycle","eco",
        "sun","season","weather","water","rocks","planet",
        "ancient","rastaban","maps","nu","native","explor","colony","rev",
    ]

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

        // 2. Hardcoded static lesson — no generation
        if !needsGeneration(for: node) {
            onState(.ready(DynamicLessonStore.staticLesson(for: node))); return
        }

        // 3. Deduplicate in-flight
        guard !inFlight.contains(node.id) else {
            pollCache(starID: node.id, onState: onState); return
        }

        inFlight.insert(node.id)
        onState(.generatingOpening)

        // Build LessonContext — key step: inject curriculum RAG windows as memory
        let ctx = buildContext(
            node: node,
            constellationName: constellationName,
            course: course,
            blurb: blurb,
            siblingLabels: siblingLabels
        )

        Task {
            let content = await generateFull(ctx: ctx, node: node, onState: onState, onStream: onStream)
            cache[node.id] = content
            inFlight.remove(node.id)
            onState(.ready(content))
        }
    }

    // MARK: - Pre-generation (fire-and-forget after UploadModal)

    /// Call this right after buildGenerationResult() returns so lessons are
    /// cached before the student taps a star.
    ///
    /// In your UploadModal onGenerate closure:
    ///
    ///   let allNewNodes = outcome.addedNodes + (outcome.newConstellation?.nodes ?? [])
    ///   let cname = outcome.newConstellation?.name ?? "New Stars"
    ///   let ccourse = outcome.newConstellation?.course ?? ""
    ///   DynamicLessonStore.shared.pregenerate(nodes: allNewNodes,
    ///                                         constellationName: cname,
    ///                                         course: ccourse)
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
                    cache[node.id] = content
                    inFlight.remove(node.id)
                    print("[DynamicLessonStore] ✦ pre-generated '\(node.label)'")
                }
            }
        }
    }

    // MARK: - Context builder (key: curriculum RAG injection)

    private func buildContext(
        node: StarNode,
        constellationName: String,
        course: String,
        blurb: String?,
        siblingLabels: [String]
    ) -> LessonContext {
        // Pull the top-3 RAG windows from CurriculumStore most relevant to this star
        let ragMemory = topCurriculumWindows(for: node, constellationName: constellationName)

        // BKT snapshot — mastery, forgetting, prereqs, misconceptions for this star.
        // The LLM uses this to calibrate the example, problem difficulty, and
        // misconception watchlist.
        let bktBlock = BKTPipeline.hints(for: node.id).promptSection()

        // Combine uploaded curriculum passages with student memory from MemoryStore
        let studentMemory = MemoryStore.shared.contextForPrompt()
        let combined: String = {
            var parts: [String] = []
            parts.append(bktBlock)
            if !ragMemory.isEmpty {
                parts.append("## 📚 Relevant Uploaded Curriculum\n\(ragMemory)")
            }
            if !studentMemory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                parts.append("## 🧠 Student History\n\(studentMemory)")
            }
            return parts.joined(separator: "\n\n")
        }()

        return LessonContext(
            node: node,
            constellationName: constellationName,
            course: course,
            blurb: blurb,
            siblingLabels: siblingLabels,
            memory: combined
        )
    }

    /// Scores all curriculum windows against the star label + constellation name
    /// and returns the top 3 as a single joined string for injection into memory.
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
        let stopwords: Set<String> = ["a","an","the","is","are","do","how","what","i","me","of","to","and","or","in","it"]
        let filtered = tokens.filter { !stopwords.contains($0) && $0.count > 1 }
        guard !filtered.isEmpty else { return "" }

        let scored = windows.map { w -> (String, Int) in
            let lower = w.lowercased()
            return (w, filtered.filter { lower.contains($0) }.count)
        }
        .filter { $0.1 > 0 }
        .sorted { $0.1 > $1.1 }
        .prefix(3)
        .map(\.0)

        return scored.joined(separator: "\n\n---\n\n")
    }

    // MARK: - Full generation sequence

    /// Uses LessonGenerator's existing per-step API:
    ///   generateOpening → LessonOpening
    ///   generateProblem × LessonConfig.problemCount → [LessonProblem]
    /// Then assembles into LessonContent.
    private func generateFull(
        ctx: LessonContext,
        node: StarNode,
        onState: @escaping (LessonLoadState) -> Void,
        onStream: @escaping (String) -> Void
    ) async -> LessonContent {
        let total = LessonConfig.problemCount

        // ── Step 1: Opening (intro + example) ───────────────────────────────
        guard let opening = await LessonGenerator.generateOpening(ctx, onStream: onStream) else {
            print("[DynamicLessonStore] ⚠️ opening generation failed for '\(node.label)'")
            return fallback(for: node)
        }

        // ── Step 2: Problems (adaptive, conditioned on prior outcomes) ───────
        var problems: [LessonProblem] = []
        var history: [PastProblemOutcome] = []   // empty until we have real outcomes

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
                print("[DynamicLessonStore] ⚠️ problem \(i+1) generation failed for '\(node.label)'")
                // Pad with fallback problems rather than returning a short lesson
                problems.append(contentsOf: fallback(for: node).problems.dropFirst(problems.count))
                break
            }
            problems.append(problem)
            // History stays empty at generation time — no student answers yet.
            // LessonGenerator's adaptive logic will kick in during live lesson
            // replay if you later wire handleAnswer → history tracking.
        }

        let safeProblems = problems.isEmpty ? fallback(for: node).problems : problems

        return LessonContent(
            intro: opening.intro,
            exampleQuestion: opening.exampleQuestion,
            exampleAnswer: opening.exampleAnswer,
            exampleViz: opening.exampleViz,
            problems: safeProblems
        )
    }

    // MARK: - Static lesson passthrough

    /// Calls through to LessonView's lessonFor() for hardcoded stars.
    static func staticLesson(for node: StarNode) -> LessonContent {
        lessonFor(node: node)
    }

    // MARK: - Fallback

    static func fallback(for node: StarNode) -> LessonContent {
        fallbackLesson(for: node)
    }

    private func fallback(for node: StarNode) -> LessonContent {
        DynamicLessonStore.fallback(for: node)
    }

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

// MARK: - Fallback lesson (standalone so DynamicLessonStore.fallback() can call it)

private func fallbackLesson(for node: StarNode) -> LessonContent {
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

// MARK: - LessonLoader (ObservableObject for LessonView)

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

        // Hardcoded stars skip the async path entirely — instant
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
        case .idle:                             return ""
        case .generatingOpening:                return "Nova is preparing your lesson… ✨"
        case .generatingProblems(let d, let t): return "Building questions… \(d)/\(t)"
        case .ready:                            return ""
        case .failed:                           return "Generation failed"
        }
    }
}
