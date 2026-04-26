//
//  UploadModal.swift
//  LA Hacks
//
//  Star Hop! upload-doc → grow-new-stars flow — pick screen.
//  Ported from project/galaxy-upload.jsx.
//
// Floating centered popup (not a bottom sheet).
// • Two tabs: 📷 Scan  |  📝 Paste
// • X button top-right + tap-outside-to-dismiss
// • Entire content scrolls inside the card
// • Footer (Grow stars!) lives inside the scroll so it is never
//   hidden behind the bottom nav bar

import SwiftUI
import Vision
import VisionKit

// MARK: - Topic recipes

private struct TopicRecipe {
    let keywords: [String]
    let matchConstellationId: String?
    let newName: String?
    let newEmoji: String?
    let newSkyStory: String?
    let topics: [(label: String, emoji: String)]
}

private let TOPIC_RECIPES: [TopicRecipe] = [
    TopicRecipe(
        keywords: ["math","add","subtract","sum","arith","plus","minus"],
        matchConstellationId: "numbers",
        newName: nil, newEmoji: nil, newSkyStory: nil,
        topics: [("Two-Digit Adding","🔟"), ("Carrying Over","🎒"), ("Number Lines","📏")]
    ),
    TopicRecipe(
        keywords: ["fraction","pizza","half","slice","quarter"],
        matchConstellationId: "fractions",
        newName: nil, newEmoji: nil, newSkyStory: nil,
        topics: [("Pizza Slicing","🍕"), ("Comparing ½ and ⅓","⚖️"), ("Decimals & Fractions","🔢")]
    ),
    TopicRecipe(
        keywords: ["reading","story","passage","book","novel","character"],
        matchConstellationId: "reading",
        newName: nil, newEmoji: nil, newSkyStory: nil,
        topics: [("Story Settings","🏞️"), ("Plot Twists","🌪️"), ("Character Feelings","😢")]
    ),
    TopicRecipe(
        keywords: ["science","plant","animal","biolog","ecosystem"],
        matchConstellationId: "life",
        newName: nil, newEmoji: nil, newSkyStory: nil,
        topics: [("Pollinators","🐝"), ("Animal Adaptations","🦎"), ("Forest Layers","🌳")]
    ),
    TopicRecipe(
        keywords: ["history","ancient","rome","egypt","war","revolution"],
        matchConstellationId: "history",
        newName: nil, newEmoji: nil, newSkyStory: nil,
        topics: [("Roman Roads","🛣️"), ("Pyramids","🔺"), ("Trade Routes","🐪")]
    ),
    TopicRecipe(
        keywords: ["music","note","rhythm","song","piano","guitar"],
        matchConstellationId: nil,
        newName: "Melody Meadow", newEmoji: "🎵",
        newSkyStory: "You discovered a brand new corner of the galaxy. Music has its own little cluster of stars now!",
        topics: [("Reading Notes","🎼"), ("Beats & Rhythm","🥁"), ("Loud & Soft","🔊"), ("Major vs Minor","🎹"), ("Song Shapes","🎶")]
    ),
    TopicRecipe(
        keywords: ["code","program","computer","scratch","python","js"],
        matchConstellationId: nil,
        newName: "Code Cosmos", newEmoji: "💻",
        newSkyStory: "A new cluster of stars just blinked on. Computer thinking is its own kind of magic!",
        topics: [("Sequences","➡️"), ("Loops","🔁"), ("If / Then","🔀"), ("Variables","📦"), ("Bugs!","🐛")]
    ),
    TopicRecipe(
        keywords: [],
        matchConstellationId: nil,
        newName: "Curiosity Cluster", newEmoji: "🔭",
        newSkyStory: "Whatever you uploaded sparked something brand-new! These stars came together just from your doc.",
        topics: [("Big Idea #1","💡"), ("Key Term","🔑"), ("Tricky Bit","🤔"), ("Try It Out","🎯")]
    ),
]

private func pickRecipe(text: String, fileName: String) -> TopicRecipe {
    let haystack = (text + " " + fileName).lowercased()
    for r in TOPIC_RECIPES {
        if r.keywords.contains(where: { haystack.contains($0) }) { return r }
    }
    return TOPIC_RECIPES.last!
}

