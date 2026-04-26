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
    
    @State var startedMonitor = false

    var body: some View {
        if !onboarded {
            Onboard()
                .onAppear {
                    if (!startedMonitor) {
                        monitor.pathUpdateHandler = { path in
                            if path.status == .satisfied {
                                isConnected = true
                            } else {
                                isConnected = false
                            }
                        }
                        monitor.start(queue: queue)
                        startedMonitor = true
                    }
                }
        } else {
            LearningGalaxyView()
                .onAppear {
                    do {
                        // Initialize audio synthesizer
                        let session = AVAudioSession.sharedInstance()
                        try session.setCategory(.playback, mode: .default, options: [])
                        try session.setActive(true)
                        
                        if (!startedMonitor) {
                            monitor.pathUpdateHandler = { path in
                                if path.status == .satisfied {
                                    isConnected = true
                                } else {
                                    isConnected = false
                                }
                            }
                            monitor.start(queue: queue)
                            startedMonitor = true
                        }
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
