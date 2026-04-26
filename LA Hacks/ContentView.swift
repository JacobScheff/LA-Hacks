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
            Button("Speak 11Labs") {
                speak11Labs(transcript: "A black hole is a region of spacetime where gravity is so strong, nothing can escape from it, even including light. Black holes exist when spacetime gets very curved an object. Once objects enter the event horizon, it is impossible to escape.")
            }
            LearningGalaxyView()
                .onAppear {
                    do {
                        // Initialize audio synthesizer
                        let session = AVAudioSession.sharedInstance()
                        try session.setCategory(.playback, mode: .default, options: [])
                        try session.setActive(true)
                    } catch {
                        print("Failed to set audio session category: \(error)")
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
