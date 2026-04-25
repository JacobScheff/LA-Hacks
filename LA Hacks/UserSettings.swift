//
//  UserSettings.swift
//  LA Hacks
//
//  Persistent user settings manager
//

import SwiftUI

@Observable
final class UserSettings {
    @ObservationIgnored
    private let defaults = UserDefaults.standard

    private static let avatarKey = "userAvatar"
    private static let nameKey = "explorerName"
    private static let gradeKey = "explorerGrade"

    var avatar: String {
        didSet { defaults.set(avatar, forKey: Self.avatarKey) }
    }

    var explorerName: String {
        didSet { defaults.set(explorerName, forKey: Self.nameKey) }
    }

    var grade: String {
        didSet { defaults.set(grade, forKey: Self.gradeKey) }
    }

    init() {
        self.avatar = defaults.string(forKey: Self.avatarKey) ?? "🦊"
        self.explorerName = defaults.string(forKey: Self.nameKey) ?? "Maya the Brave"
        self.grade = defaults.string(forKey: Self.gradeKey) ?? "4th"
    }
}
