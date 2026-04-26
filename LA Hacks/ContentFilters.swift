//
//  ContentFilters.swift
//  LA Hacks
//
//  Created by Yirui Song on 4/25/26.
//

import Foundation
import NaturalLanguage

// MARK: - Filter Result Types

/// The outcome of running a query through the input guard.
struct InputFilterResult {
    enum Verdict {
        /// Query is safe and on-topic — forward as-is to the RAG pipeline.
        case pass
        /// Query is off-topic or mildly inappropriate — use `sanitizedQuery` instead.
        case redirect
        /// Query is harmful or clearly inappropriate — abort the pipeline entirely.
        case blocked
    }

    let verdict: Verdict
    /// The query to actually send to RAGRetriever (may differ from the original).
    /// Equals the original query when verdict is `.pass`, is rewritten when `.redirect`,
    /// and is nil when `.blocked`.
    let sanitizedQuery: String?
    /// Human-readable reason (for logging / parent dashboards).
    let reason: String
    /// Specific issues found, keyed by category (e.g. "violence", "personal_info").
    let issues: [FilterIssue]
}

struct FilterIssue {
    let category: String
    let detail: String
}

// MARK: - InputContentFilter

/// Stateless input guard for the Galaxy Tutor RAG pipeline.
///
/// Usage inside `RAGPipeline.run()`:
/// ```swift
/// let filterResult = InputContentFilter.evaluate(query: userQuery, context: context)
/// switch filterResult.verdict {
/// case .blocked:
///     onComplete(PipelineResult(text: filterResult.reason, status: .filteredByGuard, ...))
///     return
/// case .redirect:
///     effectiveQuery = filterResult.sanitizedQuery ?? userQuery
/// case .pass:
///     effectiveQuery = userQuery
/// }
/// // Continue with effectiveQuery → RAGRetriever → model
/// ```
enum InputContentFilter {

    // MARK: - Public API

    static func evaluate(query: String, context: PipelineContext) -> InputFilterResult {
        let normalized = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Hard-block pass — catches explicit harmful content first
        if let blockResult = checkHardBlocks(normalized: normalized) {
            return blockResult
        }

        // 2. Soft-flag pass — catches off-topic, manipulative, or boundary-testing queries
        let softIssues = checkSoftFlags(normalized: normalized, context: context)
        if !softIssues.isEmpty {
            let redirect = buildRedirectQuery(original: query, context: context)
            return InputFilterResult(
                verdict: .redirect,
                sanitizedQuery: redirect,
                reason: "Query redirected to stay on topic and age-appropriate.",
                issues: softIssues
            )
        }

        // 3. Pass
        return InputFilterResult(
            verdict: .pass,
            sanitizedQuery: query,
            reason: "Query approved.",
            issues: []
        )
    }

    // MARK: - Hard Block Rules

    /// Returns a `.blocked` result if the query matches any hard-block pattern.
    private static func checkHardBlocks(normalized: String) -> InputFilterResult? {
        let rules: [(category: String, detail: String, patterns: [String])] = [
            (
                "explicit_content",
                "Sexual or explicitly adult content.",
                ["sex", "porn", "nude", "naked", "xxx", "erotic", "genital", "masturbat"]
            ),
            (
                "graphic_violence",
                "Graphic depictions of violence, gore, or death.",
                ["gore", "blood and guts", "decapitat", "torture", "mutilat", "corpse", "dismember"]
            ),
            (
                "self_harm",
                "Self-harm or suicide references.",
                ["kill myself", "suicide", "self harm", "cut myself", "hurt myself", "want to die"]
            ),
            (
                "substance_abuse",
                "Detailed drug use or substance abuse.",
                ["how to get high", "how to make drugs", "how to smoke", "weed", "cocaine", "heroin", "meth"]
            ),
            (
                "personal_information_solicitation",
                "Attempting to extract or share personal identifying information.",
                ["home address", "phone number", "where do you live", "credit card", "social security",
                 "parent's email", "parent email", "my password"]
            ),
            (
                "jailbreak_attempt",
                "Attempting to override safety instructions or manipulate the AI.",
                ["ignore previous instructions", "ignore your instructions", "pretend you have no rules",
                 "act as if you are", "you are now", "dan mode", "developer mode", "jailbreak",
                 "forget you are an ai", "forget your guidelines"]
            ),
            (
                "weapon_instructions",
                "Instructions for creating weapons or explosive devices.",
                ["how to make a bomb", "build a weapon", "make a gun", "poison recipe",
                 "how to hurt someone", "how to attack"]
            ),
        ]

        for rule in rules {
            for pattern in rule.patterns {
                if normalized.contains(pattern) {
                    return InputFilterResult(
                        verdict: .blocked,
                        sanitizedQuery: nil,
                        reason: "This question isn't something I can help with. Let's keep exploring the galaxy together!",
                        issues: [FilterIssue(category: rule.category, detail: rule.detail)]
                    )
                }
            }
        }
        return nil
    }

