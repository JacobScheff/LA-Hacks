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
import Network

struct ContentView: View {
    @AppStorage("onboarded")
    private var onboarded: Bool = false
    
    @AppStorage("isConnected")
    private var isConnected: Bool = false
    
    // Monitor if connected to wifi
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "NetworkMonitor")

    var body: some View {
        // Empty element to run code from
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                monitor.pathUpdateHandler = { path in
                    if path.status == .satisfied {
                        isConnected = true
                    } else {
                        isConnected = false
                    }
                }
                monitor.start(queue: queue)
            }
                
        if !onboarded {
            Onboard()
        } else {
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