private func freeClusterCenter(avoiding constellations: [Constellation]) -> CGPoint {
    let minGap: CGFloat = 120
    let outerR: CGFloat = 215
    let bboxPad = minGap / 2
    let probeHalf = outerR + minGap / 2

    let boxes = constellations.map { c -> CGRect in
        let r = c.boundingRect(padding: bboxPad)
        let inflateW = r.width * 0.25
        let inflateH = r.height * 0.25
        return r.insetBy(dx: -inflateW, dy: -inflateH)
    }


    func isFree(_ x: CGFloat, _ y: CGFloat) -> Bool {
        let probe = CGRect(x: x - probeHalf, y: y - probeHalf, width: probeHalf * 2, height: probeHalf * 2)
        return !boxes.contains { $0.intersects(probe) }
    }
    let step: CGFloat = 100
    var y = GalaxyData.SKY_H - 150
    while y >= 200 {
        var x: CGFloat = 150
        while x <= GalaxyData.SKY_W - 150 {
            if isFree(x, y) { return CGPoint(x: x, y: y) }
            x += step
        }
        y -= step
    }
    let maxY = constellations.flatMap(\.nodes).map(\.y).max() ?? GalaxyData.SKY_H * 0.8
    return CGPoint(x: GalaxyData.SKY_W / 2, y: maxY + 380)
}

private func makeNewClusterPositions(count: Int, cx: CGFloat, cy: CGFloat) -> [(CGFloat, CGFloat)] {
    var positions: [(CGFloat, CGFloat)] = []
    let innerR: CGFloat = 130
    let outerR: CGFloat = 215
    for i in 0..<count {
        let ring = i % 2 == 0 ? innerR : outerR
        let ang = Double(i) / Double(count) * .pi * 2 - .pi / 2
        positions.append((cx + CGFloat(cos(ang)) * ring, cy + CGFloat(sin(ang)) * ring))
    }
    return positions
}

// MARK: - Generation result types

struct GenerationResult {
    let isNew: Bool
    let constellationName: String
    let emoji: String
    let addedTopics: [(label: String, emoji: String)]
    let neighborTopics: [(label: String, emoji: String)]
    var jumpTo: (x: CGFloat, y: CGFloat, scale: CGFloat)?
}

struct GenerationOutcome {
    let result: GenerationResult
    let targetConstellationId: String?
    let addedNodes: [StarNode]
    let newConstellation: Constellation?
}

func buildGenerationResult(text: String, fileName: String, constellations: [Constellation]) -> GenerationOutcome {
    let recipe = pickRecipe(text: text, fileName: fileName)
    let now = String(Int(Date().timeIntervalSince1970 * 1000))

    if let matchId = recipe.matchConstellationId,
       let target = constellations.first(where: { $0.id == matchId }) {
        let baseX = target.centroid.x
        let baseY = target.centroid.y + 90
        let positions = makeNewClusterPositions(count: recipe.topics.count, cx: baseX, cy: baseY)
        let addedNodes: [StarNode] = recipe.topics.enumerated().map { i, t in
            StarNode(
                id: "gen-\(now)-\(i)",
                label: t.label, star: "New ✨", emoji: t.emoji,
                x: positions[i].0, y: positions[i].1,
                initiallyLocked: false, size: 5
            )
        }
        return GenerationOutcome(
            result: GenerationResult(isNew: false, constellationName: target.name, emoji: target.emoji,
                                     addedTopics: recipe.topics, neighborTopics: [],
                                     jumpTo: (baseX, baseY, 1.0)),
            targetConstellationId: target.id, addedNodes: addedNodes, newConstellation: nil
        )
    }

    let freeCenter = freeClusterCenter(avoiding: constellations)
    let cx = freeCenter.x, cy = freeCenter.y
    let positions = makeNewClusterPositions(count: recipe.topics.count, cx: cx, cy: cy)
    let newId = "gen-\(now)"
    let primary: [StarNode] = recipe.topics.enumerated().map { i, t in
        StarNode(
            id: "\(newId)-\(i)",
            label: t.label, star: "New ✨", emoji: t.emoji,
            x: positions[i].0, y: positions[i].1,
            initiallyLocked: false, size: 5
        )
    }
    let neighborPool: [(label: String, emoji: String)] = [
        ("Bonus Idea","🎁"), ("Try This Too","🌱"), ("Cool Detail","🔍"),
        ("Big Picture","🖼️"), ("Real-world Use","🌎"),
    ]
    var neighborTopics: [(label: String, emoji: String)] = []
    let neighborCount = min(3, primary.count)
    let neighbors: [StarNode] = (0..<neighborCount).map { i in
        let pick = neighborPool[i % neighborPool.count]
        neighborTopics.append(pick)
        let n = primary[i]
        let ang = Double(i) / Double(neighborCount) * .pi * 2 + .pi / 6
        let dist: CGFloat = 75 + CGFloat(i) * 15
        return StarNode(
            id: "\(newId)-nb-\(i)",
            label: pick.label, star: "Sleepy", emoji: pick.emoji,
            x: n.x + CGFloat(cos(ang)) * dist,
            y: n.y + CGFloat(sin(ang)) * dist,
            initiallyLocked: true, size: 3.5
        )
    }
    var edges: [Edge] = []
    for i in 0..<(primary.count - 1) { edges.append(Edge(a: primary[i].id, b: primary[i + 1].id)) }
    for (i, nn) in neighbors.enumerated() { edges.append(Edge(a: primary[i].id, b: nn.id)) }

    let newConstellation = Constellation(
        id: newId, name: recipe.newName ?? "New Skies", realName: "A new constellation",
        nickname: "", emoji: recipe.newEmoji ?? "✨", course: "Just for you · made by Nova",
        blurb: "New stars Nova found in your doc.",
        skyStory: recipe.newSkyStory ?? "Nova made this constellation just for you.",
        centroid: CGPoint(x: cx, y: cy), nodes: primary + neighbors, edges: edges
    )
    return GenerationOutcome(
        result: GenerationResult(isNew: true, constellationName: recipe.newName ?? "New Skies",
                                 emoji: recipe.newEmoji ?? "✨", addedTopics: recipe.topics,
                                 neighborTopics: neighborTopics, jumpTo: (cx, cy, 0.9)),
        targetConstellationId: nil, addedNodes: [], newConstellation: newConstellation
    )
}

