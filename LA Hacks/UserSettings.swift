//
//  UserSettings.swift
//  LA Hacks
//
//  Persistent user settings + live progress (streak, XP, mastery, heatmap).
//

import SwiftUI

@Observable
final class UserSettings {

    /// Singleton so LessonView / MemoryStore can write progress without
    /// needing an Environment injection at every call site.
    static let shared = UserSettings()

    @ObservationIgnored
    private let defaults = UserDefaults.standard

    // MARK: - UserDefaults keys

    private static let avatarKey           = "userAvatar"
    private static let nameKey             = "explorerName"
    private static let gradeKey            = "explorerGrade"
    private static let languageKey          = "appLanguage"
    private static let notifOnKey          = "notifOn"
    private static let notifTimeKey        = "notifTime"
    private static let currentStreakKey    = "currentStreak"
    private static let longestStreakKey    = "longestStreak"
    private static let lastStudyDateKey    = "lastStudyDate"
    private static let totalXPKey          = "totalXP"
    private static let dailyXPKey          = "dailyXP"
    private static let starMasteryKey      = "starMastery"
    private static let unlockedStickersKey        = "unlockedStickers"
    private static let stickerDatesKey            = "stickerEarnedDates"
    private static let seededKey                  = "hasSeededInitialData"
    private static let lessonsCompletedKey        = "lessonsCompleted"
    private static let perfectLessonsKey          = "perfectLessons"
    private static let hintFreeLessonsKey         = "hintFreeLessons"
    private static let quickLessonsKey            = "quickLessons"
    private static let visitedNodeIdsKey          = "visitedNodeIds"
    private static let visitedConstellationIdsKey = "visitedConstellationIds"
    private static let correctStreakKey           = "correctStreakOverall"

    // MARK: - Settings

    var avatar: String {
        didSet { defaults.set(avatar, forKey: Self.avatarKey) }
    }
    var explorerName: String {
        didSet {
            defaults.set(explorerName, forKey: Self.nameKey)
            if notifOn {
                NotificationManager.shared.scheduleDailyReminder(time: notifTime, name: explorerName)
            }
        }
    }
    var grade: String {
        didSet { defaults.set(grade, forKey: Self.gradeKey) }
    }
    var language: String {
        didSet {
            NSLog("[i18n] UserSettings.language didSet: \(oldValue) -> \(language)")
            defaults.set(language, forKey: Self.languageKey)
            Bundle.setLanguage(language)
        }
    }
    var locale: Locale { Locale(identifier: language) }
    var notifOn: Bool {
        didSet {
            defaults.set(notifOn, forKey: Self.notifOnKey)
            NotificationManager.shared.update(enabled: notifOn, time: notifTime, name: explorerName)
        }
    }
    var notifTime: String {
        didSet {
            defaults.set(notifTime, forKey: Self.notifTimeKey)
            if notifOn {
                NotificationManager.shared.scheduleDailyReminder(time: notifTime, name: explorerName)
            }
        }
    }

    // MARK: - Progress

