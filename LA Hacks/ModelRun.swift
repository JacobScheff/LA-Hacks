//
//  ModelRun.swift
//  LA Hacks
//
//  Created by Jacob Scheff on 4/24/26.
//

import Foundation
import SwiftUI
import ZeticMLange
import AVFoundation

// MARK: - Global Shared Model
// Model is declared only once to avoid 5-10s memory initialization between every message
var sharedModel: ZeticMLangeLLMModel?

// MARK: - Speech Synthesizer
var synthesizer = AVSpeechSynthesizer()

// MARK: - Model Runner Function

/// Runs the LLM in a detached background task and reports back via callbacks
/// Runs the LLM in a detached background task and reports back via callbacks
func runModel(
    prompt: String,
    onDownload: @escaping (Float) -> Void,
    onStream: @escaping (String) -> Void,
    onComplete: @escaping (Error?) -> Void
) {
    @AppStorage("onboarded")
    var onboarded: Bool = false
    
    @AppStorage("isConnected")
    var isConnected: Bool = false
    
    /// If the device is connected to wifi and the user is already onboarded (model is already downloaded and this call is not an attempt to download the local model), then use the Google Gemma API. Otherwise, run the device locally with Zetic AI.
    
    if isConnected {
        print("Calling Model Run With Google Gemma API")
        runModelCloud(prompt: prompt, onStream: onStream, onComplete: onComplete)
        return
    }
    
    print("Calling Model Run With Zetic AI")
    
    Task.detached {
        do {
            // Initialize Model ONLY if it hasn't been created yet
            if sharedModel == nil {
                sharedModel = try ZeticMLangeLLMModel(
                    personalKey: personalToken,
                    name: "changgeun/gemma-4-E2B-it",
                    version: 1,
                    modelMode: LLMModelMode.RUN_SPEED,
                    onDownload: { progress in
                        onDownload(progress)
                    },
                )
            }

            // Safely unwrap our cached model
            guard let model = sharedModel else { return }

            // Start Generation
            try model.run(prompt)
            var buffer = ""

            // Streaming Loop
            while true {
                let waitResult = model.waitForNextToken()

                if waitResult.generatedTokens == 0 {
                    break
                }

                buffer.append(waitResult.token)
                
                // Filter out inline thinking tags in case the local model outputs them
                onStream(filterThinkingTags(from: buffer))
            }

            // Signal Success
            onComplete(nil)
            print("Finished generation successfully.")

        } catch {
            print("Model error: \(error)")
            onComplete(error)
        }
    }
}

func speak(transcript: String) {
    // Create an utterance.
    let utterance = AVSpeechUtterance(string: transcript)

    // Configure the utterance.
    utterance.rate = 0.57
    utterance.pitchMultiplier = 0.8
    utterance.postUtteranceDelay = 0.2
    utterance.volume = 0.8

    // Retrieve the British English voice.
    let voice = AVSpeechSynthesisVoice(language: "en-GB")

    // Assign the voice to the utterance.
    utterance.voice = voice

    // Tell the synthesizer to speak the utterance.
    synthesizer.speak(utterance)
}

// MARK: - ElevenLabs Config
let elevenLabsAPIKey = "sk_9993133219a88915031454e242372bfc39abb4fca844c447"
let elevenLabsVoiceId = "JBFqnCBsd6RMkjVDRZzb" // George — swap for any voice ID

// MARK: - ElevenLabs Audio Player
// Must be global to survive beyond the URLSession callback scope
var elevenLabsPlayer: AVAudioPlayer?

func speak11Labs(transcript: String) {
    guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(elevenLabsVoiceId)/stream") else {
        print("ElevenLabs: Invalid URL")
        return
    }

    // Build request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(elevenLabsAPIKey, forHTTPHeaderField: "xi-api-key")
    request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")

    let payload: [String: Any] = [
        "text": transcript,
        "model_id": "eleven_multilingual_v2",
        "voice_settings":[
            "stability": 0.5,
            "similarity_boost": 0.75,
            "speed": 1.0
        ]
    ]

    guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
        print("ElevenLabs: Failed to encode request body")
        return
    }
    request.httpBody = body

    // Stream audio data then hand it to AVAudioPlayer
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("ElevenLabs network error: \(error.localizedDescription)")
            return
        }

        // Surface HTTP-level errors (bad key, quota exceeded, etc.)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            print("ElevenLabs HTTP \(http.statusCode): \(body)")
            return
        }

        guard let data = data, !data.isEmpty else {
            print("ElevenLabs: Empty audio response")
            return
        }

        do {
            // Configure audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.mp3.rawValue)
            elevenLabsPlayer = player  // retain
            player.prepareToPlay()
            player.play()
        } catch {
            print("ElevenLabs playback error: \(error.localizedDescription)")
        }
    }.resume()
}