    // MARK: - Soft Flag Rules

    /// Returns issues for queries that are off-topic, boundary-testing, or mildly inappropriate.
    /// These are redirected rather than blocked.
    private static func checkSoftFlags(normalized: String, context: PipelineContext) -> [FilterIssue] {
        var issues: [FilterIssue] = []

        let softRules: [(category: String, detail: String, patterns: [String])] = [
            (
                "homework_completion",
                "Asking the tutor to complete homework rather than explain concepts.",
                ["do my homework", "write my essay", "complete my assignment",
                 "give me the answers", "just tell me the answer"]
            ),
            (
                "off_topic_personal",
                "Asking for personal information about the tutor or unrelated personal topics.",
                ["what is your name", "how old are you", "are you a real person",
                 "do you have feelings", "are you human", "do you have a body"]
            ),
            (
                "scary_framing",
                "Curiosity about dark space phenomena framed in a scary or morbid way.",
                ["killing everything", "destroying the earth", "end of the world",
                 "death of the universe", "everything dies", "nothing survives",
                 "terrifying", "horrifying", "scariest thing"]
            ),
            (
                "hate_speech",
                "Language targeting groups of people.",
                ["i hate", "stupid people", "dumb kids", "people are terrible"]
            ),
            (
                "unrelated_topic",
                "Clearly unrelated to the astronomy/math curriculum.",
                ["recipe for", "what should i eat", "sports score", "celebrity",
                 "movie spoiler", "video game cheat", "stock price"]
            ),
        ]

        for rule in softRules {
            for pattern in rule.patterns {
                if normalized.contains(pattern) {
                    issues.append(FilterIssue(category: rule.category, detail: rule.detail))
                    break // one issue per rule category
                }
            }
        }

        return issues
    }

    // MARK: - Redirect Query Builder

    /// Builds a safe, on-topic replacement query based on active context.
    private static func buildRedirectQuery(original: String, context: PipelineContext) -> String {
        if let constellationID = context.activeConstellationID {
            return "Can you help me understand more about \(constellationID)?"
        }
        return "Can you tell me something interesting about astronomy or math?"
    }
}

// MARK: - Output Filter Result

/// The outcome of running a model response through the output guard.
struct OutputFilterResult {
    enum Verdict {
        /// Response is safe — deliver as-is.
        case pass
        /// Response contained issues — deliver `cleanedText` instead.
        case rewritten
        /// Response is wholly inappropriate — replace with a safe fallback.
        case replaced
    }

    let verdict: Verdict
    /// The text that should actually be shown to the child.
    let deliverableText: String
    /// Audit log of what was changed and why.
    let issues: [FilterIssue]
}

// MARK: - OutputContentFilter

/// Stateless output guard for the Galaxy Tutor RAG pipeline.
///
/// Usage inside `RAGPipeline.run()` — wrap `onStream` accumulator:
/// ```swift
/// var buffer = ""
/// RAGPipeline.run(userQuery: effectiveQuery, context: context,
///     onDownload: onDownload,
///     onStream: { token in
///         buffer += token
///         onStream(token)          // stream raw tokens to UI for live display
///     },
///     onComplete: { error in
///         let filtered = OutputContentFilter.evaluate(response: buffer, context: context)
///         // If the output was rewritten/replaced, notify the UI to swap the text
///         let finalText = filtered.deliverableText
///         onComplete(PipelineResult(
///             text: finalText,
///             status: filtered.verdict == .pass ? .success : .filteredByGuard,
///             ragChunksUsed: chunks,
///             error: error
///         ))
///     }
/// )
/// ```
enum OutputContentFilter {

    // MARK: - Fallback Responses

    private static let genericFallback = "Hmm, let me think of a better way to explain that! Can you try asking me again?"

    private static let offTopicFallback = "That's an interesting question! Let's bring it back to our galaxy — what would you like to explore next in your constellation?"

    // MARK: - Public API