    var currentStreak: Int {
        didSet { defaults.set(currentStreak, forKey: Self.currentStreakKey) }
    }
    var longestStreak: Int {
        didSet { defaults.set(longestStreak, forKey: Self.longestStreakKey) }
    }
    /// ISO date of the last day the user completed a lesson ("2026-04-26").
    var lastStudyDate: String? {
        didSet { defaults.set(lastStudyDate, forKey: Self.lastStudyDateKey) }
    }
    var totalXP: Int {
        didSet { defaults.set(totalXP, forKey: Self.totalXPKey) }
    }
    /// Date string → XP earned that day. Drives the heatmap.
    var dailyXP: [String: Int] {
        didSet { saveJSON(dailyXP, forKey: Self.dailyXPKey) }
    }
    /// Star node ID → mastery 0.0–1.0. Updated after every lesson.
    var starMastery: [String: Double] {
        didSet { saveJSON(starMastery, forKey: Self.starMasteryKey) }
    }
    /// IDs of stickers the user has earned.
    var unlockedStickers: Set<String> {
        didSet { saveJSON(Array(unlockedStickers), forKey: Self.unlockedStickersKey) }
    }
    /// Sticker ID → display date string ("Apr 26").
    var stickerEarnedDates: [String: String] {
        didSet { saveJSON(stickerEarnedDates, forKey: Self.stickerDatesKey) }
    }
    var lessonsCompleted: Int {
        didSet { defaults.set(lessonsCompleted, forKey: Self.lessonsCompletedKey) }
    }
    var perfectLessonsCount: Int {
        didSet { defaults.set(perfectLessonsCount, forKey: Self.perfectLessonsKey) }
    }
    var hintFreeLessonsCount: Int {
        didSet { defaults.set(hintFreeLessonsCount, forKey: Self.hintFreeLessonsKey) }
    }
    var quickLessonsCount: Int {
        didSet { defaults.set(quickLessonsCount, forKey: Self.quickLessonsKey) }
    }
    var visitedNodeIds: Set<String> {
        didSet { saveJSON(Array(visitedNodeIds), forKey: Self.visitedNodeIdsKey) }
    }
    var visitedConstellationIds: Set<String> {
        didSet { saveJSON(Array(visitedConstellationIds), forKey: Self.visitedConstellationIdsKey) }
    }
    var correctStreakOverall: Int {
        didSet { defaults.set(correctStreakOverall, forKey: Self.correctStreakKey) }
    }
    /// Transient — populated by checkStickerUnlocks(), read by LessonView immediately after recordStudySession().
    @ObservationIgnored var recentlyUnlocked: [String] = []

    // MARK: - Computed: level & XP curve

    private static let xpThresholds = [0, 200, 500, 900, 1400, 2000, 2700, 3600, 4600, 6000]

    var level: Int {
        for (i, t) in Self.xpThresholds.enumerated().reversed() {
            if totalXP >= t { return i + 1 }
        }
        return 1
    }

    var levelTitle: String {
        switch level {
        case 1:  return "Star Seeker"
        case 2:  return "Cosmic Cadet"
        case 3:  return "Nova Scout"
        case 4:  return "Star Captain"
        case 5:  return "Galaxy Pilot"
        case 6:  return "Nebula Knight"
        case 7:  return "Astro Master"
        case 8:  return "Constellation Lord"
        case 9:  return "Universe Champion"
        default: return "Legend of the Stars"
        }
    }

    var xpForCurrentLevel: Int {
        Self.xpThresholds[min(level - 1, Self.xpThresholds.count - 1)]
    }
    var xpForNextLevel: Int {
        level < Self.xpThresholds.count ? Self.xpThresholds[level] : Self.xpThresholds.last! + 1000
    }
    /// 0.0–1.0 progress within the current level band.
    var xpProgress: Double {
        let span = xpForNextLevel - xpForCurrentLevel
        guard span > 0 else { return 1.0 }
        return min(1.0, Double(totalXP - xpForCurrentLevel) / Double(span))
    }

    // MARK: - Mastery thresholds & stage computation

    static let twinklingThreshold: Double = 0.33
    static let shiningThreshold: Double   = 0.65

    /// Returns the live MasteryStage for a node given its lock flag and neighbor node IDs.
    func stage(for nodeId: String, initiallyLocked: Bool, neighborIds: [String]) -> MasteryStage {
        if initiallyLocked {
            let neighborReady = neighborIds.contains { (starMastery[$0] ?? 0) >= Self.twinklingThreshold }
            if !neighborReady { return .locked }
        }
        let m = starMastery[nodeId] ?? 0.0
        if m >= Self.shiningThreshold   { return .shining }
        if m >= Self.twinklingThreshold { return .twinkling }
        return .sleepy
    }

    /// Number of stars that have reached Shining mastery.
    var masteredStarsCount: Int { starMastery.values.filter { $0 >= Self.shiningThreshold }.count }

    // MARK: - Init

