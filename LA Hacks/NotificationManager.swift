//
//  NotificationManager.swift
//  LA Hacks
//

import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let identifier = "dailyLessonReminder"

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // Show banner + play sound even when the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion?(granted) }
        }
    }

    func scheduleDailyReminder(time: String, name: String) {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Time to explore! 🚀"
        content.body = "Hey \(name), your daily lesson is waiting. Come light up some stars!"
        content.sound = .default

        var components = DateComponents()
        components.hour = parts[0]
        components.minute = parts[1]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func update(enabled: Bool, time: String, name: String) {
        if enabled {
            scheduleDailyReminder(time: time, name: name)
        } else {
            cancelReminder()
        }
    }

    /// Fires an immediate notification celebrating a newly earned sticker.
    func scheduleStickerEarnedNotification(name: String, stickerName: String, emoji: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(emoji) New sticker unlocked!"
        content.body = "Hey \(name), you just earned the \(stickerName) sticker. Check your collection!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let id = "stickerEarned_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