    static func evaluate(response: String, context: PipelineContext) -> OutputFilterResult {
        var issues: [FilterIssue] = []
        var working = response

        // 1. Hard-replacement pass — wholly unacceptable content
        if let replaceIssues = checkHardReplacements(text: working) {
            return OutputFilterResult(
                verdict: .replaced,
                deliverableText: genericFallback,
                issues: replaceIssues
            )
        }

        // 2. Phrase-level rewrites — strip or soften specific passages
        let (rewritten, rewriteIssues) = applyPhraseRewrites(text: working)
        if !rewriteIssues.isEmpty {
            working = rewritten
            issues.append(contentsOf: rewriteIssues)
        }

        // 3. Complexity / age-appropriateness check — flag but don't block
        let complexityIssues = checkComplexity(text: working)
        issues.append(contentsOf: complexityIssues)

        // 4. Off-topic drift — model answered something unrelated to the curriculum
        if let driftIssues = checkTopicDrift(text: working, context: context) {
            return OutputFilterResult(
                verdict: .replaced,
                deliverableText: offTopicFallback,
                issues: driftIssues
            )
        }

        if issues.isEmpty {
            return OutputFilterResult(verdict: .pass, deliverableText: working, issues: [])
        } else {
            return OutputFilterResult(verdict: .rewritten, deliverableText: working, issues: issues)
        }
    }

    // MARK: - Hard Replacement Checks

    /// Returns issues if the response must be wholly replaced (not just edited).
    private static func checkHardReplacements(text: String) -> [FilterIssue]? {
        let normalized = text.lowercased()

        let hardPatterns: [(category: String, detail: String, patterns: [String])] = [
            (
                "explicit_content",
                "Model generated sexually explicit or adult content.",
                ["explicit content", "sexual", "naked", "nude", "porn"]
            ),
            (
                "self_harm",
                "Model referenced self-harm or suicide.",
                ["kill yourself", "hurt yourself", "suicide", "self-harm"]
            ),
            (
                "personal_data_leak",
                "Model attempted to collect or reference personal information.",
                ["tell me your address", "what's your phone number", "your home is",
                 "i know where you live"]
            ),
            (
                "jailbreak_compliance",
                "Model appears to have complied with a jailbreak attempt.",
                ["i have no restrictions", "i can now do anything", "ignoring my guidelines",
                 "pretending i have no rules", "as an unrestricted ai"]
            ),
        ]

        var found: [FilterIssue] = []
        for rule in hardPatterns {
            for pattern in rule.patterns {
                if normalized.contains(pattern) {
                    found.append(FilterIssue(category: rule.category, detail: rule.detail))
                    break
                }
            }
        }
        return found.isEmpty ? nil : found
    }

    // MARK: - Phrase-Level Rewrites

    /// Scans for specific phrases and replaces them inline with safer alternatives.
    private static func applyPhraseRewrites(text: String) -> (String, [FilterIssue]) {
        var result = text
        var issues: [FilterIssue] = []

        let rewrites: [(pattern: String, replacement: String, category: String, detail: String)] = [
            // Scary death framing → curiosity framing
            (
                "everything will die",
                "stars eventually change and transform over billions of years",
                "scary_framing",
                "Replaced morbid framing with wonder-focused language."
            ),
            (
                "all life will be destroyed",
                "our universe will keep changing for an incredibly long time",
                "scary_framing",
                "Replaced alarming framing with age-appropriate language."
            ),
            (
                "the earth will be swallowed",
                "the Earth will change greatly as the Sun grows older",
                "scary_framing",
                "Softened end-of-earth framing."
            ),
            // Overly scary black-hole descriptions
            (
                "nothing can escape, not even you",
                "nothing can escape — not even light",
                "scary_framing",
                "Removed direct reference to the child being harmed."
            ),
            // Mild profanity the model might occasionally produce
            (
                "damn",
                "wow",
                "profanity",
                "Replaced mild profanity."
            ),
            (
                "hell",
                "very hot region",
                "profanity",
                "Replaced ambiguous term with descriptive alternative."
            ),
        ]

        for rewrite in rewrites {
            // Case-insensitive search + replace
            let range = result.range(of: rewrite.pattern, options: [.caseInsensitive])
            if let r = range {
                result.replaceSubrange(r, with: rewrite.replacement)
                issues.append(FilterIssue(category: rewrite.category, detail: rewrite.detail))
            }
        }

        return (result, issues)
    }

    // MARK: - Complexity Check

