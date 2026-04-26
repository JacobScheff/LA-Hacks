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

    private static let avatarKey    = "userAvatar"
    private static let nameKey      = "explorerName"
    private static let gradeKey     = "explorerGrade"
    private static let notifOnKey   = "notifOn"
    private static let notifTimeKey = "notifTime"

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

    init() {
        self.avatar       = defaults.string(forKey: Self.avatarKey) ?? "🦊"
        self.explorerName = defaults.string(forKey: Self.nameKey) ?? "Maya the Brave"
        self.grade        = defaults.string(forKey: Self.gradeKey) ?? "4th"
        self.notifOn      = defaults.object(forKey: Self.notifOnKey) as? Bool ?? true
        self.notifTime    = defaults.string(forKey: Self.notifTimeKey) ?? "18:00"
    }
}
