//
//  CurriculumStore.swift
//  LA Hacks
//
//  Created by Yirui Song on 4/26/26
//
// Extends MemoryStore with a persistent curriculum layer.
// DocumentScannerViewController produces CurriculumChunks via OCR;
// this file saves them to Documents/curriculum_chunks.json and appends
// a note to memory.md so Nova's prompts stay grounded in real uploaded work.

import Foundation

// MARK: - Date helper (fileprivate to this file)

private extension ISO8601DateFormatter {
    static let curriculumDateOnly: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()
}

// MARK: - Stored Curriculum Chunk

/// Codable snapshot of one scan session — persisted across launches.
struct StoredCurriculumChunk: Codable, Identifiable {
    let id: String           // UUID string from the scan
    let source: String       // "Camera" | "PhotoLibrary" | "DocumentScan(3p)"
    let addedDate: String    // ISO-8601 date-only string
    let wordCount: Int
    let ragWindows: [String] // Pre-split overlap windows — feed straight to embedder
    let rawText: String      // Full OCR output — kept for re-chunking if params change
}

// MARK: - MemoryStore + Curriculum

extension MemoryStore {

    // MARK: Public API — called by scanner delegate

    /// Persist a fresh scan's chunks and annotate memory.md.
    /// Call this from your DocumentScannerDelegate implementation:
    ///
    ///     func scanner(_ scanner: DocumentScannerViewController, didProduce chunk: CurriculumChunk) {
    ///         MemoryStore.shared.saveCurriculumScan(chunk)
    ///     }
    func saveCurriculumScan(_ scanChunk: CurriculumChunk) {
        let stored = StoredCurriculumChunk(
            id: scanChunk.id.uuidString,
            source: scanChunk.source,
            addedDate: ISO8601DateFormatter.curriculumDateOnly.string(from: scanChunk.timestamp),
            wordCount: scanChunk.wordCount,
            ragWindows: scanChunk.ragChunks(),   // 500-word / 50-word-overlap default
            rawText: scanChunk.rawText
        )
        writeChunkToRegistry(stored)
        appendCurriculumNoteToMemory(stored)
        print("CurriculumStore ✅ saved \(stored.ragWindows.count) RAG windows from \"\(stored.source)\"")
    }

    // MARK: Public API — called by RAGPipeline / RAGRetriever

    /// All stored chunks, newest first.
    func loadCurriculumChunks() -> [StoredCurriculumChunk] {
        readRegistry()
    }

    /// Flat list of every RAG window string across all scans.
    /// Pass these to your vector store or keyword matcher.
    func allRAGWindows() -> [String] {
        readRegistry().flatMap(\.ragWindows)
    }

    /// Formatted Markdown block ready to append to a system prompt.
    /// Automatically capped at `LessonConfig.memoryContextByteCap`.
    func curriculumContextForPrompt() -> String {
        let chunks = readRegistry()
        guard !chunks.isEmpty else { return "" }

        var lines = ["## 📚 Student's Uploaded Curriculum\n"]
        for chunk in chunks {
            lines.append("**Source:** \(chunk.source) · \(chunk.addedDate) · \(chunk.wordCount) words")
            for (i, window) in chunk.ragWindows.enumerated() {
                lines.append("_Chunk \(i + 1):_ \(window)")
            }
            lines.append("")
        }

        var result = lines.joined(separator: "\n")
        if result.utf8.count > LessonConfig.memoryContextByteCap {
            let tail = Array(result.utf8).suffix(LessonConfig.memoryContextByteCap)
            result = String(decoding: tail, as: UTF8.self)
        }
        return result
    }

    // MARK: - Registry persistence (curriculum_chunks.json)

    private var registryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("curriculum_chunks.json")
    }

    private func readRegistry() -> [StoredCurriculumChunk] {
        guard let data = try? Data(contentsOf: registryURL),
              let decoded = try? JSONDecoder().decode([StoredCurriculumChunk].self, from: data)
        else { return [] }
        return decoded
    }

    private func writeChunkToRegistry(_ chunk: StoredCurriculumChunk) {
        var list = readRegistry()
        list.removeAll { $0.id == chunk.id }   // deduplicate re-scans of same image
        list.insert(chunk, at: 0)              // newest first
        if let data = try? JSONEncoder().encode(list) {
            try? data.write(to: registryURL, options: .atomic)
        }
    }

    // MARK: - Append human-readable note to memory.md

    private func appendCurriculumNoteToMemory(_ chunk: StoredCurriculumChunk) {
        let preview = chunk.rawText
            .prefix(150)
            .replacingOccurrences(of: "\n", with: " ")
        let note = """
        ### 📄 \(chunk.addedDate) · Curriculum Upload
        - Source: \(chunk.source) · \(chunk.wordCount) words · \(chunk.ragWindows.count) RAG windows
        - Preview: \(preview)…

        """

        // Build the updated file string
        var updated = contents
        if let range = updated.range(of: "## Curriculum") {
            // Insert under existing section header
            let insertIdx = updated.index(
                range.upperBound,
                offsetBy: 1,
                limitedBy: updated.endIndex
            ) ?? updated.endIndex
            updated.insert(contentsOf: "\n" + note, at: insertIdx)
        } else {
            // Create the section for the first time
            updated += "\n## Curriculum\n\n" + note
        }

        // Write directly to the same memory.md path MemoryStore uses,
        // then reload so @Published contents refreshes.
        let memURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("memory.md")
        try? updated.write(to: memURL, atomically: true, encoding: .utf8)

        Task { @MainActor in
            self.load()   // triggers @Published update
        }
    }
}
