// BKTMastery.swift
//  LA Hacks
//
//  Created by Yirui Song on 4/26/26
//
// Bayesian Knowledge Tracing (BKT) — the technical pipeline behind Nova.
//
// The classical BKT model treats each concept as a hidden binary state: the
// student either "knows" it or doesn't. After every answer attempt the model
// updates the probability of mastery using four parameters:
//
//   pL0  — prior: probability student already knew it before any attempts
//   pT   — transit: probability of learning the concept after each attempt
//   pG   — guess: probability of answering correctly when NOT knowing
//   pS   — slip: probability of answering incorrectly when knowing
//
// Star Hop! extends classical BKT with three pieces the LLM pipeline relies on:
//
//   1. Forgetting decay (pF). pKnows decays exponentially since lastAttempt so
//      stars the kid hasn't seen in days drift back toward unknown — the
//      probability the skill has been forgotten.
//
//   2. Prerequisite-conditioned prior. Brand-new stars inherit pL0 from the
//      mean mastery of their direct neighbors in the constellation graph —
//      knowing addition raises the prior on subtraction, and so on. This is
//      "how easy will the kid pick this up."
//
//   3. Mistake patterns. The wrong answers a student gives are remembered per
//      star so Nova can name the misconception ("you keep saying 14 — that's
//      the sum, not the product") and so the LLM prompt can warn the model
//      what to watch for.
//
// All three pieces flow into BKTPipeline (bottom of file) which is the bridge
// to LessonGenerator, DynamicLessonStore, and the RAG retriever.

import Foundation
import Combine

// MARK: - Per-concept state

struct BKTState: Codable {
    let starID: String
    let constellationID: String

    /// P(knows) — fresh posterior at the moment of `lastAttempt`. Apply decay
    /// to read out the *current* probability.
    var pKnows: Double

    /// Total attempts recorded
    var attempts: Int

    /// Timestamp of last attempt
    var lastAttempt: Date

    // ── BKT parameters (can be tuned per subject later) ──
    /// Prior probability of knowing before any practice
    var pL0: Double
    /// Probability of transitioning to "knows" after an attempt
    var pT: Double
    /// Probability of a correct guess when NOT knowing
    var pG: Double
    /// Probability of an incorrect slip when knowing
    var pS: Double

    /// Per-day forgetting probability (0–1). Decays pKnows toward zero between
    /// attempts: P(retains | knew) = (1 - pF)^days_since_lastAttempt.
    var pF: Double

    /// Top wrong answers the student has given for this star, with frequency.
    /// Capped at 8 entries — the most common ones survive eviction.
    var mistakes: [String: Int]

    init(starID: String, constellationID: String) {
        self.starID = starID
        self.constellationID = constellationID
        // Sensible defaults for elementary school content
        self.pL0 = 0.3
        self.pT  = 0.09
        self.pG  = 0.2
        self.pS  = 0.1
        self.pF  = 0.02
        self.mistakes = [:]
        self.pKnows = pL0
        self.attempts = 0
        self.lastAttempt = Date()
    }

    // MARK: Codable — backwards compatible with v1 saves that lack pF/mistakes.

    enum CodingKeys: String, CodingKey {
        case starID, constellationID, pKnows, attempts, lastAttempt
        case pL0, pT, pG, pS, pF, mistakes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        starID = try c.decode(String.self, forKey: .starID)
        constellationID = try c.decode(String.self, forKey: .constellationID)
        pKnows = try c.decode(Double.self, forKey: .pKnows)
        attempts = try c.decode(Int.self, forKey: .attempts)
        lastAttempt = try c.decode(Date.self, forKey: .lastAttempt)
        pL0 = try c.decode(Double.self, forKey: .pL0)
        pT  = try c.decode(Double.self, forKey: .pT)
        pG  = try c.decode(Double.self, forKey: .pG)
        pS  = try c.decode(Double.self, forKey: .pS)
        pF  = try c.decodeIfPresent(Double.self, forKey: .pF) ?? 0.02
        mistakes = try c.decodeIfPresent([String: Int].self, forKey: .mistakes) ?? [:]
    }

    // MARK: BKT update step

