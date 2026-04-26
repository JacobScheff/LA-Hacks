//
//  LearningGalaxyView.swift
//  LA Hacks
//
//  Star Hop! main pannable / zoomable galaxy + tab routing.
//

import SwiftUI
import Combine

// MARK: - Tab routing

enum GalaxyTab: String, Hashable {
    case galaxy, study, nova, profile
}

/// App-level state shared between Galaxy + tabs (so an upload-grown
/// constellation persists when you flip away and back).
@MainActor
final class GalaxyState: ObservableObject {
    @Published var constellations: [Constellation] = GalaxyData.constellations
    @Published var pendingNewIds: Set<String> = []

    var stats: (mastered: Int, gaps: Int, learning: Int) {
        var m = 0, g = 0, l = 0
        for c in constellations {
            for n in c.nodes {
                switch n.status {
                case .mastered: m += 1
                case .gap:      g += 1
                case .learning: l += 1
                case .locked:   break
                }
            }
        }
        return (m, g, l)
    }

    func nodesById() -> [String: (node: StarNode, constellationId: String, constellationName: String, constellationEmoji: String)] {
        var out: [String: (StarNode, String, String, String)] = [:]
        for c in constellations {
            for n in c.nodes { out[n.id] = (n, c.id, c.name, c.emoji) }
        }
        return out
    }
}

// MARK: - Root view

struct LearningGalaxyView: View {
    @State private var tab: GalaxyTab = .galaxy
    @State private var trainingNode: StarNode?
    @State private var lessonNode: StarNode?
    @StateObject private var state = GalaxyState()

    init() {
        let bar = UITabBarAppearance()
        bar.configureWithOpaqueBackground()
        bar.backgroundColor = UIColor(red: 0.04, green: 0.02, blue: 0.11, alpha: 0.97)
        bar.shadowColor = .clear

        let gold = UIColor(red: 1.0, green: 0.878, blue: 0.4, alpha: 1.0)
        let dim  = UIColor.white.withAlphaComponent(0.28)

        bar.stackedLayoutAppearance.normal.titleTextAttributes   = [.foregroundColor: dim]
        bar.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: gold]

        UITabBar.appearance().standardAppearance   = bar
        UITabBar.appearance().scrollEdgeAppearance = bar
    }

    var body: some View {
        TabView(selection: $tab) {
            Tab(value: GalaxyTab.galaxy) {
                GalaxyScreen(onTrain: { trainingNode = $0 })
                    .environmentObject(state)
                    .ignoresSafeArea()
            } label: {
                Label { Text("Galaxy") } icon: { Image(uiImage: Self.emojiTabIcon("🌌")) }
            }

            Tab(value: GalaxyTab.study) {
                StudyTab(onBeginQuest: {
                    trainingNode = LearningGalaxyView.makeSyntheticNode(
                        label: "Adding Slices", emoji: "🍕", status: .gap)
                })
                .background { tabBackground }
            } label: {
                Label { Text("Quests") } icon: { Image(uiImage: Self.emojiTabIcon("🎯")) }
            }

            Tab(value: GalaxyTab.nova) {
                NovaAITab()
                    .background { tabBackground }
            } label: {
                Label { Text("Nova") } icon: { Image(uiImage: Self.emojiTabIcon("🦊")) }
            }

            Tab(value: GalaxyTab.profile) {
                YouTab()
                    .background { tabBackground }
            } label: {
                Label { Text("Me") } icon: { Image(uiImage: Self.emojiTabIcon("👤")) }
            }
        }
        .tint(Color(hex: 0xFFE066))
        .preferredColorScheme(.dark)
        .overlay {
            if let node = trainingNode {
                TrainingOverlay(
                    node: node,
                    onClose: { trainingNode = nil },
                    onStart: { n in trainingNode = nil; lessonNode = n }
                )
                .transition(.opacity)
            }
            if let node = lessonNode {
                LessonView(node: node, onClose: { lessonNode = nil })
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.3), value: trainingNode?.id)
        .animation(.easeOut(duration: 0.3), value: lessonNode?.id)
    }

    static func emojiTabIcon(_ emoji: String) -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let img = UIGraphicsImageRenderer(size: size).image { _ in
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 26)]
            let s = emoji as NSString
            let sz = s.size(withAttributes: attrs)
            s.draw(at: CGPoint(x: (size.width - sz.width) / 2,
                               y: (size.height - sz.height) / 2),
                   withAttributes: attrs)
        }
        return img.withRenderingMode(.alwaysOriginal)
    }

    static func makeSyntheticNode(label: String, emoji: String, status: StarStatus) -> StarNode {
        StarNode(
            id: "synthetic-\(label.lowercased().replacingOccurrences(of: " ", with: "-"))",
            label: label, star: nil, emoji: emoji,
            x: 0, y: 0, status: status, size: 5,
            mastery: status == .mastered ? 1.0 : 0.4
        )
    }

    /// Shared background for non-galaxy tabs: nebula wash + star dust, full bleed.
    private var tabBackground: some View {
        ZStack {
            backdrop
            dustOverlay
        }
        .ignoresSafeArea()
    }

    /// Background gradients — richer multi-stop nebula washes.
    private var backdrop: some View {
        ZStack {
            Color(hex: 0x07021A)
            // Top-left magenta nebula
            RadialGradient(
                colors: [Color(hex: 0xFF5DC8, opacity: 0.52), Color(hex: 0xC030A0, opacity: 0.22), .clear],
                center: UnitPoint(x: 0.22, y: 0.10),
                startRadius: 0, endRadius: 500
            )
            // Bottom-right cyan nebula
            RadialGradient(
                colors: [Color(hex: 0x28E8FF, opacity: 0.46), Color(hex: 0x08B8D8, opacity: 0.16), .clear],
                center: UnitPoint(x: 0.80, y: 0.82),
                startRadius: 0, endRadius: 460
            )
            // Center deep violet
            RadialGradient(
                colors: [Color(hex: 0x8030E8, opacity: 0.44), Color(hex: 0x5010C0, opacity: 0.14), .clear],
                center: UnitPoint(x: 0.52, y: 0.48),
                startRadius: 0, endRadius: 580
            )
            // Top-right warm orange accent
            RadialGradient(
                colors: [Color(hex: 0xFF8020, opacity: 0.26), .clear],
                center: UnitPoint(x: 0.92, y: 0.06),
                startRadius: 0, endRadius: 260
            )
            // Bottom-left indigo accent
            RadialGradient(
                colors: [Color(hex: 0x2040D8, opacity: 0.30), .clear],
                center: UnitPoint(x: 0.06, y: 0.92),
                startRadius: 0, endRadius: 300
            )
        }
    }

    /// Faint star dust across non-galaxy tabs (mirrors TabFrame in Learning Galaxy.html).
    private var dustOverlay: some View {
        Canvas { ctx, size in
            let pts: [(CGFloat, CGFloat, CGFloat, Double)] = [
                (0.18, 0.22, 0.7, 0.50),
                (0.82, 0.38, 0.6, 0.40),
                (0.35, 0.78, 0.6, 0.40),
                (0.70, 0.92, 0.6, 0.30),
                (0.50, 0.52, 0.5, 0.22),
                (0.10, 0.55, 0.4, 0.30),
                (0.92, 0.62, 0.5, 0.30),
                (0.45, 0.10, 0.4, 0.30),
            ]
            for (px, py, pr, op) in pts {
                let x = px * size.width, y = py * size.height
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - pr, y: y - pr, width: pr * 2, height: pr * 2)),
                    with: .color(.white.opacity(op))
                )
            }
        }
        .allowsHitTesting(false)
        .opacity(0.6)
    }
}

