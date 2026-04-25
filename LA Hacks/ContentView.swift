//
//  ContentView.swift
//  LA Hacks
//
//  Created by Jacob Scheff on 4/24/26.
//

import SwiftUI
import ZeticMLange

struct ContentView: View {
    @State private var mem: Int = 0
    let personalToken = "ztp_92c5cc5cc8024dc89ce028f7bd2aa11d"
    
    // Added states to show what is happening on screen
    @State private var outputText: String = ""
    @State private var isProcessing: Bool = false
    @State private var downloadProgress: Float = 0.0

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
            
            Button("Run") {
                guard !isProcessing else { return }
                isProcessing = true
                outputText = "Initializing and checking model..."
                downloadProgress = 0.0
                
                // ⚠️ Task.detached FORCES this off the Main Thread
                Task.detached {
                    do {
                        let model = try ZeticMLangeLLMModel(
                            personalKey: personalToken, // using the struct's property directly
                            name: "changgeun/gemma-4-E2B-it",
                            version: 1,
                            modelMode: .RUN_AUTO,
                            onDownload: { progress in
                                // Update progress on the main thread safely
                                DispatchQueue.main.async {
                                    self.downloadProgress = progress
                                }
                            }
                        )

                        await MainActor.run {
                            self.outputText = "Model loaded! Generating response..."
                        }

                        // Initiate generation context
                        try model.run("Hello!")

                        var buffer = ""

                        // Asynchronous Token Consumption Loop
                        while true {
                            let waitResult = model.waitForNextToken()
                            let token = waitResult.token
                            let generatedTokens = waitResult.generatedTokens

                            if generatedTokens == 0 {
                                break
                            }

                            buffer.append(token)
                            
                            let currentOutput = buffer
                            await MainActor.run {
                                self.outputText = currentOutput
                            }
                        }

                        await MainActor.run {
                            self.isProcessing = false
                        }
                        print("Finished: \n\(buffer)")
                        
                    } catch {
                        await MainActor.run {
                            self.outputText = "Model error: \(error.localizedDescription)"
                            self.isProcessing = false
                        }
                        print("Model error: \(error)")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