    init() {
        self.avatar       = defaults.string(forKey: Self.avatarKey) ?? "🦊"
        self.explorerName = defaults.string(forKey: Self.nameKey) ?? "Maya the Brave"
        self.grade        = defaults.string(forKey: Self.gradeKey) ?? "4th"
        let savedLang     = defaults.string(forKey: Self.languageKey) ?? "en"
        self.language     = savedLang == "English" ? "en" : savedLang  // migrate old display-name value
        self.notifOn      = defaults.object(forKey: Self.notifOnKey) as? Bool ?? true
        self.notifTime    = defaults.string(forKey: Self.notifTimeKey) ?? "18:00"

        self.currentStreak = defaults.integer(forKey: Self.currentStreakKey)
        self.longestStreak = defaults.integer(forKey: Self.longestStreakKey)
        self.lastStudyDate = defaults.string(forKey: Self.lastStudyDateKey)
        self.totalXP       = defaults.integer(forKey: Self.totalXPKey)
        self.dailyXP       = Self.loadJSON([String: Int].self,    key: Self.dailyXPKey,          defaults: defaults) ?? [:]
        self.starMastery   = Self.loadJSON([String: Double].self, key: Self.starMasteryKey,      defaults: defaults) ?? [:]
        let sArr           = Self.loadJSON([String].self,         key: Self.unlockedStickersKey, defaults: defaults) ?? []
        self.unlockedStickers   = Set(sArr)
        self.stickerEarnedDates = Self.loadJSON([String: String].self, key: Self.stickerDatesKey, defaults: defaults) ?? [:]
        self.lessonsCompleted     = defaults.integer(forKey: Self.lessonsCompletedKey)
        self.perfectLessonsCount  = defaults.integer(forKey: Self.perfectLessonsKey)
        self.hintFreeLessonsCount = defaults.integer(forKey: Self.hintFreeLessonsKey)
        self.quickLessonsCount    = defaults.integer(forKey: Self.quickLessonsKey)
        let vNodeArr              = Self.loadJSON([String].self, key: Self.visitedNodeIdsKey, defaults: defaults) ?? []
        self.visitedNodeIds       = Set(vNodeArr)
        let vConstArr             = Self.loadJSON([String].self, key: Self.visitedConstellationIdsKey, defaults: defaults) ?? []
        self.visitedConstellationIds = Set(vConstArr)
        self.correctStreakOverall = defaults.integer(forKey: Self.correctStreakKey)

        // Seed realistic demo data on first launch
        if !defaults.bool(forKey: Self.seededKey) {
            self.currentStreak = 12
            self.longestStreak = 18
            self.totalXP = 1240
            self.unlockedStickers = [
                "pizza_pro", "sharp_shoot", "times_whiz",
                "quick_fox", "symm_star", "rocket_kid", "streak_7"
            ]
            self.stickerEarnedDates = [
                "pizza_pro":   "Apr 12",
                "sharp_shoot": "Apr 8",
                "times_whiz":  "Mar 30",
                "quick_fox":   "Apr 1",
                "symm_star":   "Apr 18",
                "rocket_kid":  "Jan 10",
                "streak_7":    "Apr 15",
            ]
            // Seed a realistic heatmap: last 12 days studied (streak),
            // ~65% density before that.
            var seedXP: [String: Int] = [:]
            let cal = Calendar.current
            let today = Date()
            let recentXPs = [80, 120, 60, 95, 150, 70, 200, 110, 85, 130, 75, 165]
            for i in 0..<12 {
                if let d = cal.date(byAdding: .day, value: -i, to: today) {
                    seedXP[Self.isoDateString(d)] = recentXPs[i]
                }
            }
            let oldXPs = [50, 80, 100, 120, 150, 60, 90]
            for i in 13..<84 {
                if let d = cal.date(byAdding: .day, value: -i, to: today),
                   (i * 17 + 3) % 10 < 7 {
                    seedXP[Self.isoDateString(d)] = oldXPs[i % 7]
                }
            }
            self.dailyXP = seedXP
            // Seed star mastery so demo nodes show correct stages (matching original static statuses)
            self.starMastery = [
                // Shining (≥ 0.65) — formerly .mastered
                "count":0.9, "place":0.85, "add":0.88, "sub":0.80, "mul":0.92, "div":0.82, "odd":0.78,
                "half":0.90, "frac":0.85,
                "tri":0.85, "sq":0.90, "circ":0.88, "sym":0.80,
                "clock":0.95, "min":0.80, "cal":0.85, "elapsed":0.78, "rasalas":0.70, "algenubi":0.70,
                "coins":0.82, "change":0.75, "dollar":0.90,
                "phon":0.95, "sight":0.82, "flu":0.80,
                "caps":0.90, "noun":0.85, "sent":0.82,
                "living":0.82, "plant":0.80, "animal":0.78,
                "sun":0.90,
                "ancient":0.85, "rastaban":0.78, "maps":0.80, "nu":0.72,
                // Twinkling (0.33–0.65) — formerly .learning
                "equiv":0.55, "compare":0.45, "poly":0.58, "angle":0.40,
                "main":0.50, "detail":0.45,
                "adj":0.50, "para":0.45,
                "habitat":0.58, "food":0.40,
                "season":0.50, "weather":0.52,
                "native":0.50, "explor":0.40,
                // Sleepy (0–0.33) — formerly .gap
                "addfrac":0.20, "mixed":0.18, "simplify":0.18,
                "area":0.22, "vol":0.15,
                "infer":0.22, "theme":0.15,
                "story":0.20, "opin":0.15, "edit":0.10,
                "cycle":0.22, "eco":0.15,
                "water":0.22, "rocks":0.15, "planet":0.18,
                "colony":0.22, "rev":0.15, "gov":0.18,
            ]
            self.visitedNodeIds = Set(self.starMastery.keys)
            self.visitedConstellationIds = ["numbers","fractions","shapes","time","reading","writing","life","earth","history"]
            defaults.set(true, forKey: Self.seededKey)
        }
        Bundle.setLanguage(self.language)   // activate persisted language after all properties are set
    }