    /// Call after each answer. Returns updated P(knows) at this attempt.
    mutating func update(correct: Bool) -> Double {
        // Step 1 — P(knows | evidence) via Bayes
        let pCorrectGivenKnows    = 1.0 - pS
        let pCorrectGivenNotKnows = pG
        let pWrongGivenKnows      = pS
        let pWrongGivenNotKnows   = 1.0 - pG

        let pEvidence = correct
            ? (pKnows * pCorrectGivenKnows + (1 - pKnows) * pCorrectGivenNotKnows)
            : (pKnows * pWrongGivenKnows   + (1 - pKnows) * pWrongGivenNotKnows)

        // Posterior P(knows | answer)
        let pKnowsGivenEvidence: Double
        if pEvidence > 0 {
            let numerator = correct
                ? pKnows * pCorrectGivenKnows
                : pKnows * pWrongGivenKnows
            pKnowsGivenEvidence = numerator / pEvidence
        } else {
            pKnowsGivenEvidence = pKnows
        }

        // Step 2 — Apply learning transition
        pKnows = pKnowsGivenEvidence + (1.0 - pKnowsGivenEvidence) * pT

        attempts += 1
        lastAttempt = Date()
        return pKnows
    }

    // MARK: Forgetting decay

    /// Mastery probability adjusted for time-based forgetting since lastAttempt.
    /// Same as pKnows the moment of the attempt; decays toward 0 at rate pF/day.
    func decayedMastery(at now: Date = Date()) -> Double {
        let days = max(0, now.timeIntervalSince(lastAttempt) / 86_400.0)
        let retention = pow(1.0 - pF, days)
        return pKnows * retention
    }

    /// Probability the student has forgotten since lastAttempt: pKnows × (1 - retention).
    func forgetProbability(at now: Date = Date()) -> Double {
        let days = max(0, now.timeIntervalSince(lastAttempt) / 86_400.0)
        let retention = pow(1.0 - pF, days)
        return pKnows * (1.0 - retention)
    }

    /// Apply forgetting decay in-place. Called before a fresh attempt update so
    /// the Bayes step reflects whatever the student may have lost since last seen.
    mutating func applyDecay(at now: Date = Date()) {
        pKnows = decayedMastery(at: now)
    }

    // MARK: Mistakes

    mutating func recordMistake(_ answer: String) {
        let key = answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty, key.count <= 60 else { return }
        mistakes[key, default: 0] += 1
        if mistakes.count > 8 {
            let trimmed = mistakes.sorted { $0.value > $1.value }.prefix(8)
            mistakes = Dictionary(uniqueKeysWithValues: trimmed.map { ($0.key, $0.value) })
        }
    }
}

// MARK: - MasteryStore

final class BKTMastery: ObservableObject {

    static let shared = BKTMastery()

    /// All tracked star states, keyed by starID
    @Published private(set) var states: [String: BKTState] = [:]

    private let saveKey = "bkt_mastery_v1"

    private init() {
        load()
    }

    // MARK: - Public API: recording

    /// Record an answer for a star node. Creates state if first time. Applies
    /// forgetting decay before the Bayes update. Returns updated P(knows).
    @discardableResult
    func record(
        starID: String,
        constellationID: String,
        correct: Bool,
        studentAnswer: String? = nil
    ) -> Double {
        var state = states[starID] ?? BKTState(starID: starID, constellationID: constellationID)
        // Apply forgetting before observing the new evidence — this is what
        // lets the model say "they used to know it but probably forgot."
        state.applyDecay()
        let updated = state.update(correct: correct)
        if !correct, let answer = studentAnswer {
            state.recordMistake(answer)
        }
        states[starID] = state
        save()
        return updated
    }

    // MARK: - Public API: reading

    /// Fresh posterior at the moment of last attempt (no decay applied).
    /// Returns nil if the star has never been attempted.
    func mastery(for starID: String) -> Double? {
        states[starID]?.pKnows
    }

    /// Decay-adjusted mastery — what we believe the student knows *right now*.
    /// Returns nil if the star has never been attempted.
    func currentMastery(for starID: String) -> Double? {
        states[starID]?.decayedMastery()
    }

