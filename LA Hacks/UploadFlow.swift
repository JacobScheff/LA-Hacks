//
//  UploadFlow.swift
//  LA Hacks
//
//  Star Hop! upload-doc → grow-new-stars flow.
//  Three screens: pick → reading → reveal.
//  Ported from project/galaxy-upload.jsx.
//

import SwiftUI

// MARK: - Topic recipes (mocked picker by keyword)

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
        topics: [
            ("Reading Notes","🎼"), ("Beats & Rhythm","🥁"), ("Loud & Soft","🔊"),
            ("Major vs Minor","🎹"), ("Song Shapes","🎶"),
        ]
    ),
    TopicRecipe(
        keywords: ["code","program","computer","scratch","python","js"],
        matchConstellationId: nil,
        newName: "Code Cosmos", newEmoji: "💻",
        newSkyStory: "A new cluster of stars just blinked on. Computer thinking is its own kind of magic!",
        topics: [
            ("Sequences","➡️"), ("Loops","🔁"), ("If / Then","🔀"),
            ("Variables","📦"), ("Bugs!","🐛"),
        ]
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
                status: .gap, size: 5, mastery: 0
            )
        }
        return GenerationOutcome(
            result: GenerationResult(
                isNew: false,
                constellationName: target.name,
                emoji: target.emoji,
                addedTopics: recipe.topics,
                neighborTopics: [],
                jumpTo: (baseX, baseY, 1.0)
            ),
            targetConstellationId: target.id,
            addedNodes: addedNodes,
            newConstellation: nil
        )
    }

    // Brand-new constellation in lower-right open spot
    let cx: CGFloat = 760, cy: CGFloat = 1450
    let positions = makeNewClusterPositions(count: recipe.topics.count, cx: cx, cy: cy)
    let newId = "gen-\(now)"
    let primary: [StarNode] = recipe.topics.enumerated().map { i, t in
        StarNode(
            id: "\(newId)-\(i)",
            label: t.label, star: "New ✨", emoji: t.emoji,
            x: positions[i].0, y: positions[i].1,
            status: .gap, size: 5, mastery: 0
        )
    }
    let neighborPool: [(label: String, emoji: String)] = [
        ("Bonus Idea","🎁"), ("Try This Too","🌱"),
        ("Cool Detail","🔍"), ("Big Picture","🖼️"),
        ("Real-world Use","🌎"),
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
            status: .locked, size: 3.5, mastery: nil
        )
    }
    var edges: [Edge] = []
    for i in 0..<(primary.count - 1) {
        edges.append(Edge(a: primary[i].id, b: primary[i + 1].id))
    }
    for (i, nn) in neighbors.enumerated() {
        edges.append(Edge(a: primary[i].id, b: nn.id))
    }

    let newConstellation = Constellation(
        id: newId,
        name: recipe.newName ?? "New Skies",
        realName: "A new constellation",
        nickname: "",
        emoji: recipe.newEmoji ?? "✨",
        course: "Just for you · made by Nova",
        blurb: "New stars Nova found in your doc.",
        skyStory: recipe.newSkyStory ?? "Nova made this constellation just for you.",
        centroid: CGPoint(x: cx, y: cy),
        nodes: primary + neighbors,
        edges: edges
    )
    return GenerationOutcome(
        result: GenerationResult(
            isNew: true,
            constellationName: recipe.newName ?? "New Skies",
            emoji: recipe.newEmoji ?? "✨",
            addedTopics: recipe.topics,
            neighborTopics: neighborTopics,
            jumpTo: (cx, cy, 0.9)
        ),
        targetConstellationId: nil,
        addedNodes: [],
        newConstellation: newConstellation
    )
}

// MARK: - Upload modal (pick)

struct UploadModal: View {
    let onClose: () -> Void
    let onGenerate: (_ text: String, _ fileName: String) -> Void

    @State private var tab: PickTab = .file
    @State private var text: String = ""
    @State private var fileName: String = ""

    enum PickTab: String, CaseIterable {
        case file, paste, link
        var label: String {
            switch self {
            case .file: return "📎 Upload"
            case .paste: return "📝 Paste text"
            case .link: return "🔗 Link"
            }
        }
    }

