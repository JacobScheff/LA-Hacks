//
//  ContentExtractor.swift
//  LA Hacks
//
//  Turns raw OCR / pasted text into a set of topics suitable for growing a
//  new (or extending an existing) galaxy constellation.
//
//  Strategy — heuristic, deterministic, runs in <50ms on-device:
//   1. Detect the broad subject (math, reading, science, …) from a weighted
//      keyword bag plus filename hints.
//   2. Mine the document for high-quality topic phrases:
//      • numbered / lettered list items
//      • heading-like lines (short, capitalized, no terminal punctuation)
//      • all-caps lines
//      • section markers ("Lesson 3:", "Topic:", "Chapter")
//      • most-frequent content nouns via NaturalLanguage's lemma+POS tagger
//   3. Rank, dedupe, and decorate each topic with a fitting emoji.
//   4. If the text was too thin for extraction, fall back to subject defaults
//      (mirrors the old TOPIC_RECIPES behaviour for paste-only flows).
//
//  Output is a Result struct that buildGenerationResult() consumes to build
//  the constellation — see UploadModal.swift.
//

import Foundation
import NaturalLanguage

enum ContentExtractor {

    // MARK: - Public types

    struct ExtractedTopic: Equatable {
        let label: String
        let emoji: String
    }

    enum Subject: String {
        case math, fractions, geometry, time, money
        case reading, writing
        case life, earth
        case history
        case music, code, art
        case generic
    }

    struct Result {
        /// Detected subject (drives constellation theming + emoji defaults).
        let subject: Subject
        /// Existing GalaxyData constellation id to merge new stars into,
        /// or nil if a brand-new constellation should be created.
        let matchingConstellationId: String?
        /// Display name for a brand-new constellation (ignored when merging).
        let suggestedName: String
        /// Display emoji for a brand-new constellation.
        let suggestedEmoji: String
        /// Sky-story text shown in the reveal modal.
        let suggestedSkyStory: String
        /// Final 3–6 topics that should become star nodes.
        let topics: [ExtractedTopic]
        /// Optional bonus "sleepy" topics seeded around new clusters.
        let neighborTopics: [ExtractedTopic]
    }

    // MARK: - Entry point

    static func extract(text: String, fileName: String) -> Result {
        let cleaned = sanitize(text)
        let subject = detectSubject(text: cleaned, fileName: fileName)

        var candidates = mineCandidates(from: cleaned, subject: subject)

        // Avoid ids already occupied by the matching constellation when merging
        if let matchId = subject.matchingConstellationId,
           let existingLabels = existingLabels(forConstellationId: matchId) {
            candidates.removeAll { c in
                existingLabels.contains { l in
                    fuzzyEqual(c.label, l)
                }
            }
        }

        // Fall back to subject defaults when extraction is too thin
        let topics: [ExtractedTopic]
        if candidates.count >= 3 {
            topics = Array(candidates.prefix(5)).map {
                ExtractedTopic(label: prettify($0.label),
                               emoji: emojiFor(label: $0.label, subject: subject))
            }
        } else {
            // Mix any extracted candidates with subject defaults, dedupe.
            var pool: [ExtractedTopic] = candidates.map {
                ExtractedTopic(label: prettify($0.label),
                               emoji: emojiFor(label: $0.label, subject: subject))
            }
            for d in subject.defaultTopics where !pool.contains(where: { fuzzyEqual($0.label, d.label) }) {
                pool.append(d)
                if pool.count >= 4 { break }
            }
            topics = Array(pool.prefix(5))
        }

        // Optional neighbor topics — only when we're growing a NEW constellation
        let neighborTopics: [ExtractedTopic]
        if subject.matchingConstellationId == nil {
            neighborTopics = subject.neighborTopics
        } else {
            neighborTopics = []
        }

        return Result(
            subject: subject,
            matchingConstellationId: subject.matchingConstellationId,
            suggestedName: subject.suggestedName,
            suggestedEmoji: subject.suggestedEmoji,
            suggestedSkyStory: subject.suggestedSkyStory,
            topics: topics,
            neighborTopics: neighborTopics
        )
    }

    // MARK: - Sanitisation

