//
//  ModelIntegration.swift
//  LA Hacks
//
//  Created by Yirui Song on 4/25/26.
//

import Foundation
import NaturalLanguage
import Security

// MARK: - Supporting Types

/// A single knowledge chunk retrieved from the galaxy graph and injected into the prompt.
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

/// A single conversation turn stored in history for multi-turn context.
struct ChatMessage: Identifiable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    let content: String
}

/// Per-request context injected by the calling view.
struct PipelineContext {
    /// ID of the constellation currently in focus (e.g. "fractions").
    var activeConstellationID: String?
    /// ID of the star node the student just tapped (e.g. "equiv").
    var activeStarID: String?
    /// Student display name used inside the system prompt.
    var studentName: String = "Explorer"
    /// Recent conversation turns (newest last). Injected by the view's history buffer.
    var history: [ChatMessage] = []
}

/// Outcome of one full pipeline run, delivered to the UI via `onComplete`.
struct PipelineResult {
    enum Status { case success, filteredByGuard, modelError }
    let text: String
    let status: Status
    /// Which RAG chunks were injected for this run (useful for debug overlays).
    let ragChunksUsed: [RAGChunk]
    let error: Error?
}

// MARK: - RAGRetriever

/// Retrieves relevant knowledge chunks from the static galaxy graph.
///
/// Current strategy: weighted keyword overlap + active-context bonus.
/// TODO: Replace with on-device vector embeddings (e.g. CoreML sentence encoder)
///       for semantic similarity instead of exact token matching.
enum RAGRetriever {

    private static let maxChunks = 3

    /// Returns the top-`maxChunks` most relevant chunks for `query`.
    static func retrieve(query: String, context: PipelineContext) -> [RAGChunk] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = query

        // Collect all token strings first
        var queryTokens: [String] = []
        tokenizer.enumerateTokens(in: query.startIndex..<query.endIndex) { tokenRange, _ in
            queryTokens.append(query[tokenRange].lowercased())
            return true
        }

        var scored: [(chunk: RAGChunk, score: Float)] = []

        for constellation in GalaxyData.constellations {
            for star in constellation.nodes {
                let score = relevanceScore(
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

        return scored
            .sorted { $0.score > $1.score }
            .prefix(maxChunks)
            .map(\.chunk)
    }

    // MARK: - Scoring

    /// Scores a single star against the tokenized query plus active-context bonuses.
    private static func relevanceScore(
        tokens: [String],
        constellation: Constellation,
        star: StarNode,
        context: PipelineContext
    ) -> Float {
        // Build a searchable target from ALL text fields, not just label + name
        let target = [
            star.label,
            constellation.name,
            constellation.blurb,
            constellation.skyStory,
            constellation.course
        ].joined(separator: " ").lowercased()

        let stopwords: Set<String> = ["a","an","the","is","are","do","how","what","i","me","my","of","to","and","or","in","it"]

        let matchCount = tokens.filter { !stopwords.contains($0) && target.contains($0) }.count
        var score = Float(matchCount)

        // Active-context bonus
        if constellation.id == context.activeConstellationID { score += 2.0 }
        if star.id == context.activeStarID { score += 3.0 }

        return score
    }
}

// MARK: - RAG Pipeline

enum RAGPipeline {

    // MARK: - System Prompt Template

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

        // Inject RAG context if available
        if !chunks.isEmpty {
            prompt += "\n\n## 📚 Curriculum Knowledge (Source of Truth)\n"
            prompt += "Use ONLY the following curriculum content to answer. Stay grounded in this material:\n\n"

            for chunk in chunks {
                prompt += """
                Subject: \(chunk.course)
                Topic: \(chunk.constellationName) — \(chunk.starLabel)
                Summary: \(chunk.blurb)
                Story: \(chunk.skyStory)

                """
            }
        }

        // Active focus context
        if let constellationID = context.activeConstellationID {
            prompt += "\nThe student is currently studying: \(constellationID)"
            if let starID = context.activeStarID {
                prompt += ", specifically: \(starID)"
            }
            prompt += ". Try to relate your answer back to this topic.\n"
        }

        // Conversation history
        if !context.history.isEmpty {
            prompt += "\n## Recent Conversation\n"
            for message in context.history.suffix(6) {
                let roleLabel = message.role == .user ? "\(context.studentName)" : "Nova"
                prompt += "\(roleLabel): \(message.content)\n"
            }
        }

        prompt += "\nNow respond to \(context.studentName)'s message below. Remember: 3–4 sentences max! 🚀\n"
        return prompt
    }

    // MARK: - Run Pipeline

    /// Retrieves RAG chunks, builds an enhanced system prompt, and calls runModel.
    static func run(
        userQuery: String,
        context: PipelineContext,
        onDownload: @escaping (Float) -> Void,
        onStream: @escaping (String) -> Void,
        onComplete: @escaping (PipelineResult) -> Void
    ) {
        // 1. INPUT GUARD — before any retrieval or model work
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
            break // continue with sanitizedQuery below
        }
        let effectiveQuery = inputResult.sanitizedQuery ?? userQuery

        // 2. Retrieve relevant chunks (using sanitized query if redirected)
        let chunks = RAGRetriever.retrieve(query: effectiveQuery, context: context)

        // 3. Build enhanced system prompt
        let systemPrompt = buildSystemPrompt(chunks: chunks, context: context)

        // 4. Combine into a single prompt string for the model
        let fullPrompt = """
        <system>
        \(systemPrompt)
        </system>

        <user>
        \(effectiveQuery)
        </user>

        <assistant>
        """

        // 5. Stream model response into a buffer for the output guard
        var streamBuffer = ""

        runModel(
            prompt: fullPrompt,
            onDownload: onDownload,
            onStream: { currentText in
                streamBuffer = currentText
                onStream(currentText)
            },
            onComplete: { error in
                // 6. OUTPUT GUARD — runs on the fully assembled response
                let outputResult = OutputContentFilter.evaluate(
                    response: streamBuffer,
                    context: context
                )

                let finalStatus: PipelineResult.Status
                switch outputResult.verdict {
                case .pass:
                    finalStatus = error == nil ? .success : .modelError
                case .rewritten, .replaced:
                    finalStatus = .filteredByGuard
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