// MARK: - Galaxy screen

struct GalaxyScreen: View {
    @EnvironmentObject var state: GalaxyState
    let onTrain: (StarNode) -> Void

    // Pan + zoom state
    @State private var tx: CGFloat = -50
    @State private var ty: CGFloat = 180
    @State private var scale: CGFloat = 0.5

    // In-flight gesture deltas
    @State private var dragOffset: CGSize = .zero
    @State private var pinchDelta: CGFloat = 1.0
    // Focal-point correction applied while pinching
    @State private var pinchTxCorr: CGFloat = 0
    @State private var pinchTyCorr: CGFloat = 0

    // Selection / overlays
    @State private var selected: StarNode?
    @State private var filter: StarStatus? = nil
    @State private var modalConstellation: Constellation?

    // Filter chip "all" support — kept separate so we can show 'all' as a
    // selected state when filter is nil.
    @State private var showAllPill = true

    // Upload flow
    @State private var uploadStage: UploadStage = .idle
    @State private var readingStep: Int = 0
    @State private var revealResult: GenerationResult?

    // Telescope warp-in animation
    private enum WarpPhase { case enter, exit, done }
    @State private var warpPhase: WarpPhase = .enter
    @State private var warpScale: CGFloat = 0.05
    @State private var warpBlur: CGFloat = 22
    @State private var warpBrightness: Double = -0.7
    @State private var telescopeScale: CGFloat = 1.0
    @State private var lastTabLeave: Date?
    @State private var warpGeneration: Int = 0

    enum UploadStage { case idle, pick, reading, reveal }

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height
            let safeTop = geo.safeAreaInsets.top
            let safeBot = geo.safeAreaInsets.bottom