    private static func sanitize(_ text: String) -> String {
        // Normalise OCR junk: collapse repeats, strip non-printables, normalise quotes.
        var t = text.replacingOccurrences(of: "\r", with: "\n")
        t = t.replacingOccurrences(of: "\u{00A0}", with: " ")
        t = t.replacingOccurrences(of: "“", with: "\"")
        t = t.replacingOccurrences(of: "”", with: "\"")
        t = t.replacingOccurrences(of: "‘", with: "'")
        t = t.replacingOccurrences(of: "’", with: "'")
        // Drop page-break breadcrumbs added by the multi-page OCR path.
        let lines = t.split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0) }
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("--- Page") }
        return lines.joined(separator: "\n")
    }

    // MARK: - Subject detection

    private static func detectSubject(text: String, fileName: String) -> Subject {
        let haystack = (text + " " + fileName).lowercased()

        let buckets: [(Subject, [String])] = [
            (.fractions, [
                "fraction","numerator","denominator","halves","thirds","quarters",
                "1/2","1/3","1/4","2/3","3/4","decimal","ratio","percent","pizza",
                "equivalent fractions","mixed number","simplify",
            ]),
            (.geometry, [
                "geometry","triangle","square","rectangle","polygon","circle","shape",
                "perimeter","area","volume","vertex","vertices","angle","symmetric",
                "symmetry","parallel","perpendicular","quadrilateral","pentagon",
                "hexagon","octagon","cube","sphere",
            ]),
            (.money, [
                "money","coin","penny","nickel","dime","quarter coin","dollar","cent",
                "price","change","spend","budget","savings","cost",
            ]),
            (.time, [
                "clock","o'clock","minute","hour","calendar","schedule","elapsed time",
                "second hand","am pm","analog","digital clock","quarter past",
                "half past",
            ]),
            (.math, [
                "addition","add ","subtract","subtraction","multiply","multiplication",
                "divide","division","arithmetic","math","sum","carry","borrow","regroup",
                "digit","place value","number line","even","odd","equation","operator",
                "+","×","÷",
            ]),
            (.reading, [
                "story","passage","reading","phonics","comprehension","vocabulary",
                "main idea","character","setting","plot","theme","summarize","summary",
                "infer","inference","author","fiction","nonfiction","text feature",
            ]),
            (.writing, [
                "writing","sentence","paragraph","noun","verb","adjective","adverb",
                "punctuation","capitalize","capital letter","essay","draft","edit",
                "revise","topic sentence","conclusion","prompt",
            ]),
            (.life, [
                "plant","animal","habitat","ecosystem","cell","biology","biotic","organism",
                "photosynthesis","food chain","food web","life cycle","species",
                "predator","prey","mammal","reptile","amphibian","pollinator",
                "leaf","root","stem","flower","seed",
            ]),
            (.earth, [
                "earth","sun","moon","weather","climate","rock","water cycle","planet",
                "solar system","season","atmosphere","tectonic","erosion","volcano",
                "earthquake","ocean","gravity","stars","galaxy",
            ]),
            (.history, [
                "history","ancient","rome","egypt","greek","civilization","war",
                "revolution","treaty","empire","century","explorer","colony",
                "constitution","independence","government","democracy","timeline",
            ]),
            (.music, [
                "music","rhythm","melody","beat","song","piano","guitar","tempo",
                "scale","chord","staff","note","clef","measure","sharp flat",
            ]),
            (.code, [
                "code","coding","program","programming","function","loop","variable",
                "algorithm","boolean","javascript","python","scratch","debug","syntax",
                "console","print(",
            ]),
            (.art, [
                "art","painting","drawing","sketch","primary color","warm color",
                "cool color","shade","tint","palette","texture","perspective",
                "watercolor","sculpture",
            ]),
        ]

        var ranked: [(Subject, Int)] = []
        for (s, kws) in buckets {
            var score = 0
            for kw in kws {
                if haystack.contains(kw) { score += 1 }
            }
            if score > 0 { ranked.append((s, score)) }
        }
        ranked.sort { $0.1 > $1.1 }
        return ranked.first?.0 ?? .generic
    }

    // MARK: - Candidate mining

    private struct Candidate {
        var label: String
        var score: Double
    }

    private static func mineCandidates(from text: String, subject: Subject) -> [Candidate] {
        var pool: [Candidate] = []

        let rawLines = text.split(separator: "\n", omittingEmptySubsequences: true)
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // 1. Numbered / lettered list items — highest priority
        let listRegex = try? NSRegularExpression(
            pattern: #"^\s*(?:[0-9]{1,2}|[a-zA-Z])[\.\)]\s+(.{2,})$"#,
            options: []
        )
        // 2. Section markers
        let sectionRegex = try? NSRegularExpression(
            pattern: #"^\s*(?:lesson|topic|chapter|unit|part|section|skill)\s*[:#0-9\-]*\s*(.{2,})$"#,
            options: [.caseInsensitive]
        )

        for line in rawLines {
            let nsLine = line as NSString
            let fullRange = NSRange(location: 0, length: nsLine.length)

            if let m = listRegex?.firstMatch(in: line, range: fullRange),
               m.numberOfRanges > 1 {
                let raw = nsLine.substring(with: m.range(at: 1))
                if let phrase = topicPhrase(from: raw) {
                    pool.append(Candidate(label: phrase, score: 8.0))
                }
                continue
            }

            if let m = sectionRegex?.firstMatch(in: line, range: fullRange),
               m.numberOfRanges > 1 {
                let raw = nsLine.substring(with: m.range(at: 1))
                if let phrase = topicPhrase(from: raw) {
                    pool.append(Candidate(label: phrase, score: 7.0))
                }
                continue
            }

            // 3. All-caps lines (length > 3 chars, mostly letters)
            if isAllCapsHeading(line),
               let phrase = topicPhrase(from: line) {
                pool.append(Candidate(label: phrase, score: 6.0))
                continue
            }

            // 4. Heading-like lines
            if isHeadingLike(line),
               let phrase = topicPhrase(from: line) {
                pool.append(Candidate(label: phrase, score: 5.0))
            }
        }

        // 5. Frequent content nouns / noun phrases via NLTagger
        let frequentPhrases = extractFrequentNounPhrases(in: text, max: 8)
        for (phrase, count) in frequentPhrases {
            // Boost when the phrase aligns with the detected subject's vocabulary
            let boost = subjectAffinity(phrase: phrase, subject: subject) ? 1.5 : 0
            pool.append(Candidate(label: phrase, score: 2.0 + Double(count) * 0.3 + boost))
        }

        // Dedupe (case-insensitive, fuzzy) keeping highest score
        var bestByKey: [String: Candidate] = [:]
        for c in pool {
            let key = normalisedKey(c.label)
            guard !key.isEmpty, key.count >= 3 else { continue }
            if let existing = bestByKey[key] {
                if c.score > existing.score { bestByKey[key] = c }
            } else {
                bestByKey[key] = c
            }
        }

        // Filter low-quality phrases
        let filtered = bestByKey.values.filter { isPlausibleTopic($0.label) }

        // Sort by score, then by length (shorter labels read better as star names)
        return filtered.sorted { a, b in
            if a.score != b.score { return a.score > b.score }
            return a.label.count < b.label.count
        }
    }

    /// Extracts candidate topic phrase from a raw line: trims, drops trailing
    /// punctuation/answer fragments, caps at 3 words, returns nil if too thin.
    private static func topicPhrase(from raw: String) -> String? {
        var s = raw.trimmingCharacters(in: .whitespaces)

        // Drop trailing answer hints ("... = ?" or "... ___")
        if let r = s.range(of: " = ") { s = String(s[..<r.lowerBound]) }
        s = s.replacingOccurrences(of: "_", with: "")
        s = s.replacingOccurrences(of: "____", with: "")

        // Strip ending punctuation
        while let last = s.unicodeScalars.last,
              CharacterSet.punctuationCharacters.contains(last) ||
                CharacterSet(charactersIn: ":?!.").contains(last) {
            s.removeLast()
        }

        // Words — collapse to first 3 meaningful
        let stopwords = generalStopwords
        let words = s.split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "&" && $0 != "'" })
            .map { String($0) }

        // Drop leading articles / fillers
        var filtered = words
        while let first = filtered.first?.lowercased(), stopwords.contains(first) {
            filtered.removeFirst()
        }

        guard !filtered.isEmpty, filtered.joined().count >= 3 else { return nil }
        let trimmed = Array(filtered.prefix(4))
        let phrase = trimmed.joined(separator: " ")
        return phrase
    }

    private static func isAllCapsHeading(_ line: String) -> Bool {
        let letters = line.filter { $0.isLetter }
        guard letters.count >= 4 else { return false }
        let uppers = letters.filter { $0.isUppercase }.count
        return Double(uppers) / Double(letters.count) >= 0.85 && line.count <= 60
    }

    private static func isHeadingLike(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3, trimmed.count <= 60 else { return false }
        if let last = trimmed.last, ".!?".contains(last) { return false }
        let words = trimmed.split(separator: " ").map { String($0) }
        guard words.count >= 1, words.count <= 6 else { return false }
        let initialCaps = words.filter { ($0.first?.isUppercase ?? false) }.count
        return Double(initialCaps) / Double(words.count) >= 0.5
    }

    // MARK: - Frequency-based noun phrases (NaturalLanguage)

    /// Returns the top N most-frequent content nouns (lemmatized) plus simple
    /// adjective+noun bigrams. Score = raw count.
    private static func extractFrequentNounPhrases(in text: String, max: Int) -> [(String, Int)] {
        let truncated = String(text.prefix(8000))   // protect against huge OCR dumps
        let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
        tagger.string = truncated
        let opts: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther]
        let stopwords = generalStopwords

        // Walk every word once, building (lemma, posTag) tuples
        var sequence: [(lemma: String, pos: NLTag)] = []
        tagger.enumerateTags(
            in: truncated.startIndex..<truncated.endIndex,
            unit: .word, scheme: .lexicalClass, options: opts
        ) { tag, range in
            guard let tag = tag else { return true }
            let surface = String(truncated[range]).trimmingCharacters(in: .whitespaces)
            guard surface.count >= 2 else { return true }
            let lemmaTag = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lemma).0
            let lemma = (lemmaTag?.rawValue ?? surface).lowercased()
            sequence.append((lemma, tag))
            return true
        }

        var unigramCount: [String: Int] = [:]
        var bigramCount: [String: Int] = [:]

        for (idx, item) in sequence.enumerated() {
            guard item.pos == .noun else { continue }
            let lemma = item.lemma
            guard lemma.count >= 3, !stopwords.contains(lemma),
                  lemma.first?.isLetter ?? false else { continue }
            unigramCount[lemma, default: 0] += 1

            // Adjective + noun bigram (e.g., "main idea")
            if idx > 0,
               sequence[idx - 1].pos == .adjective,
               sequence[idx - 1].lemma.count >= 3,
               !stopwords.contains(sequence[idx - 1].lemma) {
                let bigram = "\(sequence[idx - 1].lemma) \(lemma)"
                bigramCount[bigram, default: 0] += 1
            }
            // Noun + noun bigram (compound nouns like "place value")
            if idx > 0,
               sequence[idx - 1].pos == .noun,
               sequence[idx - 1].lemma.count >= 3,
               !stopwords.contains(sequence[idx - 1].lemma) {
                let bigram = "\(sequence[idx - 1].lemma) \(lemma)"
                bigramCount[bigram, default: 0] += 1
            }
        }

        // Bigrams beat unigrams when frequent enough — they're more informative.
        var combined: [(String, Int)] = []
        var consumed: Set<String> = []
        for (b, c) in bigramCount where c >= 2 {
            combined.append((b, c + 2))
            consumed.formUnion(b.split(separator: " ").map(String.init))
        }
        for (u, c) in unigramCount where !consumed.contains(u) {
            combined.append((u, c))
        }
        combined.sort { ($0.1, $1.0) > ($1.1, $0.0) }
        return Array(combined.prefix(max))
    }

    // MARK: - Filtering & prettifying

    private static func isPlausibleTopic(_ label: String) -> Bool {
        let trimmed = label.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3, trimmed.count <= 36 else { return false }

        // Reject if mostly digits — a topic should be a concept, not a number
        let letters = trimmed.filter { $0.isLetter }.count
        let digits  = trimmed.filter { $0.isNumber }.count
        if letters == 0 || digits > letters { return false }

        // Reject if it looks like a fragment of a sentence
        let lower = trimmed.lowercased()
        let badStarts = ["which ", "what ", "how ", "why ", "where ", "when ",
                         "circle ", "draw ", "write ", "find the ", "fill in ",
                         "answer ", "directions ", "instructions "]
        for prefix in badStarts where lower.hasPrefix(prefix) {
            return false
        }

        // Reject pure stopword phrases
        let words = lower.split(separator: " ").map(String.init)
        let nonStop = words.filter { !generalStopwords.contains($0) }
        return !nonStop.isEmpty
    }

    /// Title-cases the topic, expanding common abbreviations.
    private static func prettify(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespaces)
        // Cap to 3-4 words
        let words = s.split(separator: " ").map(String.init)
        if words.count > 4 { s = words.prefix(4).joined(separator: " ") }

        let parts = s.split(separator: " ").map { word -> String in
            let lower = word.lowercased()
            // Keep common short connectives lowercase
            if ["and","or","of","the","a","vs","to","in","on"].contains(lower) {
                return lower
            }
            // Special forms
            if lower == "tv" { return "TV" }
            if lower == "us" { return "US" }
            // Title case
            return lower.prefix(1).uppercased() + lower.dropFirst()
        }
        var titled = parts.joined(separator: " ")
        // First word always capitalized
        if let first = titled.first, first.isLowercase {
            titled = String(first).uppercased() + titled.dropFirst()
        }
        return titled
    }

    private static func normalisedKey(_ s: String) -> String {
        s.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func fuzzyEqual(_ a: String, _ b: String) -> Bool {
        normalisedKey(a) == normalisedKey(b)
    }

    private static func subjectAffinity(phrase: String, subject: Subject) -> Bool {
        let p = phrase.lowercased()
        return subject.affinityKeywords.contains { p.contains($0) }
    }

    // MARK: - Existing-constellation labels (for dedupe when merging)

    private static func existingLabels(forConstellationId id: String) -> [String]? {
        guard let c = GalaxyData.constellations.first(where: { $0.id == id }) else { return nil }
        return c.nodes.map(\.label)
    }

    // MARK: - Stopwords

    private static let generalStopwords: Set<String> = [
        "a","an","the","and","or","but","if","of","to","in","on","at","by","as",
        "is","are","was","were","be","been","being","do","does","did","this",
        "that","these","those","it","its","you","your","i","my","me","we","our",
        "they","their","he","she","his","her","not","no","yes","with","from",
        "for","so","than","then","there","here","what","which","who","whom",
        "whose","when","where","why","how","can","could","should","would","will",
        "shall","may","might","must","one","two","three","four","five","six",
        "seven","eight","nine","ten","page","name","date","grade","worksheet",
        "homework","question","problem","answer","class","student","teacher",
        "directions","instructions","example","examples","time","day","week",
        "year","today","tomorrow","yesterday","also","just","only","very","much",
        "many","more","most","some","any","each","every","other","another",
        "thing","things","make","made","find","get","got","take","took",
    ]
}