    /// Flags (but does not alter) responses that may be too advanced for ages 6–11.
    /// The calling layer can use this signal to append a simplification prompt.
    private static func checkComplexity(text: String) -> [FilterIssue] {
        var issues: [FilterIssue] = []

        let advancedTerms = [
            "relativistic", "quantum entanglement", "Schwarzschild radius",
            "event horizon topology", "differential equations", "thermodynamics",
            "nucleosynthesis", "spectroscopic analysis", "gravitational lensing tensor"
        ]

        let found = advancedTerms.filter { text.localizedCaseInsensitiveContains($0) }
        if !found.isEmpty {
            issues.append(FilterIssue(
                category: "age_complexity",
                detail: "Response may contain terms too advanced for ages 6–11: \(found.joined(separator: ", "))."
            ))
        }

        // Sentence length heuristic — very long sentences are hard for young readers
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let longSentences = sentences.filter { $0.split(separator: " ").count > 35 }
        if !longSentences.isEmpty {
            issues.append(FilterIssue(
                category: "sentence_complexity",
                detail: "\(longSentences.count) sentence(s) may be too long for young readers."
            ))
        }

        return issues
    }

    // MARK: - Topic Drift Check

    /// Detects if the model answered something completely unrelated to the tutor's domain.
    private static func checkTopicDrift(text: String, context: PipelineContext) -> [FilterIssue]? {
        let normalized = text.lowercased()

        // If the response contains curriculum-adjacent terms, it's on-topic
        let onTopicMarkers = [
            "star", "planet", "galaxy", "constellation", "orbit", "math",
            "fraction", "number", "learn", "explore", "space", "universe",
            "solar", "comet", "asteroid", "telescope", "science", "astronomy"
        ]
        let hasOnTopicContent = onTopicMarkers.contains { normalized.contains($0) }
        if hasOnTopicContent { return nil }

        // Patterns strongly suggesting the model went off-rails
        let offTopicPatterns = [
            "here is a recipe", "how to cook", "sports team", "stock market",
            "celebrity gossip", "political party", "election result"
        ]
        for pattern in offTopicPatterns {
            if normalized.contains(pattern) {
                return [FilterIssue(
                    category: "topic_drift",
                    detail: "Model response drifted off curriculum topic: matched '\(pattern)'."
                )]
            }
        }

        return nil
    }
}

// MARK: - Convenience Extension on RAGPipeline

extension RAGPipeline {

    /// Drop-in replacement for `run()` that adds both the input and output content guards.
    ///
    /// - The input guard runs synchronously before retrieval.
    /// - The output guard runs after the full response has been streamed.
    /// - `onStream` still fires for every token so the UI can show live typing.
    ///   If the output guard rewrites the response, the UI should replace the
    ///   streamed text with `PipelineResult.text` in the `onComplete` callback.
    static func runWithFilter(
        userQuery: String,
        context: PipelineContext,
        onDownload: @escaping (Float) -> Void,
        onStream: @escaping (String) -> Void,
        onComplete: @escaping (PipelineResult) -> Void
    ) {
        // ── INPUT GUARD ──────────────────────────────────────────────────────
        let inputResult = InputContentFilter.evaluate(query: userQuery, context: context)

        switch inputResult.verdict {
        case .blocked:
            // Short-circuit — never call the model
            onComplete(PipelineResult(
                text: inputResult.reason,
                status: .filteredByGuard,
                ragChunksUsed: [],
                error: nil
            ))
            return

        case .redirect:
            // Use the sanitized query downstream
            let safeQuery = inputResult.sanitizedQuery ?? userQuery
            runWithOutputGuard(
                userQuery: safeQuery,
                context: context,
                onDownload: onDownload,
                onStream: onStream,
                onComplete: onComplete
            )

        case .pass:
            runWithOutputGuard(
                userQuery: userQuery,
                context: context,
                onDownload: onDownload,
                onStream: onStream,
                onComplete: onComplete
            )
        }
    }

    // MARK: - Private Helpers

    private static func runWithOutputGuard(
        userQuery: String,
        context: PipelineContext,
        onDownload: @escaping (Float) -> Void,
        onStream: @escaping (String) -> Void,
        onComplete: @escaping (PipelineResult) -> Void
    ) {
        var streamBuffer = ""
        let chunks = RAGRetriever.retrieve(query: userQuery, context: context)

        run(
            userQuery: userQuery,
            context: context,
            onDownload: onDownload,
            onStream: { token in
                streamBuffer += token
                onStream(token) // pass through to UI for live display
            },
            onComplete: { baseResult in
                // ── OUTPUT GUARD ─────────────────────────────────────────────
                let outputResult = OutputContentFilter.evaluate(
                    response: streamBuffer,
                    context: context
                )

                let finalStatus: PipelineResult.Status
                switch outputResult.verdict {
                case .pass:
                    finalStatus = baseResult.error == nil ? .success : .modelError
                case .rewritten, .replaced:
                    finalStatus = .filteredByGuard
                }

                onComplete(PipelineResult(
                    text: outputResult.deliverableText,
                    status: finalStatus,
                    ragChunksUsed: chunks,
                    error: baseResult.error
                ))
            }
        )
    }
}
