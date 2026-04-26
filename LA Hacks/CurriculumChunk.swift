//
//  CurriculumChunk.swift
//  LA Hacks
//
//  Created by Yirui Song on 4/26/26.
//
// Shared model produced by DocumentScannerViewController (OCR)
// and consumed by CurriculumStore + RAGPipeline.

import Foundation

struct CurriculumChunk {
    let id: UUID
    let rawText: String
    let source: String       // "Camera" | "PhotoLibrary" | "DocumentScan(3p)"
    let timestamp: Date

    var wordCount: Int {
        rawText.split(separator: " ").count
    }

    /// Splits rawText into overlapping windows ready to feed to an embedder.
    /// - Parameters:
    ///   - size: target word count per window (default 500)
    ///   - overlap: word overlap between consecutive windows (default 50)
    func ragChunks(size: Int = 500, overlap: Int = 50) -> [String] {
        let words = rawText.split(separator: " ").map(String.init)
        guard words.count > size else { return [rawText] }
        var chunks: [String] = []
        var start = 0
        while start < words.count {
            let end = min(start + size, words.count)
            chunks.append(words[start..<end].joined(separator: " "))
            start += size - overlap
        }
        return chunks
    }
}