// MARK: - Subject defaults

extension ContentExtractor.Subject {

    /// Existing GalaxyData constellation id this subject can merge into,
    /// or nil to spawn a fresh constellation.
    var matchingConstellationId: String? {
        switch self {
        case .math:      return "numbers"
        case .fractions: return "fractions"
        case .geometry:  return "shapes"
        case .time:      return "time"
        case .money:     return "time"            // shares the Leo / Clock Cove cluster
        case .reading:   return "reading"
        case .writing:   return "writing"
        case .life:      return "life"
        case .earth:     return "earth"
        case .history:   return "history"
        case .music, .code, .art, .generic: return nil
        }
    }

    var suggestedName: String {
        switch self {
        case .math:      return "Number Land"
        case .fractions: return "Pizza Planet"
        case .geometry:  return "Shape City"
        case .time:      return "Clock Cove"
        case .money:     return "Coin Cove"
        case .reading:   return "Story Shore"
        case .writing:   return "Inkwell Isle"
        case .life:      return "Critter Cove"
        case .earth:     return "Sky & Space"
        case .history:   return "Time Travel Trail"
        case .music:     return "Melody Meadow"
        case .code:      return "Code Cosmos"
        case .art:       return "Color Cluster"
        case .generic:   return "Curiosity Cluster"
        }
    }