    // MARK: - Record study session

    /// Call this at the end of every lesson. Updates streak, XP, mastery,
    /// heatmap, and fires sticker unlock checks.
    func recordStudySession(xpEarned: Int, nodeId: String, correctCount: Int, totalCount: Int,
                            hintsUsed: Int = 0, constellationId: String? = nil) {
        let today = Self.isoDateString(Date())

        // Streak
        if let last = lastStudyDate {
            if last == today {
                // Already counted — just add XP below
            } else if isYesterday(last) {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
                longestStreak = max(longestStreak, 1)
            }
        } else {
            currentStreak = 1
            longestStreak = max(longestStreak, 1)
        }
        lastStudyDate = today

        // XP + heatmap
        totalXP += xpEarned
        dailyXP[today] = (dailyXP[today] ?? 0) + xpEarned

        // Star mastery
        if !nodeId.isEmpty, totalCount > 0 {
            let score = Double(correctCount) / Double(totalCount)
            let gain: Double = score >= 0.9 ? 0.40 : score >= 0.75 ? 0.25 : score >= 0.5 ? 0.15 : 0.05
            starMastery[nodeId] = min(1.0, (starMastery[nodeId] ?? 0.0) + gain)
        }

        // Lesson tracking
        lessonsCompleted += 1
        if !nodeId.isEmpty { visitedNodeIds.insert(nodeId) }
        if let cId = constellationId, !cId.isEmpty { visitedConstellationIds.insert(cId) }

        if totalCount > 0 {
            let perfect = correctCount == totalCount
            if perfect {
                perfectLessonsCount += 1
                correctStreakOverall += correctCount
                if hintsUsed == 0 { quickLessonsCount += 1 }
            } else {
                correctStreakOverall = 0
            }
            if hintsUsed == 0 { hintFreeLessonsCount += 1 }
        }

        checkStickerUnlocks()
    }

