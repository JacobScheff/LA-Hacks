//
//  NotificationManager.swift
//  LA Hacks
//

import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let identifier = "dailyLessonReminder"

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
}
