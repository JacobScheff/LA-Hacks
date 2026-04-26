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
var sharedModel: ZeticMLangeLLMModel?

// MARK: - Local Speech Manager
@MainActor
class SpeechManager {
    static let shared = SpeechManager()
    let synthesizer: AVSpeechSynthesizer
    var elevenLabsPlayer: AVAudioPlayer?
    private var cachedVoice: AVSpeechSynthesisVoice?
    
    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("SpeechManager AVAudioSession init error: \(error.localizedDescription)")
        }
        synthesizer = AVSpeechSynthesizer()
        
        // Cache the voice to prevent expensive OS lookups during high-speed streaming
        cachedVoice = AVSpeechSynthesisVoice(language: "en-GB")
    }
    
    func speak(_ transcript: String) {
        // Strip out XML/HTML characters to explicitly prevent iOS from attempting to parse
        // this as SSML, which causes the "No root nodes found" crash.
        let sanitized = transcript
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            
        guard !sanitized.isEmpty else { return }
            
        let utterance = AVSpeechUtterance(string: sanitized)
        utterance.rate = 0.57
        utterance.pitchMultiplier = 0.8
        utterance.postUtteranceDelay = 0.2
        utterance.volume = 0.8

        if let voice = cachedVoice {
            utterance.voice = voice
        }

        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        elevenLabsPlayer?.stop()
    }
}

// MARK: - TTS State
var ttsLastSpokenIndex = 0

func resetTTS() {
    ttsLastSpokenIndex = 0
    Task { @MainActor in
        SpeechManager.shared.stop()
    }
}

func speak(transcript: String) {
    Task { @MainActor in
        SpeechManager.shared.speak(transcript)
    }
}

func streamTTS(text: String, isFinal: Bool) {
    let isConnected = UserDefaults.standard.bool(forKey: "isConnected")
    
    if isConnected {
        // Cloud TTS
        if isFinal {
            let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanText.isEmpty {
                speak11Labs(transcript: cleanText)
            }
        }
    } else {
        // Local TTS Chunking
        let safeIndex = min(ttsLastSpokenIndex, text.count)
        let unprocessed = String(text.dropFirst(safeIndex))
        
        if isFinal {
            let cleanText = unprocessed.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanText.isEmpty {
                speak(transcript: cleanText)
            }
            ttsLastSpokenIndex = 0
            return
        }
        
        let delimiters: [Character] = [".", "?", "!", "\n", ":", ";"]
        if let lastDelimiterIndex = unprocessed.lastIndex(where: { delimiters.contains($0) }) {
            let chunkIndex = unprocessed.index(after: lastDelimiterIndex)
            let chunk = String(unprocessed[..<chunkIndex])
            
            ttsLastSpokenIndex += chunk.count
            
            let cleanChunk = chunk.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanChunk.isEmpty {
                speak(transcript: cleanChunk)
            }
        }
    }
}

// MARK: - Model Runner Function

func runModel(
    prompt: String,
    onDownload: @escaping (Float) -> Void,
    onStream: @escaping (String) -> Void,
    onComplete: @escaping (Error?) -> Void
) {
    let isOnboarded = UserDefaults.standard.bool(forKey: "onboarded")
    let isConnected = UserDefaults.standard.bool(forKey: "isConnected")
    
    resetTTS()
    
    if isConnected && isOnboarded {
        print("Calling Model Run With Google Gemma API")
        runModelCloud(prompt: prompt, onStream: onStream, onComplete: onComplete)
        return
    }
    
    print("Calling Model Run With Zetic AI")
    
    // FIX: Replaced `Task.detached` with GCD. `waitForNextToken()` is a deeply synchronous,
    // blocking C++ call. Running it inside Swift Concurrency violates the cooperative thread
    // pool, which triggers the "unsafeForcedSync" runtime warnings you saw. GCD safely bypasses this.
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            if sharedModel == nil {
                sharedModel = try ZeticMLangeLLMModel(
                    personalKey: ProcessInfo.processInfo.environment["personalToken"] ?? "",
                    name: "changgeun/gemma-4-E2B-it",
                    version: 1,
                    modelMode: LLMModelMode.RUN_SPEED,
                    onDownload: { progress in
                        onDownload(progress)
                    },
                )
            }

            guard let model = sharedModel else { return }

            try model.run(prompt)
            var buffer = ""

            while true {
                let waitResult = model.waitForNextToken()

                if waitResult.generatedTokens == 0 {
                    break
                }

                buffer.append(waitResult.token)
                
                let filtered = filterThinkingTags(from: buffer)
                onStream(filtered)
                streamTTS(text: filtered, isFinal: false)
            }

            let finalFiltered = filterThinkingTags(from: buffer)
            streamTTS(text: finalFiltered, isFinal: true)
            
            onComplete(nil)
            print("Finished generation successfully.")

        } catch {
            print("Model error: \(error)")
            onComplete(error)
        }
    }
}


