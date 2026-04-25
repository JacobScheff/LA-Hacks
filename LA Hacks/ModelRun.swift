//
//  ModelRun.swift
//  LA Hacks
//
//  Created by Jacob Scheff on 4/24/26.
//

import Foundation
import ZeticMLange

<<<<<<< HEAD
/// Runs the LLM in a detached background task and reports back via callbacks.
/// `model` is currently unused; the function constructs its own instance internally.
func runModel(
    model: ZeticMLangeLLMModel? = nil,
=======
// MARK: - Global Shared Model
// Model is declared only once to avoid 5-10s memory initialization between every message
var sharedModel: ZeticMLangeLLMModel?

// MARK: - Model Runner Function

/// Runs the LLM in a detached background task and reports back via callbacks
func runModel(
>>>>>>> 71d9d9210b1f7741fd0aa6809bf6adaf69c06736
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
                    personalKey: personalToken, // Assumes this is defined globally in your project
                    name: "changgeun/gemma-4-E2B-it",
                    version: 1,
                    modelMode: .RUN_SPEED,
                    onDownload: { progress in
                        onDownload(progress)
                    }
                    
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
                    break // End of generation
                }

                buffer.append(waitResult.token)
                
                // Trigger the streaming callback with the updated buffer
                onStream(buffer)
            }

            // Signal Success
            onComplete(nil)
            print("Finished generation successfully.")
            
        } catch {
            // Signal Error
            print("Model error: \(error)")
            onComplete(error)
        }
    }
}