// MARK: - Upload Modal

struct UploadModal: View {
    let onClose: () -> Void
    let onGenerate: (_ text: String, _ fileName: String) -> Void

    // MARK: Tab — only Scan + Paste
    enum PickTab: String, CaseIterable {
        case scan, paste
        var label: String {
            switch self {
            case .scan:  return "📷 Scan"
            case .paste: return "📝 Paste"
            }
        }
    }

    @State private var tab: PickTab = .scan
    @State private var text: String = ""
    @State private var fileName: String = ""

    // Scan sub-state
    @State private var scanStatus: ScanStatus = .idle
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .camera
    @State private var showDocumentCamera = false
    @State private var scannedPreviewImage: UIImage? = nil

    enum ScanStatus: Equatable {
        case idle, scanning, done(lines: Int, words: Int, ragWindows: Int), failed(String)
    }

    private let examples: [(label: String, emoji: String, seed: String)] = [
        ("Math worksheet", "➗", "math worksheet adding subtracting"),
        ("Reading passage", "📖", "reading story passage character"),
        ("Music notes", "🎵", "music notes rhythm"),
        ("Coding lesson", "💻", "code program loops"),
    ]

    private var canSubmit: Bool {
        switch tab {
        case .scan:
            if case .done = scanStatus { return true }
            return false
        case .paste:
            return !text.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // ── Scrim — tap to dismiss ──────────────────────────────────────
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            // ── Floating card ───────────────────────────────────────────────
            GeometryReader { geo in
                let cardWidth  = min(geo.size.width - 40, 480)
                // Leave at least 60 pt above the bottom (nav bar area) and
                // 60 pt below the status bar; clamp height so it never fills
                // the whole screen.
                let maxCardH   = geo.size.height - geo.safeAreaInsets.top - geo.safeAreaInsets.bottom - 80
                let cardHeight = min(maxCardH, 620)

                ScrollView {
                    cardContent
                        .frame(width: cardWidth)
                }
                .frame(width: cardWidth, height: cardHeight)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(hex: 0x1E0E4A), Color(hex: 0x0E0626)],
                            startPoint: .top, endPoint: .bottom
                        ))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color(hex: 0xFFE066, opacity: 0.30), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.55), radius: 40, x: 0, y: 16)
                // Centre the card in the safe area, nudged slightly above centre
                .position(
                    x: geo.size.width / 2,
                    y: geo.safeAreaInsets.top + (geo.size.height - geo.safeAreaInsets.top - geo.safeAreaInsets.bottom) / 2 - 20
                )
            }
<<<<<<< HEAD
            .dismissesKeyboard()

            footer
=======
            .ignoresSafeArea()