            ZStack(alignment: .top) {
                galaxyBackdrop

                // World layer — pan + zoom
                ZStack {
                    SkyCanvas(
                        constellations: state.constellations,
                        pendingNewIds: state.pendingNewIds,
                        tx: tx + dragOffset.width + pinchTxCorr,
                        ty: ty + dragOffset.height + pinchTyCorr,
                        scale: scale * pinchDelta,
                        selectedId: selected?.id,
                        focusedConstellationId: focusedConstellationId,
                        filter: filter,
                        showDiscoverNebula: state.constellations.count == GalaxyData.constellations.count
                    )
                    .allowsHitTesting(false)

                    GalaxyHitLayer(
                        constellations: state.constellations,
                        tx: tx + dragOffset.width + pinchTxCorr,
                        ty: ty + dragOffset.height + pinchTyCorr,
                        scale: scale * pinchDelta,
                        showDiscoverNebula: state.constellations.count == GalaxyData.constellations.count,
                        onTapStar: { handleStarTap($0, viewport: geo.size) },
                        onTapConstellation: { c in modalConstellation = c },
                        onTapDiscover: { uploadStage = .pick }
                    )
                }
                .contentShape(Rectangle())
                .simultaneousGesture(makeGesture(W: W, H: H))

                // Top fade — translucent dark gradient, no hard edge
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: 0x07021A, opacity: 0.96), location: 0.00),
                        .init(color: Color(hex: 0x0D0530, opacity: 0.90), location: 0.10),
                        .init(color: Color(hex: 0x0D0530, opacity: 0.78), location: 0.22),
                        .init(color: Color(hex: 0x08041A, opacity: 0.52), location: 0.40),
                        .init(color: Color(hex: 0x08041A, opacity: 0.18), location: 0.60),
                        .init(color: Color(hex: 0x08041A, opacity: 0.00), location: 1.00),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 340)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)

                // Bottom fade
                LinearGradient(
                    colors: [
                        Color(hex: 0x08041A, opacity: 0.0),
                        Color(hex: 0x08041A, opacity: 0.7),
                        Color(hex: 0x08041A, opacity: 0.95),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 180)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)

                TopHeader(stats: state.stats, filter: filter, onFilter: { filter = $0 }, topInset: safeTop)

                if selected == nil {
                    HintPill(gaps: state.stats.gaps)
                        .padding(.bottom, 82 + max(safeBot, 10))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .allowsHitTesting(false)
                }

                // Upload flow overlays
                switch uploadStage {
                case .idle: EmptyView()
                case .pick:
                    UploadModal(
                        onClose: { uploadStage = .idle },
                        onGenerate: startGenerate
                    )
                    .zIndex(95)
                    .transition(.opacity)
                case .reading:
                    ReadingScreen(stage: readingStep)
                        .zIndex(95)
                        .transition(.opacity)
                case .reveal:
                    if let r = revealResult {
                        RevealScreen(
                            result: r,
                            onClose: closeReveal,
                            onExplore: { exploreReveal(viewport: geo.size) }
                        )
                        .zIndex(95)
                        .transition(.opacity)
                    }
                }
            }
            .frame(width: W, height: H)
            .clipped()
            .sheet(item: $selected) { node in
                SkillSheet(
                    node: node,
                    onTrain: { n in
                        selected = nil
                        onTrain(n)
                    }
                )
            }
            .sheet(item: $modalConstellation) { c in
                ConstellationModal(
                    constellation: c,
                    onJumpToStar: { node in
                        modalConstellation = nil
                        handleStarTap(node, viewport: geo.size)
                    }
                )
            }
            .animation(.easeOut(duration: 0.25), value: selected?.id)
            .animation(.easeOut(duration: 0.25), value: uploadStage)
            .scaleEffect(warpScale)
            .blur(radius: warpBlur)
            .brightness(warpBrightness)
            .overlay(alignment: .center) {
                if warpPhase != .done {
                    TelescopeOverlayView(viewW: W, viewH: H)
                        .scaleEffect(telescopeScale, anchor: UnitPoint(x: 0.5, y: 0.48))
                        .allowsHitTesting(false)
                }
            }
            .onAppear {
                let elapsed = lastTabLeave.map { Date().timeIntervalSince($0) } ?? .infinity
                guard elapsed > 3.0 else { return }
                warpGeneration += 1
                warpPhase = .enter
                warpScale = 0.05
                warpBlur = 22
                warpBrightness = -0.7
                telescopeScale = 1.0
                startWarp()
            }
            .onDisappear {
                lastTabLeave = Date()
                warpGeneration += 1
                warpPhase = .done
                warpScale = 1.0
                warpBlur = 0
                warpBrightness = 0
                telescopeScale = 1.0
            }
        }
        .ignoresSafeArea()
    }

    // MARK: Backdrop layers

    private var galaxyBackdrop: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: 0x3C145A, opacity: 0.55), Color(hex: 0x08041A, opacity: 1)],
                center: UnitPoint(x: 0.5, y: 0.4),
                startRadius: 0, endRadius: 600
            )
        }
        .allowsHitTesting(false)
    }

    private func startWarp() {
        let gen = warpGeneration
        // Phase 1: zoom blast from 0.05 to 1.2x (1.0s)
        withAnimation(.timingCurve(0.22, 1.0, 0.36, 1.0, duration: 1.0)) {
            warpScale = 1.2
            warpBlur = 0
            warpBrightness = 0
        }
        // Phase 2: snap back below 1.0 (0.18s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard warpGeneration == gen else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                warpScale = 0.9
            }
        }
        // Phase 3: spring settle at 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.18) {
            guard warpGeneration == gen else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                warpScale = 1.0
            }
        }
        // Telescope overlay expands away
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.43) {
            guard warpGeneration == gen else { return }
            warpPhase = .exit
            withAnimation(.timingCurve(0.3, 0.0, 0.8, 1.0, duration: 0.45)) {
                telescopeScale = 3.4
            }
        }
        // Done
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.93) {
            guard warpGeneration == gen else { return }
            warpPhase = .done
            telescopeScale = 1.0
        }
    }

    private var focusedConstellationId: String? {
        guard let s = selected else { return nil }
        return state.nodesById()[s.id]?.constellationId
    }

    // MARK: Gestures

    private func clampOffset(tx: CGFloat, ty: CGFloat, scale: CGFloat, W: CGFloat, H: CGFloat) -> (CGFloat, CGFloat) {
        // Derive world bounds from actual star positions so they tighten/grow with content.
        let wsc: CGFloat = 1.3
        let allNodes = state.constellations.flatMap(\.nodes)
        let rawMaxX = allNodes.map(\.x).max() ?? GalaxyData.SKY_W
        let rawMaxY = allNodes.map(\.y).max() ?? GalaxyData.SKY_H
        // Always include the discover-nebula at (760, 1450) even when it has no stars yet.
        let pad: CGFloat = 110
        let worldW = (max(rawMaxX, 760) + pad) * wsc
        let worldH = (max(rawMaxY, 1450) + pad) * wsc
        let margin: CGFloat = 120
        let clampedTx = max(margin - worldW * scale, min(W - margin, tx))
        let clampedTy = max(margin - worldH * scale, min(H - margin, ty))
        return (clampedTx, clampedTy)
    }

    private func makeGesture(W: CGFloat, H: CGFloat) -> some Gesture {
        SimultaneousGesture(
            DragGesture(minimumDistance: 4)
                .onChanged { v in
                    let (cTx, cTy) = clampOffset(
                        tx: tx + v.translation.width,
                        ty: ty + v.translation.height,
                        scale: scale, W: W, H: H
                    )
                    dragOffset = CGSize(width: cTx - tx, height: cTy - ty)
                }
                .onEnded { _ in
                    tx += dragOffset.width
                    ty += dragOffset.height
                    dragOffset = .zero
                },
            MagnifyGesture()
                .onChanged { v in
                    let focal = v.startLocation
                    let rawD = v.magnification
                    let newScale = max(0.35, min(2.5, scale * rawD))
                    let d = newScale / scale
                    pinchDelta = d
                    pinchTxCorr = (focal.x - tx) * (1 - d)
                    pinchTyCorr = (focal.y - ty) * (1 - d)
                }
                .onEnded { v in
                    let focal = v.startLocation
                    let rawD = v.magnification
                    let newScale = max(0.35, min(2.5, scale * rawD))
                    let d = newScale / scale
                    let (cTx, cTy) = clampOffset(
                        tx: tx + (focal.x - tx) * (1 - d),
                        ty: ty + (focal.y - ty) * (1 - d),
                        scale: newScale, W: W, H: H
                    )
                    tx = cTx; ty = cTy; scale = newScale
                    pinchDelta = 1.0; pinchTxCorr = 0; pinchTyCorr = 0
                }
        )
    }

    // MARK: Tap handling

    private func handleStarTap(_ node: StarNode, viewport: CGSize) {
        let viewW = viewport.width
        let viewH = viewport.height
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            scale = 1.0
            tx = viewW / 2 - node.x
            ty = viewH * 0.35 - node.y
            selected = node
        }
    }

    // MARK: Upload flow

    private func startGenerate(text: String, fileName: String) {
        let built = buildGenerationResult(
            text: text, fileName: fileName,
            constellations: state.constellations
        )
        uploadStage = .reading
        readingStep = 0
        let delays: [Double] = [0.6, 1.1, 1.7, 2.3]
        for (i, d) in delays.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                self.readingStep = min(i, 3)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) {
            // commit nodes
            if let new = built.newConstellation {
                state.constellations.append(new)
                state.pendingNewIds = Set(new.nodes.map { $0.id })
            } else if let targetId = built.targetConstellationId, !built.addedNodes.isEmpty {
                if let idx = state.constellations.firstIndex(where: { $0.id == targetId }) {
                    let c = state.constellations[idx]
                    let updated = Constellation(
                        id: c.id, name: c.name, realName: c.realName, nickname: c.nickname,
                        emoji: c.emoji, course: c.course, blurb: c.blurb, skyStory: c.skyStory,
                        centroid: c.centroid,
                        nodes: c.nodes + built.addedNodes,
                        edges: c.edges
                    )
                    state.constellations[idx] = updated
                    state.pendingNewIds = Set(built.addedNodes.map { $0.id })
                }
            }
            self.revealResult = built.result
            self.uploadStage = .reveal
        }
    }

    private func closeReveal() {
        uploadStage = .idle
        revealResult = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            state.pendingNewIds.removeAll()
        }
    }

    private func exploreReveal(viewport: CGSize) {
        if let r = revealResult, let jump = r.jumpTo {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                scale = jump.scale
                tx = viewport.width / 2 - jump.x * jump.scale
                ty = viewport.height * 0.4 - jump.y * jump.scale
            }
        }
        closeReveal()
    }
}

