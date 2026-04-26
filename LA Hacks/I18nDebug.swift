//
//  I18nDebug.swift
//  LA Hacks
//
//  TEMPORARY (debug-2da7cf): runtime instrumentation for the multilingual bug.
//  Posts NDJSON entries to the local debug ingest server at 127.0.0.1:7664
//  AND mirrors to NSLog for Xcode console visibility.
//
//  iOS apps are sandboxed and cannot write to host filesystem paths, so direct
//  file I/O won't work — HTTP to the host's local debug server is the only
//  channel we have. Requires `NSAllowsLocalNetworking = true` in Info.plist.
//
//  Remove this file (and the call sites) once the bug is verified fixed.
//

import Foundation

enum I18nDebug {
    private static let endpoint = URL(string: "http://127.0.0.1:7664/ingest/1b55ea92-e424-4e25-9b58-0c3d2818a2e4")!
    private static let sessionId = "2da7cf"
    private static let session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 1.0
        cfg.timeoutIntervalForResource = 1.0
        return URLSession(configuration: cfg)
    }()

    static func log(_ hypothesisId: String,
                    _ location: String,
                    _ message: String,
                    _ data: [String: String] = [:]) {
        let kv = data
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        NSLog("[i18n][\(hypothesisId)] \(location) :: \(message) \(kv)")

        var payload: [String: Any] = [
            "sessionId": sessionId,
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        payload["data"] = data

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(sessionId, forHTTPHeaderField: "X-Debug-Session-Id")
        req.httpBody = body
        session.dataTask(with: req) { _, _, _ in }.resume()
    }
}
