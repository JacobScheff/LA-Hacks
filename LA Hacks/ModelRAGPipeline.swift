//
//  ModelIntegration.swift
//  LA Hacks
//
//  Created by Yirui Song on 4/25/26.
//
//

import Foundation
import NaturalLanguage
import Security

// MARK: - Supporting Types

struct RAGChunk {
    let constellationID: String
    let constellationName: String
    let starID: String
    let starLabel: String
    let course: String
    let blurb: String
    let skyStory: String
    let relevanceScore: Float
}

struct ChatMessage: Identifiable {
    enum Role { case user, assistant }
    let id: UUID = UUID()
    let role: Role
    let content: String
}

struct PipelineContext {
    var activeConstellationID: String?
    var activeStarID: String?
    var studentName: String = "Explorer"
    var history: [ChatMessage] = []
}

struct PipelineResult {
    enum Status { case success, filteredByGuard, modelError }
    let text: String
    let status: Status
    let ragChunksUsed: [RAGChunk]
    let error: Error?
}

// MARK: - RAGRetriever

enum RAGRetriever {

    private static let maxChunks = 5   // bumped from 3 to make room for curriculum hits

    static func retrieve(query: String, context: PipelineContext) -> [RAGChunk] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = query

        var queryTokens: [String] = []
        tokenizer.enumerateTokens(in: query.startIndex..<query.endIndex) { tokenRange, _ in
            queryTokens.append(query[tokenRange].lowercased())
            return true
        }

        var scored: [(chunk: RAGChunk, score: Float)] = []

        // ── 1. Galaxy graph nodes (original source) ──────────────────────────
        for constellation in GalaxyData.constellations {
            for star in constellation.nodes {
                let score = galaxyScore(
                    tokens: queryTokens,
                    constellation: constellation,
                    star: star,
                    context: context
                )
                guard score > 0 else { continue }
                scored.append((
                    RAGChunk(
                        constellationID: constellation.id,
                        constellationName: constellation.name,
                        starID: star.id,
                        starLabel: star.label,
                        course: constellation.course,
                        blurb: constellation.blurb,
                        skyStory: constellation.skyStory,
                        relevanceScore: score
                    ),
                    score
                ))
            }
        }

        // ── 2. Scanned curriculum windows from MemoryStore ───────────────────
        // Each window is a plain-text string produced by CurriculumChunk.ragChunks().
        // We score them with simple keyword overlap and inject the top hits as
        // synthetic RAGChunk objects so the existing prompt-builder handles them.
        let stopwords: Set<String> = [
            "a","an","the","is","are","do","how","what","i","me","my","of","to","and","or","in","it"
        ]
        let significantTokens = queryTokens.filter { !stopwords.contains($0) }

        for (idx, window) in MemoryStore.shared.allRAGWindows().enumerated() {
            let lower = window.lowercased()
            let hits = significantTokens.filter { lower.contains($0) }
            guard !hits.isEmpty else { continue }

            var score = Float(hits.count)
            // Small recency bonus — windows at lower index are from newer scans
            score += max(0, Float(5 - idx)) * 0.2

            scored.append((
                RAGChunk(
                    constellationID: "curriculum",
                    constellationName: "Uploaded Curriculum",
                    starID: "scan-window-\(idx)",
                    starLabel: "Document Window \(idx + 1)",
                    course: "Curriculum",
                    blurb: String(window.prefix(300)),   // blurb = first 300 chars of window
                    skyStory: window,                    // full window text for prompt injection
                    relevanceScore: score
                ),
                score
            ))
        }

        return scored
            .sorted { $0.score > $1.score }
            .prefix(maxChunks)
            .map(\.chunk)
    }

    // MARK: - Galaxy scoring (unchanged logic)

    private static func galaxyScore(
        tokens: [String],
        constellation: Constellation,
        star: StarNode,
        context: PipelineContext
    ) -> Float {
        let target = [
            star.label,
            constellation.name,
            constellation.blurb,
            constellation.skyStory,
            constellation.course
        ].joined(separator: " ").lowercased()

        let stopwords: Set<String> = [
            "a","an","the","is","are","do","how","what","i","me","my","of","to","and","or","in","it"
        ]
        let matchCount = tokens.filter { !stopwords.contains($0) && target.contains($0) }.count
        var score = Float(matchCount)

        if constellation.id == context.activeConstellationID { score += 2.0 }
        if star.id == context.activeStarID { score += 3.0 }

        return score
    }
}

// MARK: - RAGPipeline

enum RAGPipeline {

    // MARK: - System Prompt

