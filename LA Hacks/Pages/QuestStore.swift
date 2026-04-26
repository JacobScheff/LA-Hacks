//
//  QuestStore.swift
//  LA Hacks
//
//  Singleton that tracks which quests were completed today and total XP earned.
//  Listens for "LessonCompleted" notifications posted by LessonView.celebrate().
//  Uses a date-keyed UserDefaults key so progress resets at midnight automatically.
//

import Foundation
import Combine

// MARK: - Notification name

extension Notification.Name {
    static let lessonCompleted = Notification.Name("LessonCompleted")
}

// MARK: - QuestStore

@MainActor
final class QuestStore: ObservableObject {

    static let shared = QuestStore()

    // MARK: Published state

    /// Node IDs whose lessons completed today.
    @Published private(set) var completedNodeIds: Set<String> = []

    /// Total XP earned across all completed quests today.
    @Published private(set) var totalXPToday: Int = 0

    // MARK: - Persistence keys

    private var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private var completedKey: String { "qc_ids_\(todayString)" }
    private var xpKey: String { "qc_xp_\(todayString)" }

    // MARK: - Init

    private init() {
        load()

        // Listen for lesson-completed events posted by LessonView.celebrate()
        NotificationCenter.default.addObserver(
            forName: .lessonCompleted,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            let nodeId = note.userInfo?["nodeId"] as? String ?? ""
            let xp = note.userInfo?["xp"] as? Int ?? 0
            Task { @MainActor in self.markDone(nodeId: nodeId, xp: xp) }
        }
    }

    // MARK: - Public API

    /// Returns true if the quest for the given nodeId was completed today.
    func isCompleted(_ nodeId: String) -> Bool {
        completedNodeIds.contains(nodeId)
    }

    /// Marks a quest as done and persists it.
    func markDone(nodeId: String, xp: Int) {
        guard !nodeId.isEmpty else { return }
        guard !completedNodeIds.contains(nodeId) else { return }
        completedNodeIds.insert(nodeId)
        totalXPToday += xp
        save()
    }

    // MARK: - Persistence

    private func load() {
        let ids = UserDefaults.standard.stringArray(forKey: completedKey) ?? []
        completedNodeIds = Set(ids)
        totalXPToday = UserDefaults.standard.integer(forKey: xpKey)
    }

    private func save() {
        UserDefaults.standard.set(Array(completedNodeIds), forKey: completedKey)
        UserDefaults.standard.set(totalXPToday, forKey: xpKey)
    }
}
