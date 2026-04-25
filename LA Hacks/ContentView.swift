//
//  ContentView.swift
//  LA Hacks
//
//  Hosts the Learning Galaxy — Polaris Learning Atlas.
//

import Foundation
import SwiftUI
import ZeticMLange
import AVFoundation

struct ContentView: View {
    @AppStorage("onboarded")
    private var onboarded: Bool = false

    var body: some View {
        if !onboarded {
            Onboard()
        } else {
            Button("Restart") {
                onboarded = false
            }
            LearningGalaxyView()
        }
    }
}

#Preview {
    ContentView()
}