    private static func buildSystemPrompt(chunks: [RAGChunk], context: PipelineContext) -> String {
        var prompt = """
        Role: You are "Nova," a friendly, high-energy, and patient AI tutor for elementary school students (ages 6–11). Your mission is to help students understand their schoolwork using the documents they upload.
        Tone & Personality:
        * Encouraging: Use phrases like "You've got this!", "Great try!", and "We're becoming experts together!"
        * Simple: Use short sentences. Avoid "big" academic words unless you are defining them.
        * Fun: Use occasional emojis (like 🚀, ✨, 🍎) and relatable analogies (e.g., comparing gravity to invisible glue).
        * Resilient: If a student gets an answer wrong, never say "That is incorrect." Instead, say "That was a super guess! Let's look at it another way."
        Core Guidelines:
        1. Reference the File: Use the uploaded curriculum as your "Source of Truth." If a student asks something not in the file, answer generally but try to bring it back to their schoolwork.
        2. The "Check-In" Rule: After explaining a small concept, ask a quick, fun question to make sure the student is following.
        3. Frustration Detection: If the student says "I don't know," "this is hard," or uses sad emojis, stop the lesson. Offer a "Brain Break" or a funny fact before trying a simpler explanation.
        4. Conciseness: Never write more than 3–4 sentences at a time. Elementary students lose focus with "walls of text."
        Interaction Style:
        * Step-by-Step: Don't give the whole answer at once. Lead the student to the answer by asking guiding questions.
        Formatting: Use bolding for important vocabulary words. Use bullet points for lists.

        The student's name is \(context.studentName). 🌟
        """

        // ── Scanned curriculum (highest priority — real uploaded schoolwork) ──
        let curriculumContext = MemoryStore.shared.curriculumContextForPrompt()
        if !curriculumContext.isEmpty {
            prompt += "\n\n\(curriculumContext)"
            prompt += "\n⚠️ When a question relates to the uploaded curriculum above, ALWAYS use it as your primary source. Quote specific details when helpful.\n"
        }

        // ── Galaxy graph RAG chunks ───────────────────────────────────────────
        // Separate curriculum hits (already injected above) from galaxy hits
        let galaxyChunks = chunks.filter { $0.constellationID != "curriculum" }
        let curriculumHits = chunks.filter { $0.constellationID == "curriculum" }

        if !galaxyChunks.isEmpty {
            prompt += "\n\n## 🌌 Galaxy Knowledge\n"
            for chunk in galaxyChunks {
                prompt += """
                Subject: \(chunk.course)
                Topic: \(chunk.constellationName) — \(chunk.starLabel)
                Summary: \(chunk.blurb)
                Story: \(chunk.skyStory)

                """
            }
        }

        // Curriculum RAG hits = the matched windows from the student's scan.
        // Injected here as extra grounding even though the full curriculum
        // block is already above — these are the *most relevant* passages.
        if !curriculumHits.isEmpty {
            prompt += "\n\n## 📄 Most Relevant Curriculum Passages (matched to this question)\n"
            for hit in curriculumHits {
                prompt += "---\n\(hit.skyStory)\n"
            }
        }

        // ── Active focus ─────────────────────────────────────────────────────
        if let constellationID = context.activeConstellationID {
            prompt += "\nThe student is currently studying: \(constellationID)"
            if let starID = context.activeStarID {
                prompt += ", specifically: \(starID)"
            }
            prompt += ". Try to relate your answer back to this topic.\n"
        }

        // ── Conversation history ─────────────────────────────────────────────
        if !context.history.isEmpty {
            prompt += "\n## Recent Conversation\n"
            for message in context.history.suffix(6) {
                let roleLabel = message.role == .user ? context.studentName : "Nova"
                prompt += "\(roleLabel): \(message.content)\n"
            }
        }

        // ── Student memory (past lessons, preferences, mistakes) ─────────────
        let memContext = MemoryStore.shared.contextForPrompt()
        if !memContext.isEmpty {
            prompt += "\n## 🧠 Student Memory\n\(memContext)\n"
        }

        prompt += "\nNow respond to \(context.studentName)'s message below. Remember: 3–4 sentences max! 🚀\n"
        return prompt
    }

    // MARK: - Run

    static func run(
        userQuery: String,
        context: PipelineContext,
        onDownload: @escaping (Float) -> Void,
        onStream: @escaping (String) -> Void,
        onComplete: @escaping (PipelineResult) -> Void
    ) {
        // 1. Input guard
        let inputResult = InputContentFilter.evaluate(query: userQuery, context: context)
        switch inputResult.verdict {
        case .blocked:
            onComplete(PipelineResult(
                text: inputResult.reason,
                status: .filteredByGuard,
                ragChunksUsed: [],
                error: nil
            ))
            return
        case .redirect, .pass:
            break
        }
        let effectiveQuery = inputResult.sanitizedQuery ?? userQuery

        // 2. Retrieve — now searches both galaxy nodes AND curriculum windows
        let chunks = RAGRetriever.retrieve(query: effectiveQuery, context: context)

        // 3. System prompt (includes full curriculum block + matched windows)
        let systemPrompt = buildSystemPrompt(chunks: chunks, context: context)

        // 4. Assemble full prompt
        let fullPrompt = """
        <system>
        \(systemPrompt)
        </system>

        <user>
        \(effectiveQuery)
        </user>

        <assistant>
        """

        // 5. Stream
        var streamBuffer = ""
        runModel(
            prompt: fullPrompt,
            onDownload: onDownload,
            onStream: { currentText in
                streamBuffer = currentText
                onStream(currentText)
            },
            onComplete: { error in
                // 6. Output guard
                let outputResult = OutputContentFilter.evaluate(
                    response: streamBuffer,
                    context: context
                )
                let finalStatus: PipelineResult.Status
                switch outputResult.verdict {
                case .pass:     finalStatus = error == nil ? .success : .modelError
                case .rewritten, .replaced: finalStatus = .filteredByGuard
                }
                onComplete(PipelineResult(
                    text: outputResult.deliverableText,
                    status: finalStatus,
                    ragChunksUsed: chunks,
                    error: error
                ))
            }
        )
    }
}