// MARK: - Sky Canvas (pure render)

struct SkyCanvas: View {
    let constellations: [Constellation]
    let pendingNewIds: Set<String>
    let tx: CGFloat
    let ty: CGFloat
    let scale: CGFloat
    let selectedId: String?
    let focusedConstellationId: String?
    let filter: StarStatus?
    let showDiscoverNebula: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let wsc: CGFloat = 1.3

                // Parallax star layers drawn in screen space before the world transform
                drawParallaxStars(ctx: ctx, t: t)

                ctx.translateBy(x: tx, y: ty)
                ctx.scaleBy(x: scale * wsc, y: scale * wsc)

                drawBackdrop(ctx: &ctx, t: t)
                drawBridges(ctx: &ctx)
                drawConstellations(ctx: &ctx)
                if showDiscoverNebula {
                    drawDiscoverNebula(ctx: &ctx, t: t, cx: 760, cy: 1450)
                }
                drawStars(ctx: &ctx, t: t, scale: scale)
            }
        }
    }

    // MARK: Parallax star field

    private func drawParallaxStars(ctx: GraphicsContext, t: TimeInterval) {
        // Far layer — barely moves, creates infinite-depth feeling
        var farCtx = ctx
        farCtx.translateBy(x: tx * 0.05, y: ty * 0.05)
        for s in GalaxyData.starLayers.far {
            farCtx.fill(
                Path(ellipseIn: CGRect(x: s.x - s.r, y: s.y - s.r, width: s.r * 2, height: s.r * 2)),
                with: .color((s.warm ? Color(hex: 0xD0E8FF) : .white).opacity(s.o))
            )
        }

        // Mid layer — gentle parallax + twinkling
        var midCtx = ctx
        midCtx.translateBy(x: tx * 0.16, y: ty * 0.16)
        for s in GalaxyData.starLayers.mid {
            let tw = 0.5 + 0.5 * sin(t / s.tw * 2 + s.td)
            let alpha = s.o * (0.2 + 0.8 * tw)
            midCtx.fill(
                Path(ellipseIn: CGRect(x: s.x - s.r, y: s.y - s.r, width: s.r * 2, height: s.r * 2)),
                with: .color((s.warm ? Color(hex: 0xFFE8C8) : .white).opacity(alpha))
            )
        }

        // Near layer — strongest parallax, soft halos, brightest
        var nearCtx = ctx
        nearCtx.translateBy(x: tx * 0.36, y: ty * 0.36)
        for s in GalaxyData.starLayers.near {
            let tw = 0.5 + 0.5 * sin(t / s.tw * 2 + s.td)
            let alpha = s.o * (0.25 + 0.75 * tw)
            let hR = s.r * 2.8
            nearCtx.fill(
                Path(ellipseIn: CGRect(x: s.x - hR, y: s.y - hR, width: hR * 2, height: hR * 2)),
                with: .color(s.warm ? Color(hex: 0xFFDCA0, opacity: 0.18) : Color(hex: 0xB4DCFF, opacity: 0.18))
            )
            nearCtx.fill(
                Path(ellipseIn: CGRect(x: s.x - s.r, y: s.y - s.r, width: s.r * 2, height: s.r * 2)),
                with: .color((s.warm ? Color(hex: 0xFFE4AA) : .white).opacity(alpha))
            )
        }
    }

    // MARK: Backdrop (Milky Way + nebulae + ~320 background stars)

    private func drawBackdrop(ctx: inout GraphicsContext, t: TimeInterval) {
        // Milky Way band — diagonal across the sky
        do {
            let cx: CGFloat = 500, cy: CGFloat = 800
            let rx: CGFloat = 900, ry: CGFloat = 180
            var p = ctx
            p.translateBy(x: cx, y: cy)
            p.rotate(by: .degrees(-22))
            p.translateBy(x: -cx, y: -cy)
            let rect = CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)
            let grad = Gradient(stops: [
                .init(color: Color(hex: 0xDCD2FF, opacity: 0.18), location: 0),
                .init(color: Color(hex: 0xDCD2FF, opacity: 0.11), location: 0.35),
                .init(color: Color(hex: 0xDCD2FF, opacity: 0.04), location: 0.70),
                .init(color: Color(hex: 0xDCD2FF, opacity: 0), location: 1),
            ])
            p.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(grad, center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: ry)
            )
        }

        // Nebulae behind each constellation — centered on actual constellation centroids.
        let nebulae: [(x: CGFloat, y: CGFloat, rx: CGFloat, ry: CGFloat, color: UInt32, opacity: Double)] = [
            // numbers  (BigDipper)  teal   centroid (250,300)
            (250, 295, 255, 210, 0x5EE7FF, 0.42),
            // fractions (Orion)     orange centroid (600,340) stars spread to y:470
            (600, 365, 280, 250, 0xFF8C3C, 0.44),
            // shapes   (Cassiopeia) purple centroid (235,600) stars to y:720
            (242, 625, 265, 230, 0xA855F7, 0.40),
            // time     (Leo)        yellow centroid (720,600) stars to x:880
            (772, 588, 290, 245, 0xFFE066, 0.40),
            // reading  (Lyra)       pink   centroid (220,940)
            (225, 952, 255, 235, 0xFF4FB6, 0.40),
            // writing  (Cygnus)     cyan   centroid (540,920)
            (540, 932, 275, 250, 0x5EE7FF, 0.40),
            // life     (Scorpius)   rose   centroid (820,280) stars span y:150→540
            (818, 345, 235, 300, 0xFF4FB6, 0.44),
            // earth    (LtlDipper)  green  centroid (800,1010)
            (820, 1038, 268, 268, 0x50E6A0, 0.36),
            // history  (Draco)      purple centroid (470,1240) stars to y:1380
            (470, 1258, 295, 290, 0xA855F7, 0.38),
        ]
        for n in nebulae {
            let rect = CGRect(x: n.x - n.rx, y: n.y - n.ry, width: n.rx * 2, height: n.ry * 2)
            let grad = Gradient(stops: [
                .init(color: Color(hex: n.color, opacity: n.opacity),            location: 0),
                .init(color: Color(hex: n.color, opacity: n.opacity * 0.62),     location: 0.28),
                .init(color: Color(hex: n.color, opacity: n.opacity * 0.28),     location: 0.58),
                .init(color: Color(hex: n.color, opacity: n.opacity * 0.07),     location: 0.82),
                .init(color: Color(hex: n.color, opacity: 0),                    location: 1),
            ])
            ctx.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(grad, center: CGPoint(x: n.x, y: n.y), startRadius: 0, endRadius: max(n.rx, n.ry))
            )
        }

    }

    // MARK: Bridges

    private func drawBridges(ctx: inout GraphicsContext) {
        let nodes = nodesByIdLocal()
        for e in GalaxyData.bridges {
            guard let A = nodes[e.a], let B = nodes[e.b] else { continue }
            let both = A.status == .mastered && B.status == .mastered
            let mx = (A.x + B.x) / 2 + (B.y - A.y) * 0.08
            let my = (A.y + B.y) / 2 - (B.x - A.x) * 0.08
            var path = Path()
            path.move(to: A.point)
            path.addQuadCurve(to: B.point, control: CGPoint(x: mx, y: my))
            let color: Color = both
                ? Color(hex: 0xFFE066, opacity: 0.22)
                : Color(hex: 0x96AAC8, opacity: 0.10)
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 0.5, dash: [1, 5]))
        }
    }

    private func nodesByIdLocal() -> [String: StarNode] {
        var out: [String: StarNode] = [:]
        for c in constellations {
            for n in c.nodes { out[n.id] = n }
        }
        return out
    }

    // MARK: Constellation lines

    private func drawConstellations(ctx: inout GraphicsContext) {
        for c in constellations {
            let nodeMap = Dictionary(uniqueKeysWithValues: c.nodes.map { ($0.id, $0) })
            for e in c.edges {
                guard let A = nodeMap[e.a], let B = nodeMap[e.b] else { continue }
                let bothMastered = A.status == .mastered && B.status == .mastered
                let eitherLocked = A.status == .locked || B.status == .locked
                let stroke: Color = bothMastered
                    ? Color(hex: 0xFFE066, opacity: 0.7)
                    : eitherLocked
                        ? Color(hex: 0x788296, opacity: 0.18)
                        : Color(hex: 0xB4D2E6, opacity: 0.45)
                var path = Path()
                path.move(to: A.point)
                path.addLine(to: B.point)
                let style: StrokeStyle = bothMastered
                    ? StrokeStyle(lineWidth: 1.1, lineCap: .round)
                    : StrokeStyle(lineWidth: 0.7, lineCap: .round, dash: [3, 4])
                ctx.stroke(path, with: .color(stroke), style: style)
            }
        }
    }

    // MARK: Stars (foreground)

    private func drawStars(ctx: inout GraphicsContext, t: TimeInterval, scale: CGFloat) {
        for c in constellations {
            for n in c.nodes {
                let dim = (filter != nil && n.status != filter)
                let baseOpacity: Double = dim ? 0.18 : 1.0
                let pal = n.status.palette
                let r = n.size
                let isSelected = (selectedId == n.id)
                let isNew = pendingNewIds.contains(n.id)

                // pop animation for newly-added stars
                let popScale: CGFloat = isNew ? CGFloat(min(1.0, 0.6 + 0.4 * (sin(t * 6) + 1) / 2)) : 1.0

                // Halo (radial)
                let haloMul: CGFloat = n.status == .mastered ? 6 : n.status == .learning ? 5 : 4
                let haloR = r * haloMul * popScale
                let haloRect = CGRect(x: n.x - haloR, y: n.y - haloR, width: haloR * 2, height: haloR * 2)
                let haloColor = pal.glow
                let haloGrad = Gradient(stops: [
                    .init(color: haloColor.opacity(0.88 * baseOpacity), location: 0),
                    .init(color: haloColor.opacity(0.55 * baseOpacity), location: 0.22),
                    .init(color: haloColor.opacity(0.22 * baseOpacity), location: 0.52),
                    .init(color: haloColor.opacity(0.05 * baseOpacity), location: 0.80),
                    .init(color: haloColor.opacity(0),                  location: 1),
                ])
                ctx.fill(
                    Path(ellipseIn: haloRect),
                    with: .radialGradient(haloGrad, center: n.point, startRadius: 0, endRadius: haloR)
                )

                // Selected pulse ring
                if isSelected {
                    let phase = (sin(t * 2.6) + 1) / 2
                    let outerR = r * (3.2 + 1.3 * phase)
                    let outerOp = 0.9 - 0.7 * phase
                    var ring = Path()
                    ring.addEllipse(in: CGRect(x: n.x - outerR, y: n.y - outerR, width: outerR * 2, height: outerR * 2))
                    ctx.stroke(ring, with: .color(pal.mid.opacity(outerOp)), lineWidth: 1.2)
                }

                // Body — chunky 5-point star for mastered/learning/gap, dimmed for locked
                let bodyR = r * 1.9 * popScale
                drawFivePointStar(
                    ctx: &ctx,
                    cx: n.x, cy: n.y, size: bodyR,
                    fill: pal.mid.opacity(baseOpacity),
                    stroke: pal.halo.opacity(baseOpacity * (n.status == .locked ? 0.6 : 1)),
                    rotation: n.status == .mastered ? sin(t * 1.0 + Double(n.id.hashValue % 100) * 0.1) * 0.1 : 0
                )

                // Mastered: face overlay (small eyes + smile)
                if n.status == .mastered {
                    let eyeR = bodyR * 0.10
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: n.x - bodyR * 0.22 - eyeR, y: n.y - bodyR * 0.05 - eyeR, width: eyeR * 2, height: eyeR * 2)),
                        with: .color(Color(hex: 0x3A2A00, opacity: baseOpacity))
                    )
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: n.x + bodyR * 0.22 - eyeR, y: n.y - bodyR * 0.05 - eyeR, width: eyeR * 2, height: eyeR * 2)),
                        with: .color(Color(hex: 0x3A2A00, opacity: baseOpacity))
                    )
                    var smile = Path()
                    smile.move(to: CGPoint(x: n.x - bodyR * 0.18, y: n.y + bodyR * 0.16))
                    smile.addQuadCurve(
                        to: CGPoint(x: n.x + bodyR * 0.18, y: n.y + bodyR * 0.16),
                        control: CGPoint(x: n.x, y: n.y + bodyR * 0.36)
                    )
                    ctx.stroke(smile, with: .color(Color(hex: 0x3A2A00, opacity: baseOpacity)), style: StrokeStyle(lineWidth: bodyR * 0.07, lineCap: .round))
                }

                // Gap: extra pulsing aura
                if n.status == .gap {
                    let phase = (sin(t * 2.1 + Double(n.x) * 0.01) + 1) / 2
                    let gR = r * (2.2 + 2.8 * phase)
                    let gOp = 0.7 - 0.7 * phase
                    var gap = Path()
                    gap.addEllipse(in: CGRect(x: n.x - gR, y: n.y - gR, width: gR * 2, height: gR * 2))
                    ctx.stroke(gap, with: .color(pal.halo.opacity(gOp * baseOpacity)), lineWidth: 0.7)
                }

                // Center bright dot for learning
                if n.status == .learning {
                    let cR = r * 0.5
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: n.x - cR, y: n.y - cR, width: cR * 2, height: cR * 2)),
                        with: .color(pal.core.opacity(0.9 * baseOpacity))
                    )
                }

                // NEW chip — constant screen size
                if isNew {
                    let chipW: CGFloat = 28
                    let chipH: CGFloat = 14
                    let chipY = n.y - bodyR - 10
                    let wsc: CGFloat = 1.3
                    let invS = 1.0 / (scale * wsc)
                    var nctx = ctx
                    nctx.translateBy(x: n.x, y: chipY)
                    nctx.scaleBy(x: invS, y: invS)
                    let chip = Path(roundedRect: CGRect(x: -chipW/2, y: -chipH/2, width: chipW, height: chipH), cornerRadius: 7)
                    nctx.fill(chip, with: .color(Color(hex: 0xFFE066)))
                    nctx.stroke(chip, with: .color(Color(hex: 0xFFB300)), lineWidth: 1)
                    let newLabel = Text("NEW")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: 0x3A2A00))
                    nctx.draw(newLabel, at: .zero, anchor: .center)
                }

                // Label pill — fades in/out smoothly with zoom level, constant screen size
                let labelAlpha: Double = isSelected
                    ? 1.0
                    : max(0.0, min(1.0, Double((scale - 0.72) / 0.18)))
                if labelAlpha > 0.01 {
                    let labelText = "\(n.emoji) \(n.label)"
                    let chipH: CGFloat = 16
                    let approxW = max(48, CGFloat(labelText.count) * 5.6 + 18)
                    let chipY = n.y + bodyR + 10
                    let wsc: CGFloat = 1.3
                    let invS = 1.0 / (scale * wsc)
                    var lctx = ctx
                    lctx.opacity = labelAlpha
                    lctx.translateBy(x: n.x, y: chipY)
                    lctx.scaleBy(x: invS, y: invS)
                    let chipRect = CGRect(x: -approxW/2, y: -chipH/2, width: approxW, height: chipH)
                    lctx.fill(
                        Path(roundedRect: chipRect, cornerRadius: chipH/2),
                        with: .color(Color(hex: 0x0E1228, opacity: 0.82))
                    )
                    lctx.stroke(
                        Path(roundedRect: chipRect, cornerRadius: chipH/2),
                        with: .color(n.status == .locked ? Color(hex: 0xB4BED2, opacity: 0.3) : Color.white.opacity(0.18)),
                        lineWidth: 0.7
                    )
                    let label = Text(labelText)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(n.status == .locked ? Color(hex: 0xC8D2E6, opacity: 0.7) : .white)
                    lctx.draw(label, at: .zero, anchor: .center)
                }
            }
        }

        // Constellation nameplates
        drawConstellationNameplates(ctx: &ctx)
    }

    private func drawConstellationNameplates(ctx: inout GraphicsContext) {
        let wsc: CGFloat = 1.3
        let invS = 1.0 / (scale * wsc)

        for c in constellations {
            let avg = c.masteryAvg
            let pct = Int((avg * 100).rounded())
            let hot = avg > 0.7
            let minY = c.nodes.map(\.y).min() ?? c.centroid.y
            let labelY = minY - 22
            let cx = c.centroid.x

            let label = "\(c.emoji) \(c.name)"
            let labelW = max(86, CGFloat(label.count) * 8.2 + 14)
            let chipW: CGFloat = 38
            let gap: CGFloat = 6
            let totalW = labelW + gap + chipW
            let halfW = totalW / 2
            let h: CGFloat = 26

            // Counter-scale so the nameplate stays the same screen size at any zoom
            var tctx = ctx
            tctx.translateBy(x: cx, y: labelY)
            tctx.scaleBy(x: invS, y: invS)

            // Soft halo
            let haloRect = CGRect(x: -halfW - 6, y: -h/2 - 4, width: totalW + 12, height: h + 8)
            tctx.fill(Path(roundedRect: haloRect, cornerRadius: (h + 8)/2),
                     with: .color(Color(hex: 0x08041A, opacity: 0.42)))

            // Main pill
            let nameRect = CGRect(x: -halfW, y: -h/2, width: labelW, height: h)
            tctx.fill(Path(roundedRect: nameRect, cornerRadius: h/2),
                     with: .color(Color(hex: 0x0E1228, opacity: 0.85)))
            tctx.stroke(Path(roundedRect: nameRect, cornerRadius: h/2),
                       with: .color(Color(hex: 0xFFE066, opacity: 0.4)), lineWidth: 1)

            let nameText = Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: 0xFFF8E1))
            tctx.draw(nameText, at: CGPoint(x: -halfW + labelW/2, y: 0), anchor: .center)

            // Mastery chip
            let chipRect = CGRect(x: -halfW + labelW + gap, y: -h/2, width: chipW, height: h)
            tctx.fill(Path(roundedRect: chipRect, cornerRadius: h/2),
                     with: .color(hot ? Color(hex: 0xFFB300, opacity: 0.9) : Color(hex: 0x5EE7FF, opacity: 0.18)))
            tctx.stroke(Path(roundedRect: chipRect, cornerRadius: h/2),
                       with: .color(hot ? Color(hex: 0xFFE066, opacity: 0.9) : Color(hex: 0x5EE7FF, opacity: 0.6)), lineWidth: 1)

            let pctText = Text("\(pct)%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(hot ? Color(hex: 0x2A1A00) : Color(hex: 0x5EE7FF))
            tctx.draw(pctText, at: CGPoint(x: -halfW + labelW + gap + chipW/2, y: 0), anchor: .center)
        }
    }

    // MARK: Discover nebula (empty cluster inviting upload)

    private func drawDiscoverNebula(ctx: inout GraphicsContext, t: TimeInterval, cx: CGFloat, cy: CGFloat) {
        // Nebula clouds
        let clouds: [(dx: CGFloat, dy: CGFloat, r: CGFloat, color: UInt32, op: Double)] = [
            (0, 0, 120, 0xA855F7, 0.85),
            (-15, 10, 95, 0xFF4FB6, 0.65),
            (20, -15, 80, 0x5EE7FF, 0.5),
        ]
        for c in clouds {
            let rect = CGRect(x: cx + c.dx - c.r, y: cy + c.dy - c.r, width: c.r * 2, height: c.r * 2)
            let grad = Gradient(stops: [
                .init(color: Color(hex: c.color, opacity: c.op * 0.5), location: 0),
                .init(color: Color(hex: c.color, opacity: 0), location: 1),
            ])
            ctx.fill(Path(ellipseIn: rect),
                     with: .radialGradient(grad, center: CGPoint(x: cx + c.dx, y: cy + c.dy), startRadius: 0, endRadius: c.r))
        }

        // Rotating dashed boundary
        let boundaryR: CGFloat = 78
        var boundary = ctx
        boundary.translateBy(x: cx, y: cy)
        boundary.rotate(by: .radians(t * 0.16))
        boundary.translateBy(x: -cx, y: -cy)
        boundary.stroke(
            Path(ellipseIn: CGRect(x: cx - boundaryR, y: cy - boundaryR, width: boundaryR * 2, height: boundaryR * 2)),
            with: .color(.white.opacity(0.22)),
            style: StrokeStyle(lineWidth: 1, dash: [3, 6])
        )

        // Ghost stars
        let ghosts: [(dx: CGFloat, dy: CGFloat, r: CGFloat)] = [
            (-55, -30, 3.5), (30, -50, 4.5), (70, 20, 3),
            (-40, 35, 4), (0, 60, 3), (-75, 5, 2.6),
            (55, -10, 3), (20, 30, 2.6),
        ]
        for g in ghosts {
            let p = CGPoint(x: cx + g.dx, y: cy + g.dy)
            ctx.fill(
                Path(ellipseIn: CGRect(x: p.x - g.r, y: p.y - g.r, width: g.r * 2, height: g.r * 2)),
                with: .color(.white.opacity(0.35))
            )
            ctx.stroke(
                Path(ellipseIn: CGRect(x: p.x - g.r - 2, y: p.y - g.r - 2, width: (g.r + 2) * 2, height: (g.r + 2) * 2)),
                with: .color(.white.opacity(0.15)),
                style: StrokeStyle(lineWidth: 0.6, dash: [1, 2])
            )
        }

        // Center plus button (pulsing yellow ring)
        let pulsePhase = (sin(t * 2.6) + 1) / 2
        let outR = 26 + 12 * pulsePhase
        ctx.stroke(
            Path(ellipseIn: CGRect(x: cx - outR, y: cy - outR, width: outR * 2, height: outR * 2)),
            with: .color(Color(hex: 0xFFE066, opacity: 0.7 * (1 - pulsePhase))),
            lineWidth: 1.4
        )
        ctx.fill(
            Path(ellipseIn: CGRect(x: cx - 32, y: cy - 32, width: 64, height: 64)),
            with: .color(Color(hex: 0xFFE066, opacity: 0.18))
        )
        ctx.fill(
            Path(ellipseIn: CGRect(x: cx - 26, y: cy - 26, width: 52, height: 52)),
            with: .color(Color(hex: 0x140A32, opacity: 0.85))
        )
        ctx.stroke(
            Path(ellipseIn: CGRect(x: cx - 26, y: cy - 26, width: 52, height: 52)),
            with: .color(Color(hex: 0xFFE066)),
            lineWidth: 1.6
        )
        // Plus icon
        var plus = Path()
        plus.move(to: CGPoint(x: cx - 10, y: cy)); plus.addLine(to: CGPoint(x: cx + 10, y: cy))
        plus.move(to: CGPoint(x: cx, y: cy - 10)); plus.addLine(to: CGPoint(x: cx, y: cy + 10))
        ctx.stroke(plus, with: .color(Color(hex: 0xFFE066)), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))

        // Nameplate "✨ New Skies" — constant screen size
        let wsc: CGFloat = 1.3
        let invS = 1.0 / (scale * wsc)
        let nebulaLabelY = cy + 110
        do {
            let labelW: CGFloat = 130
            let labelH: CGFloat = 26
            var tctx = ctx
            tctx.translateBy(x: cx, y: nebulaLabelY)
            tctx.scaleBy(x: invS, y: invS)
            let nameRect = CGRect(x: -labelW/2, y: -labelH/2, width: labelW, height: labelH)
            tctx.fill(Path(roundedRect: nameRect, cornerRadius: labelH/2),
                     with: .color(Color(hex: 0x0E1228, opacity: 0.85)))
            tctx.stroke(Path(roundedRect: nameRect, cornerRadius: labelH/2),
                       with: .color(Color(hex: 0xFFE066, opacity: 0.4)), lineWidth: 1)
            tctx.draw(
                Text("✨ New Skies").font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(Color(hex: 0xFFF8E1)),
                at: .zero, anchor: .center
            )
        }

        // Sub-label — constant screen size
        do {
            let subY = cy + 142
            var tctx = ctx
            tctx.translateBy(x: cx, y: subY)
            tctx.scaleBy(x: invS, y: invS)
            tctx.draw(
                Text("Tap to grow new stars!")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: 0xFFE066, opacity: 0.95)),
                at: .zero, anchor: .center
            )
        }
    }

    private func drawFivePointStar(
        ctx: inout GraphicsContext,
        cx: CGFloat, cy: CGFloat, size: CGFloat,
        fill: Color, stroke: Color, rotation: Double
    ) {
        var path = Path()
        for i in 0..<10 {
            let ang = Double.pi / 5 * Double(i) - Double.pi / 2 + rotation
            let rad = (i % 2 == 0) ? size : size * 0.42
            let x = cx + CGFloat(cos(ang)) * rad
            let y = cy + CGFloat(sin(ang)) * rad
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        ctx.fill(path, with: .color(fill))
        ctx.stroke(path, with: .color(stroke), style: StrokeStyle(lineWidth: 0.9, lineJoin: .round))
    }
}