    private let examples: [(label: String, emoji: String, seed: String)] = [
        ("Math worksheet", "➗", "math worksheet adding subtracting"),
        ("Reading passage", "📖", "reading story passage character"),
        ("Music notes", "🎵", "music notes rhythm"),
        ("Coding lesson", "💻", "code program loops"),
    ]

    var body: some View {
        ZStack {
            Color(hex: 0x04060E, opacity: 0.7)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                modal
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var modal: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 40, height: 4)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .onTapGesture { onClose() }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero.padding(.bottom, 16)
                    tabs.padding(.bottom, 14)

                    Group {
                        switch tab {
                        case .file: filePane
                        case .paste: pastePane
                        case .link: linkPane
                        }
                    }
                    .padding(.bottom, 18)

                    examplesSection
                        .padding(.bottom, 22)
                }
                .padding(.horizontal, 18)
            }

            footer
        }
        .containerRelativeFrame(.vertical) { length, _ in length * 0.94 }
        .background(
            LinearGradient(
                colors: [Color(hex: 0x1A0B40), Color(hex: 0x0E0626)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipShape(.rect(topLeadingRadius: 28, topTrailingRadius: 28))
        .overlay(
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .stroke(Color(hex: 0xFFE066, opacity: 0.35), lineWidth: 1.5)
                .ignoresSafeArea(edges: .bottom)
        )
        .foregroundColor(.white)
    }

    private var hero: some View {
        HStack(spacing: 14) {
            // Nova with magnifier — emoji rendition
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: 0xFF8A4C), Color(hex: 0xFF8A4C, opacity: 0.6)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 64, height: 64)
                Text("🦊").font(.system(size: 36))
                Text("🔍")
                    .font(.system(size: 28))
                    .offset(x: 24, y: 22)
            }
            .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: 2) {
                Text("✨ NEW SKIES")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(Color(hex: 0xFFE066))
                Text("Show Nova a doc!")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Drop in a worksheet, photo, or anything you're learning. Nova will turn it into stars to play with.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.78))
                    .lineSpacing(1)
                    .padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
    }

    private var tabs: some View {
        HStack(spacing: 6) {
            ForEach(PickTab.allCases, id: \.self) { t in
                let active = tab == t
                Button(action: { tab = t }) {
                    Text(t.label)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(active ? Color(hex: 0x3A2A00) : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
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
        .background(
            Capsule().fill(Color.black.opacity(0.3))
        )
    }

    private var filePane: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("📂").font(.system(size: 38))
                if !fileName.isEmpty {
                    Text("Got it! ✨")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0xFFE066))
                    Text(fileName)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                    Text("Tap \"Grow stars!\" below")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .padding(.top, 8)
                } else {
                    Text("Drop a file here")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("or tap to pick from your device")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                        .padding(.bottom, 8)
                    HStack(spacing: 6) {
                        ForEach(["📄 PDF","🖼️ Photo","📝 Doc","🎤 Audio","✍️ Text"], id: \.self) { t in
                            Text(t)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.75))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16))
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        Color(hex: 0xFFE066, opacity: 0.45),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
            )
            .onTapGesture {
                // Mock file pick — set a sample filename so user can test the flow
                fileName = "homework.pdf"
                text = fileName
            }
        }
    }

    private var pastePane: some View {
        TextEditor(text: $text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 130)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: 0xFFE066, opacity: 0.35), lineWidth: 2)
            )
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Paste anything you're learning… a passage, a problem, a list of words…")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(20)
                        .allowsHitTesting(false)
                }
            }
    }

    private var linkPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("", text: $text, prompt: Text("Paste a link (article, video, lesson)…")
                .foregroundColor(.white.opacity(0.45)))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.black.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(hex: 0xFFE066, opacity: 0.35), lineWidth: 2)
                )
            Text("💡 Tip: works great with Wikipedia, news, Khan Academy, YouTube")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
                .padding(.leading, 4)
        }
    }

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("⚡ TRY ONE OF THESE")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(0.6)
                .foregroundColor(Color(hex: 0xFFE066, opacity: 0.95))
            FlowLayout(spacing: 7) {
                ForEach(Array(examples.enumerated()), id: \.offset) { _, ex in
                    Button(action: {
                        tab = .paste
                        text = ex.seed
                        fileName = ""
                    }) {
                        HStack(spacing: 6) {
                            Text(ex.emoji)
                            Text(ex.label)
                        }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                        .overlay(Capsule().stroke(Color(hex: 0x5EE7FF, opacity: 0.35), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var canSubmit: Bool {
        switch tab {
        case .file: return !fileName.isEmpty
        case .paste, .link: return !text.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.white.opacity(0.05)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1.5))
            }
            .buttonStyle(.plain)

            Button(action: {
                onGenerate(text, fileName)
            }) {
                Text("🌟 Grow stars!")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: 0x3A2A00))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule().fill(
                            canSubmit
                            ? AnyShapeStyle(LinearGradient(
                                colors: [Color(hex: 0xFFE066), Color(hex: 0xFFB300)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color(hex: 0xFFE066, opacity: 0.25))
                        )
                    )
                    .shadow(color: canSubmit ? Color(hex: 0xFFB300, opacity: 0.5) : .clear, radius: 16, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.55)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color.clear, Color(hex: 0x0E0626)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }
}

// MARK: - ReadingScreen

struct ReadingScreen: View {
    let stage: Int

    private let messages = [
        "Nova is squinting at every word…",
        "Spotting big ideas…",
        "Sorting them into stars…",
        "Almost ready! ✨",
    ]

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: 0x2A0F5C), Color(hex: 0x0E0626)],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 0, endRadius: 700
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()
                hero
                Text("✨ READING YOUR DOC")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1)
                    .foregroundColor(Color(hex: 0xFFE066))
                Text("Nova is investigating…")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(messages[min(stage, messages.count - 1)])
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(minHeight: 22)

                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule()
                            .fill(i <= stage ? Color(hex: 0xFFE066) : Color.white.opacity(0.15))
                            .frame(width: i <= stage ? 24 : 8, height: 8)
                            .shadow(color: i <= stage ? Color(hex: 0xFFE066, opacity: 0.7) : .clear, radius: 4)
                            .animation(.easeOut(duration: 0.3), value: stage)
                    }
                }
                .padding(.top, 6)
                Spacer()
            }
        }
    }

    private var hero: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                // Pulsing rings
                ForEach(0..<3, id: \.self) { i in
                    let phase = (t + Double(i) * 0.6).truncatingRemainder(dividingBy: 2.4) / 2.4
                    Circle()
                        .stroke(Color(hex: 0xFFE066, opacity: 0.5 * (1 - phase)), lineWidth: 2)
                        .scaleEffect(0.8 + 0.8 * phase)
                }
                .frame(width: 200, height: 200)

                // Flying docs around
                ForEach(0..<5, id: \.self) { i in
                    let dur = 2.6
                    let phase = (t + Double(i) * 0.3).truncatingRemainder(dividingBy: dur) / dur
                    let p = 1.0 - phase
                    let starts: [CGSize] = [
                        CGSize(width: -110, height: -80),
                        CGSize(width:  120, height: -90),
                        CGSize(width: -130, height:  60),
                        CGSize(width:  110, height:  70),
                        CGSize(width:    0, height: -130),
                    ]
                    let st = starts[i]
                    let alpha = phase < 0.15 ? phase / 0.15 : phase > 0.9 ? (1 - phase) / 0.1 * 0.6 : 1.0
                    Text("📄")
                        .font(.system(size: 30))
                        .offset(x: CGFloat(p) * st.width, y: CGFloat(p) * st.height)
                        .scaleEffect(0.4 + 0.6 * phase)
                        .opacity(alpha)
                }

                // Center: Nova with magnifier
                ZStack {
                    Text("🦊").font(.system(size: 80))
                    Text("🔍")
                        .font(.system(size: 40))
                        .offset(x: 28, y: 30 + CGFloat(sin(t * 1.8)) * 4)
                }

                // Sparkles around the edge
                Group {
                    Text("✨").position(x: 30, y: 30)
                    Text("⭐").position(x: 180, y: 50)
                    Text("💫").position(x: 30, y: 180)
                    Text("✨").position(x: 180, y: 180)
                }
                .font(.system(size: 18))
                .scaleEffect(1.0 + 0.2 * CGFloat(sin(t * 3.5)))
            }
            .frame(width: 220, height: 220)
        }
    }
}

