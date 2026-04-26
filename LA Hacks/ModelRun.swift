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

    /// Cache of resolved voices keyed by BCP-47 / language code. We re-use voices
    /// across utterances because AVSpeechSynthesisVoice(language:) is expensive,
    /// but we DO swap voices when the user changes language at runtime.
    private var voiceCache: [String: AVSpeechSynthesisVoice] = [:]

    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("SpeechManager AVAudioSession init error: \(error.localizedDescription)")
        }
        synthesizer = AVSpeechSynthesizer()
    }

    /// Map our app language code to the BCP-47 locale identifier
    /// `AVSpeechSynthesisVoice(language:)` expects.
    private func ttsLocale(for appLang: String) -> String {
        switch appLang {
        case "en":      return "en-US"
        case "es":      return "es-ES"
        case "fr":      return "fr-FR"
        case "de":      return "de-DE"
        case "ja":      return "ja-JP"
        case "zh-Hans": return "zh-CN"
        case "zh-Hant": return "zh-TW"
        case "ar":      return "ar-SA"
        case "pt":      return "pt-BR"
        case "ru":      return "ru-RU"
        case "ko":      return "ko-KR"
        case "hi":      return "hi-IN"
        case "it":      return "it-IT"
        case "tr":      return "tr-TR"
        case "nl":      return "nl-NL"
        case "pl":      return "pl-PL"
        case "uk":      return "uk-UA"
        default:        return appLang
        }
    }

    /// Resolve a voice for the current user language, falling back gracefully
    /// to en-US if the OS doesn't ship a matching voice.
    private func voice(for appLang: String) -> AVSpeechSynthesisVoice? {
        if let cached = voiceCache[appLang] { return cached }
        let primary = ttsLocale(for: appLang)
        if let v = AVSpeechSynthesisVoice(language: primary) {
            voiceCache[appLang] = v
            NSLog("[i18n] SpeechManager picked voice \(primary) for app lang \(appLang)")
            return v
        }
        NSLog("[i18n] SpeechManager: no voice for \(primary), falling back to en-US")
        let fallback = AVSpeechSynthesisVoice(language: "en-US")
        if let f = fallback { voiceCache[appLang] = f }
        return fallback
    }

    func speak(_ transcript: String) {
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

        utterance.voice = voice(for: UserSettings.shared.language)
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

/// Runs the LLM and streams tokens to `onStream`.
///
/// `speak` controls whether output is sent to the TTS pipeline. The chat-tutor
/// path leaves it `true`; structured-JSON callers (LessonGenerator,
/// MemoryStore compression) pass `false` so the user never hears raw JSON
/// fences or backstage scaffolding read aloud.
func runModel(
    prompt: String,
    onDownload: @escaping (Float) -> Void,
    onStream: @escaping (String) -> Void,
    onComplete: @escaping (Error?) -> Void,
    speak: Bool = true
) {
    let isOnboarded = UserDefaults.standard.bool(forKey: "onboarded")
    let isConnected = UserDefaults.standard.bool(forKey: "isConnected")

    if speak { resetTTS() }

    if isConnected && isOnboarded {
        print("Calling Model Run With Google Gemma API")
        runModelCloud(prompt: prompt, onStream: onStream, onComplete: onComplete, speak: speak)
        return
    }

    print("Calling Model Run With Zetic AI")

    // FIX: Replaced `Task.detached` with GCD. `waitForNextToken()` is a deeply synchronous,
    // blocking C++ call. Running it inside Swift Concurrency violates the cooperative thread
    // pool, which triggers the "unsafeForcedSync" runtime warnings you saw. GCD safely bypasses this.
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            if sharedModel == nil {
                guard let personalToken = Bundle.main.infoDictionary?["personalToken"] as? String,
                      !personalToken.isEmpty else {
                    print("ModelRun: missing 'personalToken' in Info.plist — skipping local model load.")
                    onComplete(NSError(
                        domain: "ModelRun", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Local model not configured (personalToken missing)."]
                    ))
                    return
                }
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
                if speak { streamTTS(text: filtered, isFinal: false) }
            }

            if speak {
                let finalFiltered = filterThinkingTags(from: buffer)
                streamTTS(text: finalFiltered, isFinal: true)
            }

            onComplete(nil)
            print("Finished generation successfully.")

        } catch {
            print("Model error: \(error)")
            onComplete(error)
        }
    }
}


// MARK: - ElevenLabs Config & Logic

/// Read at use-site (not as eager top-level lets) so a missing key can fall back
/// to local TTS instead of crashing the app.
private var elevenLabsAPIKey: String? {
    Bundle.main.infoDictionary?["elevenLabsAPIKey"] as? String
}
private var elevenLabsVoiceId: String? {
    Bundle.main.infoDictionary?["elevenLabsVoiceId"] as? String
}

func speak11Labs(transcript: String) {
    guard let voiceId = elevenLabsVoiceId, !voiceId.isEmpty,
          let apiKey = elevenLabsAPIKey, !apiKey.isEmpty,
          let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)/stream")
    else {
        print("ElevenLabs: missing API key or voice id — falling back to local TTS.")
        Task { @MainActor in SpeechManager.shared.speak(transcript) }
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
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
    onComplete: @escaping (Error?) -> Void,
    speak: Bool = true
) {
    Task.detached {
        guard let gemmaApiKey = Bundle.main.infoDictionary?["gemmaApiKey"] as? String,
              !gemmaApiKey.isEmpty else {
            print("ModelRunCloud: missing 'gemmaApiKey' in Info.plist — aborting cloud call.")
            onComplete(NSError(
                domain: "ModelRunCloud", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Cloud model not configured (gemmaApiKey missing)."]
            ))
            return
        }
        let modelName = "gemma-4-31b-it"
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):streamGenerateContent?alt=sse&key=\(gemmaApiKey)"

        guard let url = URL(string: urlString) else {
            onComplete(NSError(domain: "ModelRunCloud", code: -2,
                               userInfo: [NSLocalizedDescriptionKey: "Bad cloud model URL."]))
            return
        }
        
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
                            if speak { streamTTS(text: filtered, isFinal: false) }
                        }
                    }
                }
            }

            if speak {
                let finalFiltered = filterThinkingTags(from: buffer)
                streamTTS(text: finalFiltered, isFinal: true)
            }
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