    /// Probability the student has forgotten the skill since lastAttempt.
    func forgetProbability(for starID: String) -> Double? {
        states[starID]?.forgetProbability()
    }

    /// Top-N most common wrong answers for a star. Empty if never attempted.
    func topMistakes(for starID: String, n: Int = 3) -> [(answer: String, count: Int)] {
        guard let state = states[starID] else { return [] }
        return state.mistakes.sorted { $0.value > $1.value }
            .prefix(n)
            .map { ($0.key, $0.value) }
    }

    /// Stars whose decay-adjusted mastery is below the threshold, weakest first.
    /// Only includes stars attempted at least `minAttempts` times.
    func weakStars(below threshold: Double = 0.6, minAttempts: Int = 1) -> [BKTState] {
        states.values
            .filter { $0.attempts >= minAttempts && $0.decayedMastery() < threshold }
            .sorted { $0.decayedMastery() < $1.decayedMastery() }
    }

    /// Stars where forgetProbability exceeds threshold — review candidates.
    func forgettingStars(above threshold: Double = 0.2) -> [BKTState] {
        states.values
            .filter { $0.attempts >= 1 && $0.forgetProbability() >= threshold }
            .sorted { $0.forgetProbability() > $1.forgetProbability() }
    }

    /// Weak star IDs grouped by constellation — useful for subject-level summaries.
    func weakStarsByConstellation(below threshold: Double = 0.6) -> [String: [BKTState]] {
        Dictionary(grouping: weakStars(below: threshold), by: \.constellationID)
    }

    /// Top N weakest stars to reinforce (for injection into PipelineContext).
    func topWeakStarIDs(n: Int = 3, below threshold: Double = 0.6) -> [String] {
        weakStars(below: threshold, minAttempts: 1)
            .prefix(n)
            .map(\.starID)
    }

    /// Human-readable summary for debugging / Nova prompt injection.
    /// Now decay-aware and includes the top misconception per weak star.
    func summaryForPrompt(below threshold: Double = 0.6) -> String {
        let weak = weakStars(below: threshold)
        guard !weak.isEmpty else { return "" }

        var lines = ["The student is struggling with these concepts (show extra patience and reinforce):"]
        for state in weak.prefix(5) {
            let pct = Int(state.decayedMastery() * 100)
            var line = "  • \(state.starID) (mastery: \(pct)%, attempts: \(state.attempts))"
            if let topMistake = state.mistakes.max(by: { $0.value < $1.value })?.key {
                line += " — common wrong answer: \"\(topMistake)\""
            }
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }

    /// Reset a single star (e.g. after a full lesson replay).
    func reset(starID: String) {
        states.removeValue(forKey: starID)
        save()
    }

    /// Reset all mastery data.
    func resetAll() {
        states = [:]
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(states) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: saveKey),
            let decoded = try? JSONDecoder().decode([String: BKTState].self, from: data)
        else { return }
        states = decoded
    }
}

// MARK: - BKTPipeline
//
// The bridge layer between BKTMastery and the LLM/RAG pipeline. Turns raw
// per-star mastery state into:
//   • a pickup prior for never-seen stars (from prerequisite mastery),
//   • a structured BKTLessonHints block that LessonGenerator pastes into prompts,
//   • a per-star RAG score multiplier that boosts retrieval of weak topics.

/// Compact, prompt-ready snapshot of the BKT model's beliefs about one star.
struct BKTLessonHints {
    let starID: String
    let starLabel: String
    /// Decay-adjusted mastery if attempted before, else the prereq-conditioned prior.
    let estimatedMastery: Double
    /// True iff the student has never recorded an attempt on this star.
    let isFirstEncounter: Bool
    /// Probability the student has forgotten since lastAttempt (0 if first encounter).
    let forgetProbability: Double
    let weakPrereqs: [(starID: String, label: String, mastery: Double)]
    let strongPrereqs: [(starID: String, label: String, mastery: Double)]
    let likelyMisconceptions: [String]
    /// True iff forgetProbability >= 0.25 — the model thinks they need a refresher.
    let needsReview: Bool