    var suggestedEmoji: String {
        switch self {
        case .math:      return "🔢"
        case .fractions: return "🍕"
        case .geometry:  return "🔷"
        case .time:      return "🕒"
        case .money:     return "💰"
        case .reading:   return "📚"
        case .writing:   return "✏️"
        case .life:      return "🌱"
        case .earth:     return "🪐"
        case .history:   return "🏛️"
        case .music:     return "🎵"
        case .code:      return "💻"
        case .art:       return "🎨"
        case .generic:   return "🔭"
        }
    }

    var suggestedSkyStory: String {
        switch self {
        case .music:
            return "You discovered a brand new corner of the galaxy. Music has its own little cluster of stars now!"
        case .code:
            return "A new cluster of stars just blinked on. Computer thinking is its own kind of magic!"
        case .art:
            return "Splashes of color lit up the sky! Your artistic side has its very own cluster now."
        case .generic:
            return "Whatever you uploaded sparked something brand-new — these stars came together just from your doc!"
        default:
            return "Nova grew this part of the sky from your upload. New stars are waking up!"
        }
    }

    /// Subject-specific defaults used when text was too thin to extract topics.
    var defaultTopics: [ContentExtractor.ExtractedTopic] {
        switch self {
        case .math:
            return [
                .init(label: "Two-Digit Adding", emoji: "🔟"),
                .init(label: "Carrying Over", emoji: "🎒"),
                .init(label: "Number Lines", emoji: "📏"),
                .init(label: "Place Value", emoji: "🏠"),
            ]
        case .fractions:
            return [
                .init(label: "Pizza Slicing", emoji: "🍕"),
                .init(label: "Comparing Halves", emoji: "⚖️"),
                .init(label: "Decimals & Fractions", emoji: "🔢"),
                .init(label: "Mixed Numbers", emoji: "🥧"),
            ]
        case .geometry:
            return [
                .init(label: "Triangles", emoji: "🔺"),
                .init(label: "Quadrilaterals", emoji: "🟦"),
                .init(label: "Symmetry", emoji: "🦋"),
                .init(label: "Perimeter", emoji: "📐"),
            ]
        case .time:
            return [
                .init(label: "Reading Clocks", emoji: "🕒"),
                .init(label: "Hours & Minutes", emoji: "⏱️"),
                .init(label: "Calendar Skills", emoji: "📅"),
            ]
        case .money:
            return [
                .init(label: "Counting Coins", emoji: "🪙"),
                .init(label: "Making Change", emoji: "💱"),
                .init(label: "Dollars & Cents", emoji: "💵"),
            ]
        case .reading:
            return [
                .init(label: "Story Settings", emoji: "🏞️"),
                .init(label: "Plot Twists", emoji: "🌪️"),
                .init(label: "Character Feelings", emoji: "😢"),
                .init(label: "Main Idea", emoji: "💡"),
            ]
        case .writing:
            return [
                .init(label: "Capitals & Periods", emoji: "🔠"),
                .init(label: "Strong Verbs", emoji: "🐶"),
                .init(label: "Topic Sentences", emoji: "📝"),
                .init(label: "Edit & Revise", emoji: "🧹"),
            ]
        case .life:
            return [
                .init(label: "Pollinators", emoji: "🐝"),
                .init(label: "Animal Adaptations", emoji: "🦎"),
                .init(label: "Forest Layers", emoji: "🌳"),
                .init(label: "Food Chains", emoji: "🦊"),
            ]
        case .earth:
            return [
                .init(label: "Water Cycle", emoji: "💧"),
                .init(label: "Weather Patterns", emoji: "⛅"),
                .init(label: "Rocks & Minerals", emoji: "🪨"),
                .init(label: "Solar System", emoji: "🪐"),
            ]
        case .history:
            return [
                .init(label: "Roman Roads", emoji: "🛣️"),
                .init(label: "Pyramids", emoji: "🔺"),
                .init(label: "Trade Routes", emoji: "🐪"),
                .init(label: "Reading Maps", emoji: "🧭"),
            ]
        case .music:
            return [
                .init(label: "Reading Notes", emoji: "🎼"),
                .init(label: "Beats & Rhythm", emoji: "🥁"),
                .init(label: "Loud & Soft", emoji: "🔊"),
                .init(label: "Major vs Minor", emoji: "🎹"),
                .init(label: "Song Shapes", emoji: "🎶"),
            ]
        case .code:
            return [
                .init(label: "Sequences", emoji: "➡️"),
                .init(label: "Loops", emoji: "🔁"),
                .init(label: "If / Then", emoji: "🔀"),
                .init(label: "Variables", emoji: "📦"),
                .init(label: "Bugs!", emoji: "🐛"),
            ]
        case .art:
            return [
                .init(label: "Primary Colors", emoji: "🎨"),
                .init(label: "Warm vs Cool", emoji: "🔥"),
                .init(label: "Lines & Shapes", emoji: "📐"),
                .init(label: "Texture", emoji: "🪶"),
            ]
        case .generic:
            return [
                .init(label: "Big Idea", emoji: "💡"),
                .init(label: "Key Term", emoji: "🔑"),
                .init(label: "Tricky Bit", emoji: "🤔"),
                .init(label: "Try It Out", emoji: "🎯"),
            ]
        }
    }