    private func checkStickerUnlocks() {
        recentlyUnlocked = []
        let date = Self.shortDateString(Date())
        func unlock(_ id: String) {
            guard !unlockedStickers.contains(id) else { return }
            unlockedStickers.insert(id)
            stickerEarnedDates[id] = date
            recentlyUnlocked.append(id)
        }

        let mastered = masteredStarsCount
        let t = Self.shiningThreshold
        let hour = Calendar.current.component(.hour, from: Date())

        // ── Streaks ──────────────────────────────────────────────────────
        if currentStreak >= 7  { unlock("streak_7") }
        if currentStreak >= 14 { unlock("streak_14") }
        if currentStreak >= 21 { unlock("hot_streak") }
        if currentStreak >= 30 { unlock("streak_30") }
        if currentStreak >= 60 { unlock("iron_will") }

        // ── Math mastery by node ─────────────────────────────────────────
        if (starMastery["half"] ?? 0) >= t || (starMastery["addfrac"] ?? 0) >= t { unlock("pizza_pro") }
        if (starMastery["mul"] ?? 0) >= t { unlock("times_whiz") }
        if (starMastery["tri"] ?? 0) >= t && (starMastery["area"] ?? 0) >= t { unlock("geo_gem") }

        // ── Total mastered stars ─────────────────────────────────────────
        if mastered >= 5  { unlock("symm_star") }
        if mastered >= 10 { unlock("numbers_boss") }
        if mastered >= 15 { unlock("cool_cube") }
        if mastered >= 20 { unlock("star_20") }
        if mastered >= 30 { unlock("star_captain") }
        if mastered >= 40 { unlock("galaxy_brain") }
        if mastered >= 45 { unlock("all_stars") }

        // ── Reading mastery ──────────────────────────────────────────────
        if (starMastery["main"] ?? 0) >= t && (starMastery["habitat"] ?? 0) >= t { unlock("word_wiz") }

        // ── XP milestones ────────────────────────────────────────────────
        if totalXP >= 500  { unlock("calc_wizard") }
        if totalXP >= 1000 { unlock("number_cruncher") }
        if totalXP >= 2000 { unlock("xp_master") }

        // ── Perfect lessons ──────────────────────────────────────────────
        if perfectLessonsCount >= 1 { unlock("perfect_score") }
        if perfectLessonsCount >= 3 { unlock("frac_king") }

        // ── Hint-free lessons ────────────────────────────────────────────
        if hintFreeLessonsCount >= 3 { unlock("speed_read") }
        if hintFreeLessonsCount >= 5 { unlock("no_hints") }
        if hintFreeLessonsCount >= 7 { unlock("detective") }

        // ── Quick completions (perfect + no hints) ───────────────────────
        if quickLessonsCount >= 1 { unlock("quick_fox") }
        if quickLessonsCount >= 1 { unlock("speed_demon") }

        // ── Lessons completed ────────────────────────────────────────────
        if lessonsCompleted >= 1  { unlock("first_step") }
        if lessonsCompleted >= 5  { unlock("story_star") }
        if lessonsCompleted >= 10 { unlock("bookworm") }
        if lessonsCompleted >= 25 { unlock("scholar") }
        if lessonsCompleted >= 30 { unlock("hist_hero") }
        if lessonsCompleted >= 50 { unlock("nova_friend") }

        // ── Visited nodes / constellations ──────────────────────────────
        if visitedNodeIds.count >= 1  { unlock("rocket_kid") }
        if visitedNodeIds.count >= 3  { unlock("galaxy_voyager") }
        if visitedNodeIds.count >= 10 { unlock("space_cadet") }
        if visitedNodeIds.count >= 15 { unlock("cosmo_scout") }
        if visitedConstellationIds.count >= 3 { unlock("deep_space") }
        if visitedConstellationIds.count >= 5 { unlock("universe_child") }

        // ── Correct-answer streak ────────────────────────────────────────
        if correctStreakOverall >= 10 { unlock("sharp_shoot") }
        if correctStreakOverall >= 20 { unlock("nova_apprentice") }

        // ── Time-of-day ──────────────────────────────────────────────────
        if hour < 8  { unlock("early_bird") }
        if hour >= 21 { unlock("night_owl") }
        if hour == 0  { unlock("midnight_nova") }

        // ── Cross-category rainbow ───────────────────────────────────────
        let mathIds: Set<String>    = ["pizza_pro","sharp_shoot","times_whiz","cool_cube","geo_gem","frac_king","speed_demon","numbers_boss","calc_wizard","perfect_score","number_cruncher"]
        let readingIds: Set<String> = ["word_wiz","story_star","speed_read","detective","bookworm","no_hints","scholar"]
        let streakIds: Set<String>  = ["streak_7","streak_14","quick_fox","hot_streak","streak_30","iron_will","symm_star","early_bird","night_owl"]
        let explorerIds: Set<String> = ["rocket_kid","galaxy_voyager","space_cadet","star_20","star_captain","cosmo_scout","deep_space","universe_child","galaxy_brain","first_step"]
        if !mathIds.isDisjoint(with: unlockedStickers) &&
           !readingIds.isDisjoint(with: unlockedStickers) &&
           !streakIds.isDisjoint(with: unlockedStickers) &&
           !explorerIds.isDisjoint(with: unlockedStickers) {
            unlock("rainbow")
        }

        // ── Sticker-count milestones (check last so they count newly earned ones) ──
        let count = unlockedStickers.count
        if count >= 15 { unlock("star_collector") }
        if count >= 30 { unlock("legendary_path") }
        if count >= 35 { unlock("champ") }
    }