    /// LLM-ready Markdown block. Pasted verbatim into LessonContext.memory and
    /// into Nova's chat system prompt.
    func promptSection() -> String {
        var lines: [String] = []
        lines.append("## 🧮 BKT Snapshot — \(starLabel)")

        let pct = Int(estimatedMastery * 100)
        if isFirstEncounter {
            lines.append("- Predicted pickup ease: **\(pct)%** (based on prerequisite mastery — student has not seen this star yet).")
        } else {
            lines.append("- Estimated current mastery: **\(pct)%**")
            if forgetProbability > 0.05 {
                let fpct = Int(forgetProbability * 100)
                lines.append("- Forgetting since last seen: ~\(fpct)% — start with a quick refresher.")
            }
        }

        if !strongPrereqs.isEmpty {
            let parts = strongPrereqs.map { "\($0.label) (\(Int($0.mastery*100))%)" }
            lines.append("- Build on these solid skills: \(parts.joined(separator: ", "))")
        }
        if !weakPrereqs.isEmpty {
            let parts = weakPrereqs.map { "\($0.label) (\(Int($0.mastery*100))%)" }
            lines.append("- Watch out — these prerequisites are shaky: \(parts.joined(separator: ", "))")
        }
        if !likelyMisconceptions.isEmpty {
            let q = likelyMisconceptions.map { "\"\($0)\"" }.joined(separator: ", ")
            lines.append("- Common past wrong answers on this star: \(q). If the student says one of these, name the misconception directly.")
        }
        if needsReview {
            lines.append("- Recommend: open with a 1-question recap before introducing anything new.")
        }
        return lines.joined(separator: "\n")
    }
}

enum BKTPipeline {

    // MARK: - Prerequisite graph

    /// Adjacency derived from constellation edges + cross-subject bridges.
    /// Edges are treated as undirected — they encode "concepts that travel
    /// together," which is good enough for a pickup-prior estimate.
    private static let neighbors: [String: Set<String>] = {
        var adj: [String: Set<String>] = [:]
        let allEdges: [Edge] = GalaxyData.constellations.flatMap(\.edges) + GalaxyData.bridges
        for e in allEdges {
            adj[e.a, default: []].insert(e.b)
            adj[e.b, default: []].insert(e.a)
        }
        return adj
    }()

    /// Direct prerequisite / sibling stars in the knowledge graph.
    static func prereqs(of starID: String) -> [String] {
        Array(neighbors[starID] ?? [])
    }

    // MARK: - Predictions

    /// Pickup prior for a star the student has never attempted: weighted average
    /// of prerequisite mastery. Mastered prereqs raise it; unseen prereqs leave
    /// it at the BKT default (0.3). Returns nil if the star is unknown.
    static func pickupPrior(for starID: String) -> Double {
        let prereqIDs = prereqs(of: starID)
        guard !prereqIDs.isEmpty else { return 0.3 }

        var totalWeight = 0.0
        var weightedSum = 0.0
        for prereqID in prereqIDs {
            if let m = BKTMastery.shared.currentMastery(for: prereqID) {
                let w = 1.0
                weightedSum += m * w
                totalWeight += w
            } else {
                // Unseen prereq contributes the BKT default at half weight —
                // we don't know it's known, but we don't penalize for ignorance.
                weightedSum += 0.3 * 0.5
                totalWeight += 0.5
            }
        }
        return totalWeight > 0 ? weightedSum / totalWeight : 0.3
    }

    /// Best estimate of "what does the student know about this star *right now*."
    /// Falls back to the pickup prior if never attempted.
    static func estimatedMastery(for starID: String) -> Double {
        BKTMastery.shared.currentMastery(for: starID) ?? pickupPrior(for: starID)
    }

    /// Probability the student has forgotten since lastAttempt; 0 if never seen.
    static func forgetProbability(for starID: String) -> Double {
        BKTMastery.shared.forgetProbability(for: starID) ?? 0.0
    }

    // MARK: - Lesson hints