// MARK: - Hit-test layer

struct GalaxyHitLayer: View {
    let constellations: [Constellation]
    let tx: CGFloat
    let ty: CGFloat
    let scale: CGFloat
    let showDiscoverNebula: Bool
    let onTapStar: (StarNode) -> Void
    let onTapConstellation: (Constellation) -> Void
    let onTapDiscover: () -> Void

    var body: some View {
        ZStack {
            // Star hit targets
            ForEach(constellations) { c in
                ForEach(c.nodes) { n in
                    Color.clear
                        .frame(width: max(n.size * 6, 32), height: max(n.size * 6, 32))
                        .contentShape(Circle())
                        .position(worldToScreen(CGPoint(x: n.x, y: n.y)))
                        .onTapGesture { onTapStar(n) }
                        .allowsHitTesting(true)
                }
            }
            // Constellation name buttons (above each constellation)
            ForEach(constellations) { c in
                let minY = c.nodes.map(\.y).min() ?? c.centroid.y
                Color.clear
                    .frame(width: 200 * scale, height: 32 * scale)
                    .contentShape(Rectangle())
                    .position(worldToScreen(CGPoint(x: c.centroid.x, y: minY - 22)))
                    .onTapGesture { onTapConstellation(c) }
                    .allowsHitTesting(true)
            }
            // Discover nebula tap
            if showDiscoverNebula {
                Color.clear
                    .frame(width: 240 * scale, height: 240 * scale)
                    .contentShape(Circle())
                    .position(worldToScreen(CGPoint(x: 760, y: 1450)))
                    .onTapGesture { onTapDiscover() }
                    .allowsHitTesting(true)
            }
        }
    }

