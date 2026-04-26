//
//  ModelRun.swift
//  LA Hacks
//
//  Created by Jacob Scheff on 4/24/26.
//

import Foundation
import ZeticMLange
import AVFoundation

// MARK: - Global Shared Model
// Model is declared only once to avoid 5-10s memory initialization between every message
var sharedModel: ZeticMLangeLLMModel?

// MARK: - Speech Synthesizer
var synthesizer = AVSpeechSynthesizer()

// MARK: - Model Runner Function

/// Runs the LLM in a detached background task and reports back via callbacks
func runModel(
    prompt: String,
    onDownload: @escaping (Float) -> Void,
    onStream: @escaping (String) -> Void,
    onComplete: @escaping (Error?) -> Void
) {
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
                onStream(buffer)
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
        "voice_settings": [
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
