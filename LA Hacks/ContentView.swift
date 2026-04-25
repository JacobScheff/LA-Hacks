//
//  ContentView.swift
//  LA Hacks
//
//  Hosts the Learning Galaxy — Polaris Learning Atlas.
//

import SwiftUI
import ZeticMLange
import AVFoundation

struct ContentView: View {    
    // UI States
    @State private var outputText: String = ""
    @State private var isProcessing: Bool = false
    @State private var downloadProgress: Float = 0.0
    @State private var prompt: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            Text(isProcessing ? "Processing..." : "Hello, world!")
            
            // Show download progress if downloading
            if isProcessing && downloadProgress > 0 && downloadProgress < 1.0 {
                ProgressView(value: downloadProgress, total: 1.0)
                    .progressViewStyle(.linear)
                    .padding()
                Text(String(format: "Downloading: %.1f%%", downloadProgress * 100))
            }
            
            // Display output text
            ScrollView {
                Text(outputText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(height: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            TextField("Enter Prompt", text: $prompt)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Button("Run") {
                guard !isProcessing else { return }
                
                isProcessing = true
                outputText = "Initializing and checking model..."
                downloadProgress = 0.0
                
                // Call our simplified function
                runModel(
                    prompt: prompt,
                    onDownload: { progress in
                        // Update progress bar
                        DispatchQueue.main.async {
                            self.downloadProgress = progress
                        }
                    },
                    onStream: { currentText in
                        // Update text UI as it streams
                        DispatchQueue.main.async {
                            self.outputText = currentText
                        }
                    },
                    onComplete: { error in
                        // Handle completion or errors
                        DispatchQueue.main.async {
                            self.isProcessing = false
                            if let error = error {
                                self.outputText = "Model error: \(error.localizedDescription)"
                            }
                        }
                    }
                )
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing)
            
            Button("Speak") {
                speak(transcript: prompt)
            }
        }
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
        .padding()
    }
    
}

#Preview {
    ContentView()
}