// MARK: - ElevenLabs Config & Logic
let elevenLabsAPIKey = ProcessInfo.processInfo.environment["elevenLabsAPIKey"] ?? ""
let elevenLabsVoiceId = ProcessInfo.processInfo.environment["elevenLabsVoiceId"] ?? ""

func speak11Labs(transcript: String) {
    guard let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(elevenLabsVoiceId)/stream") else { return }

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

    guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
    request.httpBody = body

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error { print("ElevenLabs error: \(error)"); return }
        guard let data = data, !data.isEmpty else { return }

        Task { @MainActor in
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options:[.duckOthers, .mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)

                let player = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.mp3.rawValue)
                SpeechManager.shared.elevenLabsPlayer = player
                player.prepareToPlay()
                player.play()
            } catch {
                print("ElevenLabs playback error: \(error.localizedDescription)")
            }
        }
    }.resume()
}


// MARK: - Cloud Model Runner Function

func runModelCloud(
    prompt: String,
    onStream: @escaping (String) -> Void,
    onComplete: @escaping (Error?) -> Void
) {
    Task.detached {
        let gemmaApiKey = ProcessInfo.processInfo.environment["gemmaApiKey"] ?? ""
        let modelName = "gemma-4-31b-it"
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):streamGenerateContent?alt=sse&key=\(gemmaApiKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload:[String: Any] = [
            "contents": [
                "role": "user",
                "parts": [["text": prompt]]
            ],
            "generationConfig": [
                "thinkingConfig": [
                    "thinkingLevel": "MINIMAL"
                ]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else { return }
            guard (200...299).contains(httpResponse.statusCode) else {
                onComplete(NSError(domain: "ModelRunCloud", code: httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey: "Gemini HTTP Error \(httpResponse.statusCode)"]))
                return
            }
            
            var buffer = ""
            for try await line in bytes.lines {
                if line.hasPrefix("data: ") {
                    let jsonString = line.dropFirst("data: ".count)
                    
                    if let data = jsonString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as?[String: Any],
                       let candidates = json["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as?[String: Any],
                       let parts = content["parts"] as? [[String: Any]] {
                        
                        var chunkAdded = false
                        for part in parts {
                            if let isThought = part["thought"] as? Bool, isThought { continue }
                            if let textChunk = part["text"] as? String {
                                buffer += textChunk
                                chunkAdded = true
                            }
                        }
                        
                        if chunkAdded {
                            let filtered = filterThinkingTags(from: buffer)
                            onStream(filtered)
                            streamTTS(text: filtered, isFinal: false)
                        }
                    }
                }
            }
            
            let finalFiltered = filterThinkingTags(from: buffer)
            streamTTS(text: finalFiltered, isFinal: true)
            onComplete(nil)
            
        } catch {
            onComplete(error)
        }
    }
}

func filterThinkingTags(from text: String) -> String {
    var displayBuffer = text
    
    // Support standard tags + Gemma 4 reasoning tags
    let openClosePairs = [
        ("<think>", "</think>"),
        ("<thought>", "</thought>"),
        ("<|thought|>", "</|thought|>"),
        ("<|think|>", "</|think|>"),
        ("<|channel>thought", "<channel|>")
    ]
    
    // 1. Remove fully enclosed blocks
    for (openTag, closeTag) in openClosePairs {
        while let start = displayBuffer.range(of: openTag),
              let end = displayBuffer.range(of: closeTag, range: start.upperBound..<displayBuffer.endIndex) {
            displayBuffer.removeSubrange(start.lowerBound..<end.upperBound)
            if start.lowerBound == displayBuffer.startIndex {
                while displayBuffer.hasPrefix("\n") { displayBuffer.removeFirst() }
            }
        }
    }
    
    // 2. Remove currently open/unclosed blocks
    for (openTag, _) in openClosePairs {
        if let start = displayBuffer.range(of: openTag) {
            displayBuffer.removeSubrange(start.lowerBound..<displayBuffer.endIndex)
        }
    }
    
    // 3. Prevent partial streaming string tags (e.g., `<|chan`) from leaking to the TTS chunker
    let openTags = openClosePairs.map { $0.0 }
    let maxOpenTagLength = openTags.map { $0.count }.max() ?? 0
    let checkLength = min(displayBuffer.count, maxOpenTagLength)
    
    if checkLength > 0 {
        // Iterate backwards through the end of the string to find forming tags
        for i in 1...checkLength {
            let suffixIndex = displayBuffer.index(displayBuffer.endIndex, offsetBy: -i)
            
            // Only evaluate if the substring chunk starts with '<' to maintain performance
            if displayBuffer[suffixIndex] == "<" {
                let suffix = String(displayBuffer[suffixIndex...])
                
                // If the suffix is a partial match for any of our known open tags, strip it
                if openTags.contains(where: { $0.hasPrefix(suffix) && $0 != suffix }) {
                    displayBuffer.removeLast(i)
                    break
                }
            }
        }
    }
    
    return displayBuffer
}