    private func worldToScreen(_ p: CGPoint) -> CGPoint {
        let wsc: CGFloat = 1.3
        return CGPoint(x: p.x * scale * wsc + tx, y: p.y * scale * wsc + ty)
    }
}

// MARK: - Hint pill

struct HintPill: View {
    let gaps: Int
    @State private var pulse: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: 0x5EE7FF))
                .frame(width: 7, height: 7)
                .shadow(color: Color(hex: 0x5EE7FF), radius: 3)
                .opacity(pulse ? 0.5 : 1.0)
                .scaleEffect(pulse ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(), value: pulse)
            Text("😴 Tap a sleepy star to wake it up! (\(gaps))")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color(hex: 0x1C0C3C, opacity: 0.78))
                .background(.ultraThinMaterial, in: Capsule())
        )
        .overlay(
            Capsule().stroke(Color(hex: 0x5EE7FF, opacity: 0.4), lineWidth: 1.5)
        )
        .onAppear { pulse = true }
    }
}

// MARK: - Custom bottom navigation

private struct CustomBottomNav: View {
    @Binding var tab: GalaxyTab
    let safeBottom: CGFloat

    private let items: [(GalaxyTab, String, String)] = [
        (.galaxy,  "Galaxy", "🌌"),
        (.study,   "Quests", "🎯"),
        (.nova,    "Nova",   "🦊"),
        (.profile, "Me",     "👤"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.0.rawValue) { item in
                NavTabButton(
                    tabVal: item.0, label: item.1, emoji: item.2,
                    isActive: tab == item.0
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                        tab = item.0
                    }
                }
            }
        }
        .frame(height: 62)
        .background(.ultraThinMaterial)
        .background(Color(hex: 0x1C0C3C, opacity: 0.78))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xFFE066, opacity: 0.25), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 14)
        .padding(.bottom, max(safeBottom, 10) + 14)
    }
}