    /// Extra "sleepy" stars seeded around brand-new constellations.
    var neighborTopics: [ContentExtractor.ExtractedTopic] {
        switch self {
        case .music, .code, .art, .generic:
            return [
                .init(label: "Bonus Idea", emoji: "🎁"),
                .init(label: "Try This Too", emoji: "🌱"),
                .init(label: "Real-World Use", emoji: "🌎"),
            ]
        default:
            return []
        }
    }

    /// Keywords that boost relevance for noun-phrase candidates.
    var affinityKeywords: [String] {
        switch self {
        case .math:      return ["add","sum","plus","subtract","minus","number","digit","place","line","equation","operator"]
        case .fractions: return ["fraction","half","quarter","third","whole","slice","decimal","percent","ratio"]
        case .geometry:  return ["shape","angle","side","triangle","square","circle","polygon","perimeter","area","volume","symmetry"]
        case .time:      return ["clock","hour","minute","calendar","time","schedule"]
        case .money:     return ["money","coin","dollar","cent","price","change"]
        case .reading:   return ["story","passage","character","plot","setting","theme","idea","detail","author","fiction"]
        case .writing:   return ["sentence","paragraph","noun","verb","adjective","essay","draft","topic","punctuation"]
        case .life:      return ["plant","animal","habitat","cell","ecosystem","food","cycle","species","leaf","root","flower"]
        case .earth:     return ["earth","sun","moon","planet","weather","rock","water","season","climate"]
        case .history:   return ["history","ancient","empire","war","peace","explorer","colony","timeline","map","government"]
        case .music:     return ["music","note","beat","rhythm","melody","scale","chord","tempo"]
        case .code:      return ["code","program","loop","function","variable","algorithm","bug","syntax"]
        case .art:       return ["color","paint","draw","shade","line","shape","texture","palette"]
        case .generic:   return []
        }
    }
}