    /// Assemble the structured BKT snapshot for one star. Cheap — call per lesson.
    static func hints(for starID: String) -> BKTLessonHints {
        let starLabel = GalaxyData.nodesById[starID]?.node.label ?? starID
        let isFirstEncounter = BKTMastery.shared.mastery(for: starID) == nil
        let est = estimatedMastery(for: starID)
        let forgot = forgetProbability(for: starID)

        // Split prereqs by mastery threshold so LLM gets a clear "build on / watch out for" split
        let prereqIDs = prereqs(of: starID)
        var weak: [(starID: String, label: String, mastery: Double)] = []
        var strong: [(starID: String, label: String, mastery: Double)] = []
        for pid in prereqIDs {
            guard let m = BKTMastery.shared.currentMastery(for: pid) else { continue }
            let label = GalaxyData.nodesById[pid]?.node.label ?? pid
            if m >= 0.7 {
                strong.append((pid, label, m))
            } else if m < 0.5 {
                weak.append((pid, label, m))
            }
        }
        // Most informative first.
        weak.sort { $0.mastery < $1.mastery }
        strong.sort { $0.mastery > $1.mastery }

        let mistakes = BKTMastery.shared.topMistakes(for: starID, n: 3).map(\.answer)

        return BKTLessonHints(
            starID: starID,
            starLabel: starLabel,
            estimatedMastery: est,
            isFirstEncounter: isFirstEncounter,
            forgetProbability: forgot,
            weakPrereqs: Array(weak.prefix(3)),
            strongPrereqs: Array(strong.prefix(3)),
            likelyMisconceptions: mistakes,
            needsReview: !isFirstEncounter && forgot >= 0.25
        )
    }

    // MARK: - RAG integration

    /// Multiplier applied to a RAGChunk's relevance score based on the BKT model's
    /// urgency for that star. Weak/forgetting stars get up to a 1.7× boost so the
    /// LLM is reminded of them more often when answering tangential questions.
    static func ragBoost(for starID: String) -> Float {
        guard let state = BKTMastery.shared.states[starID] else {
            // Never seen — neutral; the pickup prior is interesting but not urgent.
            return 1.0
        }
        let mastery = Float(state.decayedMastery())
        let forgot = Float(state.forgetProbability())
        // 0.5 mastery → 1.0×, 0.0 mastery → 1.5×, 1.0 mastery → 0.9×
        let masteryBoost = 1.5 - mastery
        // Forgetting adds up to +0.2 on top.
        let forgetBoost = forgot * 0.2
        return max(0.8, masteryBoost + forgetBoost)
    }

    /// Compact summary for the chat-system prompt — different shape than
    /// `BKTMastery.summaryForPrompt` because it includes forgetting, prereqs,
    /// and misconception names for the *currently active* star when present.
    static func contextForRAG(activeStarID: String?) -> String {
        var sections: [String] = []

        // Active-star deep snapshot
        if let id = activeStarID {
            let h = hints(for: id)
            sections.append(h.promptSection())
        }

        // Forgetting queue — stars the student likely forgot
        let forgetting = BKTMastery.shared.forgettingStars(above: 0.25).prefix(3)
        if !forgetting.isEmpty {
            var lines = ["## ⏳ Likely Forgotten Topics"]
            for s in forgetting {
                let label = GalaxyData.nodesById[s.starID]?.node.label ?? s.starID
                let fpct = Int(s.forgetProbability() * 100)
                lines.append("- \(label): ~\(fpct)% forgetting probability")
            }
            lines.append("If a question even loosely relates to these, weave a quick refresher into your answer.")
            sections.append(lines.joined(separator: "\n"))
        }

        // Misconception watchlist
        let weak = BKTMastery.shared.weakStars(below: 0.5).prefix(3)
        let withMistakes = weak.filter { !$0.mistakes.isEmpty }
        if !withMistakes.isEmpty {
            var lines = ["## ⚠️ Misconceptions to Watch For"]
            for s in withMistakes {
                let label = GalaxyData.nodesById[s.starID]?.node.label ?? s.starID
                let top = s.mistakes.sorted { $0.value > $1.value }.prefix(2)
                let answers = top.map { "\"\($0.key)\"" }.joined(separator: ", ")
                lines.append("- \(label): student has answered \(answers)")
            }
            sections.append(lines.joined(separator: "\n"))
        }

        return sections.joined(separator: "\n\n")
    }
}