    // MARK: - Heatmap helpers

    /// 12-column × 7-row grid of XP values, aligned to a Sun–Sat calendar week.
    /// Column 0 = oldest week, column 11 = current week.
    /// Row 0 = Sunday, row 6 = Saturday.
    /// -1 means a future cell (not yet reached).
    func heatmapGrid() -> [[Int]] {
        let cal = Calendar.current
        let today = Date()
        // Calendar.weekday: 1=Sun … 7=Sat → convert to 0-based
        let weekday = cal.component(.weekday, from: today) - 1
        let anchor = 11 * 7 + weekday   // index of today in a flat 84-cell array

        var grid: [[Int]] = []
        for w in 0..<12 {
            var col: [Int] = []
            for d in 0..<7 {
                let offset = w * 7 + d - anchor   // negative=past, 0=today, positive=future
                if offset > 0 {
                    col.append(-1)
                } else if let date = cal.date(byAdding: .day, value: offset, to: today) {
                    col.append(dailyXP[Self.isoDateString(date)] ?? 0)
                } else {
                    col.append(-1)
                }
            }
            grid.append(col)
        }
        return grid
    }

    /// Number of days in the last 84 days where any XP was earned.
    var studiedDaysInLast84: Int {
        let cal = Calendar.current
        let today = Date()
        return (0..<84).filter { i in
            guard let d = cal.date(byAdding: .day, value: -(83 - i), to: today) else { return false }
            return (dailyXP[Self.isoDateString(d)] ?? 0) > 0
        }.count
    }

    /// Days in the last 84 where XP ≥ 150 (a "Star Day").
    var starDaysInLast84: Int {
        let cal = Calendar.current
        let today = Date()
        return (0..<84).filter { i in
            guard let d = cal.date(byAdding: .day, value: -(83 - i), to: today) else { return false }
            return (dailyXP[Self.isoDateString(d)] ?? 0) >= 150
        }.count
    }

    // MARK: - Private helpers

    static func isoDateString(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f.string(from: date)
    }

    private func isYesterday(_ dateStr: String) -> Bool {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        guard let d = f.date(from: dateStr) else { return false }
        return Calendar.current.isDateInYesterday(d)
    }

    static func shortDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    private func saveJSON<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func loadJSON<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
