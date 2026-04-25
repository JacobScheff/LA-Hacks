//
//  LA_HacksApp.swift
//  LA Hacks
//
//  Created by Jacob Scheff on 4/24/26.
//

import SwiftUI

@main
struct LA_HacksApp: App {
    @State private var userSettings = UserSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(userSettings)
        }
    }
}
