// BKTMastery.swift
//  LA Hacks
//
//  Created by Yirui Song on 4/26/26
//
// Bayesian Knowledge Tracing (BKT) per star node.
//
// BKT models each concept as a hidden binary state: the student either
// "knows" it or doesn't. After each answer attempt, it updates the
// probability of mastery using four parameters:
//
//   pL0  — prior: probability student already knew it before any attempts
//   pT   — transit: probability of learning the concept after each attempt
//   pG   — guess: probability of answering correctly when NOT knowing
//   pS   — slip: probability of answering incorrectly when knowing
//
// Usage:
//   BKTMastery.shared.record(starID: "addfrac", constellationID: "fractions", correct: true)
//   let weak = BKTMastery.shared.weakStars(below: 0.6)
//   let p = BKTMastery.shared.mastery(for: "addfrac")

import Foundation
import Combine

// MARK: - Per-concept state

struct BKTState: Codable {
    let starID: String
    let constellationID: String

    /// P(knows) — updated after each answer
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

    init(starID: String, constellationID: String) {
        self.starID = starID
        self.constellationID = constellationID
        // Sensible defaults for elementary school content
        self.pL0 = 0.3
        self.pT  = 0.09
        self.pG  = 0.2
        self.pS  = 0.1
        self.pKnows = pL0
        self.attempts = 0
        self.lastAttempt = Date()
    }

    // MARK: BKT update step

    /// Call after each answer. Returns updated P(knows).
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

    // MARK: - Public API

    /// Record an answer for a star node. Creates state if first time.
    @discardableResult
    func record(starID: String, constellationID: String, correct: Bool) -> Double {
        var state = states[starID] ?? BKTState(starID: starID, constellationID: constellationID)
        let updated = state.update(correct: correct)
        states[starID] = state
        save()
        return updated
    }

    /// Current mastery probability for a star (0–1). Returns nil if never attempted.
    func mastery(for starID: String) -> Double? {
        states[starID]?.pKnows
    }

    /// Stars with mastery below the threshold, sorted weakest first.
    /// Only includes stars that have been attempted at least `minAttempts` times.
    func weakStars(below threshold: Double = 0.6, minAttempts: Int = 1) -> [BKTState] {
        states.values
            .filter { $0.attempts >= minAttempts && $0.pKnows < threshold }
            .sorted { $0.pKnows < $1.pKnows }
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
    func summaryForPrompt(below threshold: Double = 0.6) -> String {
        let weak = weakStars(below: threshold)
        guard !weak.isEmpty else { return "" }

        var lines = ["The student is struggling with these concepts (show extra patience and reinforce):"]
        for state in weak.prefix(5) {
            let pct = Int(state.pKnows * 100)
            lines.append("  • \(state.starID) (mastery: \(pct)%, attempts: \(state.attempts))")
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