// MARK: - Emoji decoration for arbitrary labels

extension ContentExtractor {

    /// Picks a fitting emoji for a topic label by keyword lookup, falling back
    /// to the subject default and then a deterministic hash-based pool.
    static func emojiFor(label: String, subject: Subject) -> String {
        let key = label.lowercased()
        for (kw, emoji) in topicEmojiMap {
            if key.contains(kw) { return emoji }
        }
        // Subject-default fallback
        let fallbackPool: [String]
        switch subject {
        case .math, .fractions:    fallbackPool = ["✨","➕","➖","✖️","➗","🧮","🔢"]
        case .geometry:            fallbackPool = ["🔷","🔺","🟦","⭕","🔶"]
        case .time:                fallbackPool = ["🕒","⏱️","📅","⌛"]
        case .money:               fallbackPool = ["🪙","💵","💰","💱"]
        case .reading:             fallbackPool = ["📖","📚","🔍","💡","🎭"]
        case .writing:             fallbackPool = ["✏️","📝","📄","🔠","🧹"]
        case .life:                fallbackPool = ["🌱","🦎","🐝","🍃","🦊","🐾"]
        case .earth:               fallbackPool = ["🪐","🌍","🌞","🌧️","🪨","💧"]
        case .history:             fallbackPool = ["🏛️","📜","⛵","🧭","🪶"]
        case .music:               fallbackPool = ["🎵","🎼","🥁","🎹","🎶"]
        case .code:                fallbackPool = ["💻","🐛","🔁","🔀","📦"]
        case .art:                 fallbackPool = ["🎨","🖌️","🖼️"]
        case .generic:             fallbackPool = ["✨","💫","⭐","🌟","🪐","🔭"]
        }
        let hash = abs(label.hashValue)
        return fallbackPool[hash % fallbackPool.count]
    }

