//
//  LA_HacksApp.swift
//  LA Hacks
//
//  Created by Jacob Scheff on 4/24/26.
//

import SwiftUI

@main
struct LA_HacksApp: App {
    @State private var userSettings = UserSettings.shared

    var body: some Scene {
        WindowGroup {
            let _ = NSLog("[i18n] WindowGroup body re-evaluated  language=\(userSettings.language)  locale.id=\(userSettings.locale.identifier)")
            ContentView()
                .environment(userSettings)
                .environment(\.locale, userSettings.locale)
                // Force a full view-tree rebuild whenever the language changes.
                // The runtime-bundle swizzle in `LocaleBundle.swift` re-routes
                // `Bundle.main.localizedString(forKey:…)` to our translation table,
                // but SwiftUI has no localization resources on disk and so won't
                // re-invoke that lookup on a simple environment change. Re-keying
                // the root view causes SwiftUI to discard cached localized strings
                // and run a fresh localization pass against the swizzled bundle.
                .id(userSettings.language)
                .onAppear {
                    NotificationManager.shared.requestPermission { granted in
                        guard granted, userSettings.notifOn else { return }
                        NotificationManager.shared.scheduleDailyReminder(
                            time: userSettings.notifTime,
                            name: userSettings.explorerName
                        )
                    }
                }
        }
    }
}