// MARK: - RevealScreen

struct RevealScreen: View {
    let result: GenerationResult
    let onClose: () -> Void
    let onExplore: () -> Void

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: 0x2A0F5C), Color(hex: 0x0E0626)],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 0, endRadius: 700
            )
            .ignoresSafeArea()

            confettiOverlay

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    HStack(alignment: .center, spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(RadialGradient(
                                    colors: [Color(hex: 0xFFE066, opacity: 0.4), .clear],
                                    center: .center, startRadius: 0, endRadius: 50
                                ))
                            Text(result.emoji)
                                .font(.system(size: 52))
                                .shadow(color: Color(hex: 0xFFE066, opacity: 0.9), radius: 16)
                        }
                        .frame(width: 80, height: 80)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.isNew ? "🌟 NEW CONSTELLATION!" : "✨ NEW STARS ADDED!")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .tracking(1.2)
                                .foregroundColor(Color(hex: 0xFFE066))
                            Text(result.constellationName)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 14)

                    Text(summaryText)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 18)

                    VStack(spacing: 8) {
                        ForEach(Array(result.addedTopics.enumerated()), id: \.offset) { _, t in
                            topicRow(label: t.label, emoji: t.emoji)
                        }
                        if !result.neighborTopics.isEmpty {
                            neighborBlock
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 18)

                    HStack(spacing: 10) {
                        Button(action: onClose) {
                            Text("Later")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(Color.white.opacity(0.05)))
                                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)

                        Button(action: onExplore) {
                            Text("🚀 Show me the stars!")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: 0x3A2A00))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: 0xFFE066), Color(hex: 0xFFB300)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Capsule())
                                .shadow(color: Color(hex: 0xFFB300, opacity: 0.5), radius: 16, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 30)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var summaryText: String {
        if result.isNew {
            let extra = result.neighborTopics.isEmpty ? "" : " Plus \(result.neighborTopics.count) sleepy stars nearby waiting for you!"
            return "Nova found \(result.addedTopics.count) new ideas in your doc and grew them into a brand-new constellation.\(extra)"
        } else {
            return "Nova added \(result.addedTopics.count) new stars to \(result.constellationName). Time to wake them up!"
        }
    }

    private func topicRow(label: String, emoji: String) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: 0xFFE066, opacity: 0.25))
                )

            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text("New star · sleepy ⭐")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: 0xFFE066, opacity: 0.18), Color(hex: 0xFF8AD8, opacity: 0.12)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: 0xFFE066, opacity: 0.4), lineWidth: 1.5)
        )
    }

    private var neighborBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("💤 Plus \(result.neighborTopics.count) bonus sleepy stars nearby:")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: 0x5EE7FF))
            Text(result.neighborTopics.map { "\($0.emoji) \($0.label)" }.joined(separator: " · "))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: 0x5EE7FF, opacity: 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(hex: 0x5EE7FF, opacity: 0.4),
                              style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
    }

    private var confettiOverlay: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let colors: [UInt32] = [0xFFE066, 0xFF8AD8, 0x5EE7FF, 0xA78BFA, 0xFF8A4C]
                var seed: UInt64 = 42
                func r() -> Double {
                    seed = (seed &* 9301 &+ 49297) % 233280
                    return Double(seed) / 233280.0
                }
                for i in 0..<30 {
                    let left = r() * 100
                    let delay = r() * 1.4
                    let dur = 2.4 + r() * 1.6
                    let color = colors[Int(r() * Double(colors.count)) % colors.count]
                    let isCircle = r() > 0.5
                    let sz = 8 + r() * 8
                    let phase = ((t + delay).truncatingRemainder(dividingBy: dur)) / dur
                    let x = left / 100 * Double(size.width)
                    let y = phase * Double(size.height + 60) - 30
                    let alpha = phase < 0.15 ? phase / 0.15 : 0.6 + 0.4 * (1 - phase)
                    let rotation = Double(i) + phase * 6.28
                    var p = ctx
                    p.translateBy(x: x, y: y)
                    p.rotate(by: .radians(rotation))
                    let rect = CGRect(x: -sz/2, y: -sz/2, width: sz, height: sz)
                    if isCircle {
                        p.fill(Path(ellipseIn: rect), with: .color(Color(hex: color).opacity(alpha)))
                    } else {
                        p.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(Color(hex: color).opacity(alpha)))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