    /// Curated keyword → emoji map. Order doesn't matter; longer keywords are
    /// listed first within each cluster so they win lookup against their roots
    /// (e.g. "fraction" before "ration").
    private static let topicEmojiMap: [(String, String)] = [
        // Math
        ("addition","➕"), ("adding","➕"), (" add","➕"), ("plus","➕"),
        ("subtract","➖"), ("minus","➖"),
        ("multiplication","✖️"), ("multiply","✖️"), ("times tables","✖️"), ("times","✖️"),
        ("division","➗"), ("divide","➗"), ("share","➗"),
        ("place value","🏠"), ("number line","📏"), ("counting","👆"),
        ("even","👯"), ("odd","👯"), ("digit","🔢"), ("regroup","🎒"), ("carry","🎒"),
        // Fractions / decimals
        ("fraction","🍕"), ("pizza","🍕"), ("slice","🍕"),
        ("half","🍰"), ("quarter","🍰"), ("third","🥧"),
        ("decimal","🔢"), ("percent","💯"), ("ratio","⚖️"),
        ("equivalent","🟰"), ("simplify","✂️"), ("mixed number","🥧"),
        // Geometry
        ("triangle","🔺"), ("square","🟦"), ("rectangle","🟦"), ("circle","⭕"),
        ("polygon","🔶"), ("hexagon","🔶"), ("pentagon","🔶"),
        ("symmetry","🦋"), ("angle","📐"), ("perimeter","📐"),
        ("area","🟩"), ("volume","🧊"), ("vertex","📌"), ("vertices","📌"),
        // Time / money
        ("clock","🕒"), ("hour","⏱️"), ("minute","⏱️"), ("calendar","📅"),
        ("elapsed","⌛"), ("am pm","🌗"),
        ("coin","🪙"), ("dollar","💵"), ("cent","🪙"), ("money","💰"),
        ("change","💱"), ("price","🏷️"),
        // Reading / writing
        ("phonics","🔤"), ("sight word","👀"), ("vocabulary","📒"),
        ("main idea","💡"), ("detail","🔍"), ("infer","🕵️"), ("clue","🕵️"),
        ("theme","🎭"), ("character","🧑"), ("setting","🏞️"), ("plot","🌪️"),
        ("summarize","📝"), ("summary","📝"),
        ("noun","🐶"), ("verb","🏃"), ("adjective","🌈"), ("adverb","💨"),
        ("paragraph","📄"), ("sentence","📝"), ("punctuation","🔠"),
        ("capital","🔠"), ("opinion","💭"), ("editing","🧹"),
        ("essay","📃"), ("draft","✏️"), ("topic sentence","📝"),
        // Life science
        ("plant","🌻"), ("animal","🦁"), ("habitat","🌳"),
        ("ecosystem","🐝"), ("life cycle","🦋"), ("photosynthesis","☀️"),
        ("cell","🔬"), ("food chain","🦊"), ("food web","🕸️"),
        ("pollinator","🐝"), ("adaptation","🐾"),
        ("leaf","🍃"), ("root","🌱"), ("seed","🌰"), ("flower","🌸"),
        // Earth / space
        ("water cycle","💧"), ("weather","⛅"), ("season","🍁"),
        ("rock","🪨"), ("mineral","💎"), ("planet","🪐"),
        ("solar system","🪐"), ("gravity","🍎"), ("galaxy","🌌"),
        ("moon","🌙"), ("sun","🌞"), ("star","⭐"), ("ocean","🌊"),
        ("volcano","🌋"), ("earthquake","🌐"),
        // History / civics
        ("ancient","🏛️"), ("rome","🏛️"), ("egypt","🔺"), ("pyramid","🔺"),
        ("explorer","⛵"), ("colony","🏘️"), ("revolution","🔔"),
        ("government","🏛️"), ("democracy","🤝"), ("map","🧭"),
        ("native","🪶"), ("timeline","📜"), ("treaty","📜"),
        // Music
        ("note","🎼"), ("rhythm","🥁"), ("beat","🥁"), ("melody","🎶"),
        ("piano","🎹"), ("guitar","🎸"), ("chord","🎵"), ("scale","🎵"),
        // Code
        ("loop","🔁"), ("variable","📦"), ("function","🛠️"),
        ("algorithm","🧮"), ("bug","🐛"), ("debug","🐛"),
        ("if then","🔀"), ("sequence","➡️"), ("boolean","🔀"),
        // Art
        ("color","🎨"), ("paint","🖌️"), ("draw","✏️"),
        ("texture","🪶"), ("palette","🎨"), ("perspective","🖼️"),
    ]
}