private struct NavTabButton: View {
    let tabVal: GalaxyTab
    let label: String
    let emoji: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(emoji)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)

                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1.0)
            }
            .foregroundColor(isActive ? Color(hex: 0xFFE066) : .white.opacity(0.45))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, isActive ? 14 : 10)
            .background(
                Group {
                    if isActive {
                        LinearGradient(
                            colors: [Color(hex: 0xFFE066, opacity: 0.22), Color(hex: 0xFF8AD8, opacity: 0.18)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(hex: 0xFFE066, opacity: 0.5), lineWidth: 1.5)
                        )
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .offset(y: isActive ? -3 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.78), value: isActive)
    }
}

// MARK: - Telescope overlay (warp-in page transition)

private struct TelescopeOverlayView: View {
    let viewW: CGFloat
    let viewH: CGFloat

    var body: some View {
        let cx = viewW / 2
        let cy = viewH * 0.48
        let r  = viewW * 0.46

        Canvas { ctx, _ in
            // Vignette: clear inside eyepiece, dark outside
            ctx.fill(
                Path(CGRect(x: 0, y: 0, width: viewW, height: viewH)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: .clear,                      location: 0.00),
                        .init(color: .clear,                      location: 0.80),
                        .init(color: .black.opacity(0.90),        location: 0.91),
                        .init(color: .black.opacity(0.99),        location: 0.97),
                        .init(color: Color(hex: 0x020108),        location: 1.00),
                    ]),
                    center: CGPoint(x: cx, y: cy),
                    startRadius: 0, endRadius: r
                )
            )

            // Chromatic aberration fringe
            ctx.fill(
                Path(CGRect(x: 0, y: 0, width: viewW, height: viewH)),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: .clear,                                                  location: 0.74),
                        .init(color: Color(red: 0.24, green: 0.31, blue: 1.0, opacity: 0.13), location: 0.82),
                        .init(color: Color(red: 1.0,  green: 0.16, blue: 0.24, opacity: 0.10), location: 0.87),
                        .init(color: .clear,                                                  location: 0.92),
                    ]),
                    center: CGPoint(x: cx, y: cy),
                    startRadius: 0, endRadius: r
                )
            )

            // Hard eyepiece rim
            let rimR = r + 18
            let rimPath = Path(ellipseIn: CGRect(x: cx - rimR, y: cy - rimR, width: rimR * 2, height: rimR * 2))
            ctx.stroke(rimPath, with: .color(Color(red: 0.12, green: 0.12, blue: 0.20, opacity: 0.98)), lineWidth: 38)
            ctx.stroke(rimPath, with: .color(Color(red: 0.35, green: 0.41, blue: 0.55, opacity: 0.55)), lineWidth: 2)

            // Inner rim line
            ctx.stroke(
                Path(ellipseIn: CGRect(x: cx - (r-1), y: cy - (r-1), width: (r-1)*2, height: (r-1)*2)),
                with: .color(Color(red: 0.51, green: 0.61, blue: 0.78, opacity: 0.30)),
                lineWidth: 1.5
            )

            // Lens reflection rings
            ctx.stroke(
                Path(ellipseIn: CGRect(x: cx - r*0.87, y: cy - r*0.87, width: r*0.87*2, height: r*0.87*2)),
                with: .color(Color(red: 0.71, green: 0.82, blue: 1.0, opacity: 0.07)), lineWidth: 1
            )
            ctx.stroke(
                Path(ellipseIn: CGRect(x: cx - r*0.70, y: cy - r*0.70, width: r*0.70*2, height: r*0.70*2)),
                with: .color(Color(red: 0.71, green: 0.82, blue: 1.0, opacity: 0.04)), lineWidth: 0.8
            )

        }
        .frame(width: viewW, height: viewH)
    }
}

#Preview {
    LearningGalaxyView()
}