// MARK: - Cloud Model Runner Function

/// Runs the Gemma 4 31B model via the Google Gemini API and streams the response
func runModelCloud(
    prompt: String,
    onStream: @escaping (String) -> Void,
    onComplete: @escaping (Error?) -> Void
) {
    Task.detached {
        let modelName = "gemma-4-31b-it"
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):streamGenerateContent?alt=sse&key=\(gemmaApiKey)"
        
        guard let url = URL(string: urlString) else {
            onComplete(NSError(domain: "ModelRunCloud", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Gemini URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Gemini API payload structure
        let payload: [String: Any] = [
            "contents": [[
                    "role": "user",
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "thinkingConfig": [
                    "thinkingLevel": "MINIMAL"
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            // Execute streaming request
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                onComplete(NSError(domain: "ModelRunCloud", code: 2, userInfo:[NSLocalizedDescriptionKey: "Invalid Response"]))
                return
            }
            
            // Surface HTTP-level errors (bad key, quota exceeded, etc.)
            guard (200...299).contains(httpResponse.statusCode) else {
                onComplete(NSError(domain: "ModelRunCloud", code: httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey: "Gemini HTTP Error \(httpResponse.statusCode)"]))
                return
            }
            
            var buffer = ""
            
            // Read the Server-Sent Events stream line by line
            for try await line in bytes.lines {
                // Gemini API SSE chunks start with "data: "
                if line.hasPrefix("data: ") {
                    let jsonString = line.dropFirst("data: ".count)
                    
                    // Parse the JSON chunk to extract the generated text segment
                    if let data = jsonString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as?[String: Any],
                       let candidates = json["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]] {
                        
                        var chunkAdded = false
                        
                        for part in parts {
                            // 1. Skip native Gemini chain-of-thought parts
                            // (Gemini returns a "thought" boolean for thinking blocks)
                            if let isThought = part["thought"] as? Bool, isThought {
                                continue
                            }
                            
                            // 2. Extract standard text parts
                            if let textChunk = part["text"] as? String {
                                buffer += textChunk
                                chunkAdded = true
                            }
                        }
                        
                        // Only stream back to the UI if we received something valid
                        if chunkAdded {
                            // Run the string through the tag filter before updating the UI
                            onStream(filterThinkingTags(from: buffer))
                        }
                    }
                }
            }
            
            // Signal Success
            onComplete(nil)
            print("Finished cloud generation successfully.")
            
        } catch {
            print("Cloud model error: \(error.localizedDescription)")
            onComplete(error)
        }
    }
}

/// Removes `<think>...</think>` blocks from text. Used to hide model reasoning from the UI stream.
func filterThinkingTags(from text: String) -> String {
    var displayBuffer = text
    
    // Remove all fully closed <think>...</think> blocks
    while let start = displayBuffer.range(of: "<think>"),
          let end = displayBuffer.range(of: "</think>", range: start.upperBound..<displayBuffer.endIndex) {
        
        displayBuffer.removeSubrange(start.lowerBound..<end.upperBound)
        
        // Clean up trailing newlines left at the beginning if <think> was the first thing
        if start.lowerBound == displayBuffer.startIndex {
            while displayBuffer.hasPrefix("\n") {
                displayBuffer.removeFirst()
            }
        }
    }
    
    // Remove an unclosed <think> block at the end (hides thinking process while it is actively streaming)
    if let start = displayBuffer.range(of: "<think>") {
        displayBuffer.removeSubrange(start.lowerBound..<displayBuffer.endIndex)
    }
    
    return displayBuffer
}