>>>>>>> 375dfe5b2f235de72a7a4adffec66d180de8d8d3
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: true)
        // Image picker sheet
        .sheet(isPresented: $showImagePicker) {
            ImagePickerRepresentable(source: imagePickerSource) { image in
                scannedPreviewImage = image
                runOCR(on: image, source: imagePickerSource == .camera ? "Camera" : "PhotoLibrary")
            }
        }
        // Document camera sheet
        .sheet(isPresented: $showDocumentCamera) {
            DocumentCameraRepresentable { images in
                if let first = images.first { scannedPreviewImage = first }
                runOCROnPages(images, source: "DocumentScan(\(images.count)p)")
            }
        }
    }

    // MARK: - Card content (scrolls inside the card)

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Top bar: title + X ─────────────────────────────────────────
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("✨ NEW SKIES")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(0.6)
                        .foregroundColor(Color(hex: 0xFFE066))
                    Text("Show Nova a doc!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                // X dismiss button
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 14)

            // ── Sub-headline ───────────────────────────────────────────────
            Text("Scan a worksheet or paste any text. Nova will turn it into stars! 🌟")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
                .lineSpacing(2)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // ── Tab picker ─────────────────────────────────────────────────
            tabPicker
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            // ── Active pane ────────────────────────────────────────────────
            Group {
                switch tab {
                case .scan:  scanPane
                case .paste: pastePane
                }
            }
            .padding(.horizontal, 20)

            // ── Examples (paste tab only) ──────────────────────────────────
            if tab == .paste {
                examplesSection
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }

            // ── Grow stars button — only appears once content is ready ───
            if canSubmit {
                growButton
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.spring(response: 0.35, dampingFraction: 0.78), value: canSubmit)
            }
        }
    }

    // MARK: - Tab picker (2 tabs only)

    private var tabPicker: some View {
        HStack(spacing: 6) {
            ForEach(PickTab.allCases, id: \.self) { t in
                let active = tab == t
                Button(action: { tab = t }) {
                    Text(t.label)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(active ? Color(hex: 0x3A2A00) : .white.opacity(0.65))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            active
                            ? AnyShapeStyle(LinearGradient(
                                colors: [Color(hex: 0xFFE066), Color(hex: 0xFFB300)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color.clear)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.black.opacity(0.35)))
    }

    // MARK: - Scan pane

    private var scanPane: some View {
        VStack(spacing: 12) {
            // Preview / status box
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color(hex: 0xFFE066, opacity: 0.4),
                                          style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    )

                if let img = scannedPreviewImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(alignment: .topTrailing) {
                            Button {
                                scannedPreviewImage = nil
                                scanStatus = .idle
                                text = ""
                                fileName = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.85))
                                    .padding(8)
                            }
                            .buttonStyle(.plain)
                        }
                } else {
                    scanStatusView.frame(height: 140)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)

            // Source buttons
            HStack(spacing: 8) {
                sourceBtn("📷 Camera")    { imagePickerSource = .camera;       showImagePicker = true }
                sourceBtn("🖼️ Library")   { imagePickerSource = .photoLibrary; showImagePicker = true }
                sourceBtn("📄 Document")  { showDocumentCamera = true }
            }

            // Extracted text preview
            if !text.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("📝 Extracted text")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: 0xFFE066, opacity: 0.9))
                        Spacer()
                        if case .done(let l, let w, let c) = scanStatus {
                            Text("\(l) lines · \(w)w · \(c) chunks")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    ScrollView {
                        Text(text)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.75))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 76)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
                }
            }
        }
    }

    @ViewBuilder
    private var scanStatusView: some View {
        switch scanStatus {
        case .idle:
            VStack(spacing: 7) {
                Text("📸").font(.system(size: 32))
                Text("Scan your schoolwork")
                    .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white)
                Text("Camera · Library · Multi-page doc")
                    .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.5))
            }
        case .scanning:
            VStack(spacing: 10) {
                ProgressView().progressViewStyle(.circular).tint(Color(hex: 0xFFE066)).scaleEffect(1.2)
                Text("Reading your doc… ✨")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: 0xFFE066))
            }
        case .done(let lines, let words, _):
            VStack(spacing: 5) {
                Text("✅").font(.system(size: 28))
                Text("Got it! \(lines) lines, \(words) words")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0xFFE066))
                Text("Tap Grow stars! below")
                    .font(.system(size: 11, design: .rounded)).foregroundColor(.white.opacity(0.5))
            }
        case .failed(let msg):
            VStack(spacing: 7) {
                Text("⚠️").font(.system(size: 28))
                Text(msg).font(.system(size: 12, design: .rounded)).foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func sourceBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0x5EE7FF, opacity: 0.30), lineWidth: 1.2))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Paste pane

    private var pastePane: some View {
        TextEditor(text: $text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 140)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.3)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xFFE066, opacity: 0.32), lineWidth: 1.5))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Paste anything you're learning — a passage, problem, vocab list…")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.38))
                        .padding(20)
                        .allowsHitTesting(false)
                }
            }
    }

    // MARK: - Examples

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("⚡ TRY ONE OF THESE")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(0.5)
                .foregroundColor(Color(hex: 0xFFE066, opacity: 0.85))
            FlowLayout(spacing: 7) {
                ForEach(Array(examples.enumerated()), id: \.offset) { _, ex in
                    Button(action: { text = ex.seed; fileName = "" }) {
                        HStack(spacing: 5) {
                            Text(ex.emoji)
                            Text(ex.label)
                        }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 11).padding(.vertical, 7)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                        .overlay(Capsule().stroke(Color(hex: 0x5EE7FF, opacity: 0.30), lineWidth: 1.2))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Grow stars button

    // Only rendered when canSubmit == true — no dimming needed
    private var growButton: some View {
        Button(action: { onGenerate(text, fileName) }) {
            HStack(spacing: 8) {
                Text("🌟")
                Text("Grow stars!")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(Color(hex: 0x3A2A00))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                Capsule().fill(LinearGradient(
                    colors: [Color(hex: 0xFFE066), Color(hex: 0xFFB300)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
            )
            .shadow(color: Color(hex: 0xFFB300, opacity: 0.45), radius: 14, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    // MARK: - OCR

    private func runOCR(on image: UIImage, source: String) {
        scanStatus = .scanning
        fileName = source
        Task { await performOCR(cgImage: image.cgImage, source: source) }
    }

    private func runOCROnPages(_ images: [UIImage], source: String) {
        scanStatus = .scanning
        fileName = source
        Task {
            var allLines: [String] = []
            for (i, img) in images.enumerated() {
                guard let cg = img.cgImage else { continue }
                var req = RecognizeTextRequest()
                req.recognitionLevel = .accurate
                req.usesLanguageCorrection = true
                let obs = try? await ImageRequestHandler(cg).perform(req)
                allLines.append("--- Page \(i + 1) ---")
                allLines.append(contentsOf: obs?.compactMap { $0.topCandidates(1).first?.string } ?? [])
            }
            await finishOCR(lines: allLines, source: source)
        }
    }

    private func performOCR(cgImage: CGImage?, source: String) async {
        guard let cg = cgImage else {
            await MainActor.run { scanStatus = .failed("Couldn't read image data.") }
            return
        }
        var req = RecognizeTextRequest()
        req.recognitionLevel = .accurate
        req.usesLanguageCorrection = true
        req.recognitionLanguages = [Locale.Language(identifier: "en-US")]
        guard let obs = try? await ImageRequestHandler(cg).perform(req) else {
            await MainActor.run { scanStatus = .failed("OCR failed — try again.") }
            return
        }
        await finishOCR(lines: obs.compactMap { $0.topCandidates(1).first?.string }, source: source)
    }

    @MainActor
    private func finishOCR(lines: [String], source: String) async {
        let fullText = lines.joined(separator: "\n")
        text = fullText
        let chunk = CurriculumChunk(id: UUID(), rawText: fullText, source: source, timestamp: Date())
        MemoryStore.shared.saveCurriculumScan(chunk)
        scanStatus = .done(lines: lines.count, words: chunk.wordCount, ragWindows: chunk.ragChunks().count)
    }
}

// MARK: - UIKit bridges

private struct ImagePickerRepresentable: UIViewControllerRepresentable {
    let source: UIImagePickerController.SourceType
    let onPick: (UIImage) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = source
        p.allowsEditing = false
        p.delegate = context.coordinator
        return p
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPick: (UIImage) -> Void
        init(onPick: @escaping (UIImage) -> Void) { self.onPick = onPick }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            if let img = (info[.editedImage] ?? info[.originalImage]) as? UIImage { onPick(img) }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}

private struct DocumentCameraRepresentable: UIViewControllerRepresentable {
    let onFinish: ([UIImage]) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onFinish: ([UIImage]) -> Void
        init(onFinish: @escaping ([UIImage]) -> Void) { self.onFinish = onFinish }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            controller.dismiss(animated: true)
            onFinish((0..<scan.pageCount).map { scan.imageOfPage(at: $0) })
        }
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true); onFinish([])
        }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            controller.dismiss(animated: true); onFinish([])
        }
    }
}
