//
//  ModelRun.swift
//  LA Hacks
//
//  Created by Jacob Scheff on 4/24/26.
//

// MARK: - Model Runner Function

import ZeticMLange

/// Runs the LLM in a detached background task and reports back via callbacks
func runModel(
    model: ZeticMLangeLLMModel,
    prompt: String,
    onDownload: @escaping (Float) -> Void,
    onStream: @escaping (String) -> Void,
    onComplete: @escaping (Error?) -> Void
) {
    Task.detached {
        do {
            // Initialize Model
            let model = try ZeticMLangeLLMModel(
                personalKey: personalToken,
                name: "changgeun/gemma-4-E2B-it",
                version: 1,
                modelMode: .RUN_SPEED,
                onDownload: { progress in
                    onDownload(progress)
                }
            )

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
